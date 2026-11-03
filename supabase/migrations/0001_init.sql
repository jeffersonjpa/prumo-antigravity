-- Prumo — migração inicial
-- Núcleo (perfis, órgãos, membros, setores, planos, leads, eventos)
-- Módulo Maturidade em Dados e IA
-- Módulo Prompts
--
-- Dados pessoais armazenados e por quê:
-- - profiles: e-mail, nome e cargo do usuário com conta (identificação e acesso)
-- - leads: e-mail, nome, cargo e órgão de quem pediu contato, com consentimento registrado
-- - org_invitations: e-mail de quem foi convidado para um órgão, até o aceite ou a expiração
-- Respostas do diagnóstico não guardam nenhum dado do respondente.

-- No Supabase o pgcrypto fica no schema extensions
create extension if not exists pgcrypto with schema extensions;

-- =====================================================================
-- Tipos
-- =====================================================================
create type public.member_role as enum ('admin', 'gestor', 'membro');
create type public.org_type as enum ('municipio', 'estado', 'autarquia', 'legislativo', 'judiciario', 'outro');
create type public.plan_code as enum ('free', 'individual', 'equipe', 'orgao');
create type public.cycle_status as enum ('draft', 'open', 'closed');
create type public.respondent_profile as enum ('gestao', 'equipe');
create type public.prompt_access as enum ('free', 'premium');

-- =====================================================================
-- Núcleo
-- =====================================================================
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  email text not null,
  job_title text,
  created_at timestamptz not null default now()
);

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  org_type public.org_type not null default 'outro',
  uf char(2),
  city text,
  created_by uuid default auth.uid() references public.profiles (id),
  created_at timestamptz not null default now()
);

create table public.memberships (
  org_id uuid not null references public.organizations (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role public.member_role not null default 'membro',
  created_at timestamptz not null default now(),
  primary key (org_id, user_id)
);

create table public.org_units (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now(),
  unique (org_id, name)
);

-- Convite para entrar em um órgão. O aceite é feito por accept_org_invitation(),
-- que confere se o e-mail da sessão é o mesmo do convite.
create table public.org_invitations (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  email text not null check (email = lower(email)),
  role public.member_role not null default 'membro',
  token text not null unique
    default replace(replace(replace(encode(extensions.gen_random_bytes(32), 'base64'), '+', '-'), '/', '_'), '=', ''),
  invited_by uuid default auth.uid() references public.profiles (id) on delete set null,
  expires_at timestamptz not null default now() + interval '7 days',
  accepted_at timestamptz,
  created_at timestamptz not null default now()
);

-- Um convite pendente por e-mail em cada órgão
create unique index org_invitations_pending_uniq on public.org_invitations (org_id, email)
  where accepted_at is null;

-- Plano pertence a um usuário OU a um órgão (nunca aos dois)
create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles (id) on delete cascade,
  org_id uuid references public.organizations (id) on delete cascade,
  plan public.plan_code not null default 'free',
  status text not null default 'active' check (status in ('active', 'past_due', 'canceled')),
  current_period_end timestamptz,
  provider text,          -- ex.: 'asaas' (Marco 3)
  provider_ref text,
  created_at timestamptz not null default now(),
  check ((user_id is null) <> (org_id is null))
);

create table public.leads (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  full_name text,
  job_title text,
  organization_name text,
  uf char(2),
  source text not null,   -- ex.: 'oficina-manaus-2026-11', 'landing'
  consent_lgpd boolean not null,
  consent_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (email, source),
  check (consent_lgpd = true)
);

create table public.usage_events (
  id bigint generated always as identity primary key,
  user_id uuid references public.profiles (id) on delete set null,
  org_id uuid references public.organizations (id) on delete set null,
  name text not null,     -- ex.: 'prompt.copied', 'cycle.opened'
  props jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- =====================================================================
-- Funções auxiliares de permissão (usadas pelas políticas RLS)
-- =====================================================================
create or replace function public.is_member(p_org uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.memberships m
    where m.org_id = p_org and m.user_id = auth.uid()
  );
$$;

create or replace function public.has_role(p_org uuid, p_roles public.member_role[])
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.memberships m
    where m.org_id = p_org and m.user_id = auth.uid() and m.role = any (p_roles)
  );
$$;

-- Cria o perfil automaticamente quando um usuário se cadastra
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, new.raw_user_meta_data ->> 'full_name');
  insert into public.subscriptions (user_id, plan) values (new.id, 'free');
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Quem cria o órgão vira admin automaticamente. Órgãos criados pelo servidor (service role,
-- sem sessão) só ganham admin se created_by for informado.
create or replace function public.handle_new_org()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := coalesce(new.created_by, auth.uid());
begin
  if v_user is not null then
    insert into public.memberships (org_id, user_id, role)
    values (new.id, v_user, 'admin');
  end if;
  return new;
end;
$$;

create trigger on_org_created
  after insert on public.organizations
  for each row execute function public.handle_new_org();

-- Aceite de convite: só vale para o e-mail da sessão, dentro do prazo e uma única vez
create or replace function public.accept_org_invitation(p_token text)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_inv public.org_invitations;
begin
  select * into v_inv from public.org_invitations i
  where i.token = p_token and i.accepted_at is null and i.expires_at > now()
  for update;

  if v_inv.id is null or v_inv.email <> lower(auth.jwt() ->> 'email') then
    raise exception 'convite inválido ou expirado';
  end if;

  insert into public.memberships (org_id, user_id, role)
  values (v_inv.org_id, auth.uid(), v_inv.role)
  on conflict (org_id, user_id) do nothing;

  update public.org_invitations set accepted_at = now() where id = v_inv.id;
  return v_inv.org_id;
end;
$$;

-- =====================================================================
-- Módulo Maturidade em Dados e IA
-- =====================================================================
create table public.assessment_templates (
  id uuid primary key default gen_random_uuid(),
  slug text not null,
  version int not null,
  title text not null,
  published boolean not null default false,
  created_at timestamptz not null default now(),
  unique (slug, version)
);

create table public.assessment_dimensions (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references public.assessment_templates (id) on delete cascade,
  code text not null,
  name text not null,
  description text,
  position int not null,
  unique (template_id, code)
);

create table public.assessment_questions (
  id uuid primary key default gen_random_uuid(),
  dimension_id uuid not null references public.assessment_dimensions (id) on delete cascade,
  code text not null,  -- ex.: 'GOV-02'; repete entre versões do template
  statement text not null,
  help text,
  position int not null,
  unique (dimension_id, code)
);

create table public.assessment_recommendations (
  id uuid primary key default gen_random_uuid(),
  dimension_id uuid not null references public.assessment_dimensions (id) on delete cascade,
  band text not null check (band in ('baixo', 'medio', 'alto')),
  title text not null,
  body text not null,
  unique (dimension_id, band)
);

create table public.assessment_cycles (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  template_id uuid not null references public.assessment_templates (id),
  title text not null,
  status public.cycle_status not null default 'draft',
  invite_token text not null unique
    default replace(replace(replace(encode(extensions.gen_random_bytes(32), 'base64'), '+', '-'), '/', '_'), '=', ''),
  opens_at timestamptz,
  closes_at timestamptz,
  created_by uuid default auth.uid() references public.profiles (id),
  created_at timestamptz not null default now()
);

-- Setores oferecidos como opção aos respondentes do ciclo (nenhum = pergunta de setor omitida)
create table public.assessment_cycle_units (
  cycle_id uuid not null references public.assessment_cycles (id) on delete cascade,
  org_unit_id uuid not null references public.org_units (id) on delete cascade,
  primary key (cycle_id, org_unit_id)
);

create table public.assessment_responses (
  id uuid primary key default gen_random_uuid(),
  cycle_id uuid not null references public.assessment_cycles (id) on delete cascade,
  org_unit_id uuid references public.org_units (id) on delete set null,
  profile public.respondent_profile not null,
  submitted_at timestamptz not null default now()
  -- Sem identificação do respondente: o diagnóstico é anônimo
);

create table public.assessment_answers (
  response_id uuid not null references public.assessment_responses (id) on delete cascade,
  question_id uuid not null references public.assessment_questions (id),
  value smallint check (value between 1 and 5), -- null = "não sei avaliar"
  primary key (response_id, question_id)
);

-- Agregados seguros do ciclo: médias por dimensão e perfil, com mínimo de 3 respostas.
-- O gestor lê o painel por esta função; nunca pelas tabelas de resposta.
--
-- Supressão secundária: esconder só o grupo pequeno não basta, porque ele pode ser
-- recuperado por subtração (ex.: "todos" n=4 menos "gestao" n=3 revela a única resposta
-- da equipe). Por isso, por dimensão:
-- - linhas por perfil só aparecem se cada perfil tiver 0 ou 3+ respondentes no ciclo;
-- - o filtro por setor só funciona se toda célula setor × perfil do ciclo (incluindo
--   "sem setor") tiver 0 ou 3+ respondentes.
-- Como todo agregado exibido é então uma união de células com 0 ou 3+ pessoas,
-- nenhuma subtração entre agregados isola menos de 3 respondentes.
-- A regra vale tanto para a contagem total (base de dont_know_share) quanto para a de
-- respostas válidas (base de mean_value e stddev_value).
create or replace function public.get_cycle_results(p_cycle uuid, p_unit uuid default null)
returns table (
  dimension_code text,
  dimension_name text,
  profile text,             -- 'gestao', 'equipe' ou 'todos'
  respondents int,          -- respondentes com ao menos uma resposta válida na dimensão
  mean_value numeric,       -- null se respondents < 3
  stddev_value numeric,     -- desvio padrão amostral; null se respondents < 3
  dont_know_share numeric   -- fração (0 a 1) de "não sei avaliar" nas respostas da dimensão
)
language plpgsql stable security definer set search_path = public as $$
declare
  v_org uuid;
begin
  select c.org_id into v_org from public.assessment_cycles c where c.id = p_cycle;
  if v_org is null or not public.has_role(v_org, array['admin', 'gestor']::public.member_role[]) then
    raise exception 'acesso negado';
  end if;

  return query
  with per_response as (
    -- Uma linha por respondente e dimensão; dim_mean é null se tudo foi "não sei"
    select d.code as d_code, d.name as d_name, d.position as d_pos,
           r.id as resp_id, r.profile::text as resp_profile, r.org_unit_id as resp_unit,
           avg(a.value) as dim_mean,
           count(*) as answers,
           count(*) filter (where a.value is null) as dont_know
    from public.assessment_responses r
    join public.assessment_answers a on a.response_id = r.id
    join public.assessment_questions q on q.id = a.question_id
    join public.assessment_dimensions d on d.id = q.dimension_id
    where r.cycle_id = p_cycle
    group by d.code, d.name, d.position, r.id, r.profile, r.org_unit_id
  ),
  profile_cells as (
    select pr.d_code, count(*) as n_total, count(pr.dim_mean) as n_valid
    from per_response pr group by pr.d_code, pr.resp_profile
  ),
  unit_cells as (
    select pr.d_code, count(*) as n_total, count(pr.dim_mean) as n_valid
    from per_response pr group by pr.d_code, pr.resp_unit, pr.resp_profile
  ),
  safety as (
    select pc.d_code,
           bool_and(pc.n_total not in (1, 2) and pc.n_valid not in (1, 2)) as profiles_safe,
           (select bool_and(uc.n_total not in (1, 2) and uc.n_valid not in (1, 2))
            from unit_cells uc where uc.d_code = pc.d_code) as units_safe
    from profile_cells pc group by pc.d_code
  ),
  slice as (
    select * from per_response pr where p_unit is null or pr.resp_unit = p_unit
  ),
  grouped as (
    select s.d_code, s.d_name, s.d_pos, s.resp_profile as grp,
           count(*) as n_total, count(s.dim_mean) as n_valid,
           avg(s.dim_mean) as m, stddev_samp(s.dim_mean) as sd,
           sum(s.dont_know)::numeric / sum(s.answers) as dk
    from slice s group by s.d_code, s.d_name, s.d_pos, s.resp_profile
    union all
    select s.d_code, s.d_name, s.d_pos, 'todos',
           count(*), count(s.dim_mean),
           avg(s.dim_mean), stddev_samp(s.dim_mean),
           sum(s.dont_know)::numeric / sum(s.answers)
    from slice s group by s.d_code, s.d_name, s.d_pos
  )
  select g.d_code, g.d_name, g.grp, g.n_valid::int,
         case when g.n_valid >= 3 then round(g.m, 2) end,
         case when g.n_valid >= 3 then round(g.sd, 2) end,
         round(g.dk, 2)
  from grouped g
  join safety sf on sf.d_code = g.d_code
  where g.n_total >= 3
    and (p_unit is null or sf.units_safe)
    and (g.grp = 'todos' or (case when p_unit is null then sf.profiles_safe else sf.units_safe end))
  order by g.d_pos, g.grp;
end;
$$;

-- Total de respostas do ciclo (mostrado mesmo abaixo de 3, sem detalhes)
create or replace function public.get_cycle_response_count(p_cycle uuid)
returns int language plpgsql stable security definer set search_path = public as $$
declare
  v_org uuid;
  v_count int;
begin
  select c.org_id into v_org from public.assessment_cycles c where c.id = p_cycle;
  if v_org is null or not public.has_role(v_org, array['admin', 'gestor']::public.member_role[]) then
    raise exception 'acesso negado';
  end if;
  select count(*) into v_count from public.assessment_responses where cycle_id = p_cycle;
  return v_count;
end;
$$;

-- =====================================================================
-- Módulo Prompts
-- =====================================================================
create table public.prompt_categories (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  position int not null default 0
);

create table public.prompts (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.prompt_categories (id),
  slug text not null unique,
  title text not null,
  summary text not null,
  body text not null,                       -- texto com variáveis {{assim}}
  variables jsonb not null default '[]'::jsonb, -- [{ key, label, placeholder, required }]
  tips text,
  access public.prompt_access not null default 'free',
  tags text[] not null default '{}',
  published boolean not null default false,
  version int not null default 1,
  updated_at timestamptz not null default now()
);

create table public.prompt_favorites (
  user_id uuid not null references public.profiles (id) on delete cascade,
  prompt_id uuid not null references public.prompts (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, prompt_id)
);

-- Plano efetivo do usuário: o maior entre o plano pessoal e o dos órgãos de que participa
create or replace function public.current_plan()
returns public.plan_code language sql stable security definer set search_path = public as $$
  select coalesce(max(s.plan), 'free')
  from public.subscriptions s
  where s.status = 'active'
    and (s.user_id = auth.uid()
         or s.org_id in (select m.org_id from public.memberships m where m.user_id = auth.uid()));
$$;

-- =====================================================================
-- RLS
-- =====================================================================
alter table public.profiles enable row level security;
alter table public.organizations enable row level security;
alter table public.memberships enable row level security;
alter table public.org_units enable row level security;
alter table public.org_invitations enable row level security;
alter table public.subscriptions enable row level security;
alter table public.leads enable row level security;
alter table public.usage_events enable row level security;
alter table public.assessment_templates enable row level security;
alter table public.assessment_dimensions enable row level security;
alter table public.assessment_questions enable row level security;
alter table public.assessment_recommendations enable row level security;
alter table public.assessment_cycles enable row level security;
alter table public.assessment_cycle_units enable row level security;
alter table public.assessment_responses enable row level security;
alter table public.assessment_answers enable row level security;
alter table public.prompt_categories enable row level security;
alter table public.prompts enable row level security;
alter table public.prompt_favorites enable row level security;

-- Perfis: cada um vê e edita o próprio; membros do mesmo órgão se veem
create policy profiles_self_select on public.profiles for select
  using (id = auth.uid() or exists (
    select 1 from public.memberships a join public.memberships b on a.org_id = b.org_id
    where a.user_id = auth.uid() and b.user_id = profiles.id));
create policy profiles_self_update on public.profiles for update using (id = auth.uid());

-- Órgãos
create policy orgs_select on public.organizations for select using (public.is_member(id));
create policy orgs_insert on public.organizations for insert
  with check (auth.uid() is not null and created_by = auth.uid());
create policy orgs_update on public.organizations for update
  using (public.has_role(id, array['admin']::public.member_role[]));

-- Membros: membros veem a lista; só admin altera
create policy memberships_select on public.memberships for select using (public.is_member(org_id));
create policy memberships_admin_all on public.memberships for all
  using (public.has_role(org_id, array['admin']::public.member_role[]))
  with check (public.has_role(org_id, array['admin']::public.member_role[]));

-- Setores
create policy units_select on public.org_units for select using (public.is_member(org_id));
create policy units_admin_all on public.org_units for all
  using (public.has_role(org_id, array['admin', 'gestor']::public.member_role[]))
  with check (public.has_role(org_id, array['admin', 'gestor']::public.member_role[]));

-- Convites: só admin do órgão vê, cria e cancela; o aceite é por accept_org_invitation()
create policy invitations_admin_all on public.org_invitations for all
  using (public.has_role(org_id, array['admin']::public.member_role[]))
  with check (public.has_role(org_id, array['admin']::public.member_role[]));

-- Planos: leitura própria; escrita só pelo servidor (service role)
create policy subs_select on public.subscriptions for select
  using (user_id = auth.uid() or (org_id is not null and public.is_member(org_id)));

-- Leads e eventos: sem acesso pelo cliente; gravação só por server actions (service role)
-- (nenhuma policy = nenhum acesso via anon/authenticated)

-- Conteúdo do questionário: leitura pública quando publicado
create policy templates_read on public.assessment_templates for select using (published);
create policy dimensions_read on public.assessment_dimensions for select
  using (exists (select 1 from public.assessment_templates t where t.id = template_id and t.published));
create policy questions_read on public.assessment_questions for select
  using (exists (select 1 from public.assessment_dimensions d
                 join public.assessment_templates t on t.id = d.template_id
                 where d.id = dimension_id and t.published));
create policy recommendations_read on public.assessment_recommendations for select
  using (auth.uid() is not null);

-- Ciclos: gestores e admins do órgão
create policy cycles_select on public.assessment_cycles for select
  using (public.has_role(org_id, array['admin', 'gestor']::public.member_role[]));
create policy cycles_write on public.assessment_cycles for all
  using (public.has_role(org_id, array['admin', 'gestor']::public.member_role[]))
  with check (public.has_role(org_id, array['admin', 'gestor']::public.member_role[]));

-- Setores do ciclo: gestores e admins; o setor precisa ser do mesmo órgão do ciclo
create policy cycle_units_select on public.assessment_cycle_units for select
  using (exists (select 1 from public.assessment_cycles c
                 where c.id = cycle_id
                   and public.has_role(c.org_id, array['admin', 'gestor']::public.member_role[])));
create policy cycle_units_write on public.assessment_cycle_units for all
  using (exists (select 1 from public.assessment_cycles c
                 where c.id = cycle_id
                   and public.has_role(c.org_id, array['admin', 'gestor']::public.member_role[])))
  with check (exists (select 1 from public.assessment_cycles c
                      join public.org_units u on u.org_id = c.org_id
                      where c.id = cycle_id and u.id = org_unit_id
                        and public.has_role(c.org_id, array['admin', 'gestor']::public.member_role[])));

-- Respostas e itens: nenhum acesso direto pelo cliente.
-- Gravação: server action com service role, após validar o convite.
-- Leitura: apenas via get_cycle_results().

-- Prompts: categorias são públicas. A tabela prompts NÃO tem política de leitura: com
-- leitura direta, qualquer visitante pediria a coluna body dos prompts premium pela API.
-- A leitura é só pela view prompts_public.
create policy categories_read on public.prompt_categories for select using (true);
revoke all on public.prompts from anon, authenticated;

create policy favorites_own on public.prompt_favorites for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- View pública que esconde o corpo dos prompts premium para quem não tem plano.
-- É security definer de propósito (roda como o dono e ignora a RLS de prompts), porque
-- o cliente não tem acesso à tabela. O linter do Supabase vai alertar; o filtro de
-- published e de body está aqui dentro. Só leitura: sem isso, a view seria atualizável
-- e permitiria escrever em prompts com os privilégios do dono.
create or replace view public.prompts_public
with (security_barrier = true) as
select
  p.id, p.category_id, p.slug, p.title, p.summary, p.variables, p.tips, p.access, p.tags, p.updated_at,
  case when p.access = 'free' or public.current_plan() <> 'free' then p.body else null end as body
from public.prompts p
where p.published;

revoke all on public.prompts_public from anon, authenticated;
grant select on public.prompts_public to anon, authenticated;

-- =====================================================================
-- Permissões de funções
-- =====================================================================
-- Funções do painel e de convite exigem sessão. is_member, has_role e current_plan
-- continuam executáveis por todos porque são chamadas pelas políticas e pela view.
revoke execute on function public.get_cycle_results(uuid, uuid) from public, anon;
revoke execute on function public.get_cycle_response_count(uuid) from public, anon;
revoke execute on function public.accept_org_invitation(text) from public, anon;
grant execute on function public.get_cycle_results(uuid, uuid) to authenticated;
grant execute on function public.get_cycle_response_count(uuid) to authenticated;
grant execute on function public.accept_org_invitation(text) to authenticated;

-- =====================================================================
-- Índices
-- =====================================================================
create index on public.memberships (user_id);
create index on public.org_invitations (email);
create index on public.subscriptions (user_id);
create index on public.subscriptions (org_id);
create index on public.assessment_cycles (org_id);
create index on public.assessment_cycle_units (org_unit_id);
create index on public.assessment_responses (cycle_id);
create index on public.assessment_answers (question_id);
create index on public.prompts (category_id);
create index on public.usage_events (name, created_at);
