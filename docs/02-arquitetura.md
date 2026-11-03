# 02 — Arquitetura

## Visão geral

```
Navegador / PWA (celular e desktop)
        │
Next.js (App Router) na Vercel
  ├─ (public)  landing, prompts gratuitos, resposta por convite
  ├─ (app)     área logada: painel, órgão, módulos
  ├─ server actions e route handlers (validação com Zod)
        │
Supabase (sa-east-1)
  ├─ Auth (link mágico + Google)
  ├─ Postgres com RLS
  └─ Funções SQL para agregações seguras do diagnóstico
```

## Núcleo (`src/core/`)

| Parte | Responsabilidade |
| --- | --- |
| `auth` | Sessão, login, logout, middleware que protege `(app)` |
| `orgs` | Criar órgão, convidar membros, setores, troca de órgão ativo |
| `permissions` | `hasRole(orgId, roles)`; espelha as funções SQL de RLS |
| `plans` | Lê o plano do usuário ou do órgão e libera recursos (`canAccess(feature)`) |
| `events` | `trackEvent(name, props)` grava em `usage_events` |
| `leads` | Captura de leads das oficinas e da landing |

## Módulos (`src/modules/`)

Cada módulo tem a mesma estrutura:

```
src/modules/maturidade/
  components/   UI do módulo
  actions.ts    server actions
  queries.ts    leituras no Supabase
  scoring.ts    regras de cálculo (só no módulo maturidade)
  types.ts
  index.ts      o que o módulo expõe para o app
```

Um módulo é ligado ou desligado por plano em `src/core/plans/features.ts`. Exemplo: `prompts.premium` exige plano `individual` ou superior.

## Rotas principais

| Rota | Acesso | Descrição |
| --- | --- | --- |
| `/` | público | Landing da plataforma |
| `/oficina/[slug]` | público | Página do QR code de cada oficina: captura de lead e acesso aos prompts gratuitos |
| `/prompts` | público | Biblioteca, com itens premium bloqueados |
| `/prompts/[slug]` | público ou assinante | Detalhe do prompt, preenchimento de variáveis e cópia |
| `/d/[token]` | público | Resposta ao diagnóstico por convite, sem login |
| `/entrar` | público | Login |
| `/painel` | logado | Início da área logada |
| `/orgao/configuracoes` | admin | Dados do órgão, setores e membros |
| `/maturidade` | gestor | Lista de ciclos de diagnóstico |
| `/maturidade/[cicloId]` | gestor | Painel consolidado do ciclo |
| `/maturidade/[cicloId]/convite` | gestor | Link e QR code do convite |

## Diagnóstico sem login: como fica seguro

1. O gestor cria um ciclo; o banco gera `invite_token` aleatório (32 bytes, base64url).
2. O servidor abre `/d/[token]`, escolhe setor e perfil e responde.
3. A server action valida o token, o status `open` do ciclo e o payload (Zod) e grava usando o cliente `admin`, porque o respondente não tem sessão.
4. Proteção contra abuso: limite de envios por IP e por token (ex.: 30 por hora por IP) e um cookie que impede reenvio no mesmo navegador.
5. O gestor nunca lê `assessment_responses` diretamente: a RLS bloqueia. O painel usa a função `get_cycle_results(cycle_id)`, que só devolve agregados quando há 3 ou mais respostas no recorte.

## Camada de proteção de dados (para versões futuras)

Quando algum módulo passar a chamar APIs de IA (Redação, por exemplo), toda chamada passa por `src/core/ai/gateway.ts`, que:

1. Detecta e mascara CPF, CNPJ, e-mail, telefone, nomes próprios e números de processo antes do envio
2. Registra custo e uso por órgão
3. Permite trocar de fornecedor sem alterar os módulos

Na versão 1 não há chamadas a APIs de IA. O módulo Prompts apenas monta o texto para o usuário colar na ferramenta que preferir.

## Variáveis de ambiente

```
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=        # somente servidor
NEXT_PUBLIC_SITE_URL=             # usado nos links de convite e QR code
RATE_LIMIT_SALT=                  # para gerar hash de IP no limite de envios
```

## Decisões registradas

| Decisão | Motivo |
| --- | --- |
| Web + PWA, sem app nativo | Um código só, sem comissão das lojas, publicação imediata, funciona por QR code |
| Supabase com RLS | Isolamento por órgão garantido no banco, não só no código |
| Servidores respondem sem conta | Aumenta a adesão ao diagnóstico; conta só para gestores |
| Agregados mínimos de 3 respostas | Protege a identidade dos respondentes |
| Sem IA embarcada na v1 | Custo zero de API, LGPD simples, lançamento mais rápido |
