# 00 — Prompt inicial para o Antigravity

Abra a pasta do projeto no Antigravity e cole o texto abaixo na primeira conversa com o agente.

---

Você vai desenvolver o Prumo, uma plataforma web da TBA para lideranças públicas usarem dados e IA com segurança.

Antes de qualquer código, leia nesta ordem: `AGENTS.md`, `docs/01-visao-produto.md`, `docs/02-arquitetura.md`, `docs/03-modelo-de-dados.md`, `docs/04-modulo-maturidade.md`, `docs/05-modulo-prompts.md`, `docs/06-roadmap.md` e `docs/07-design.md`. O esquema do banco está em `supabase/migrations/0001_init.sql` e o conteúdo inicial em `supabase/seed/`.

Depois de ler:
1. Me diga em até 10 linhas o que você entendeu do produto e da versão 1.
2. Liste dúvidas ou contradições que encontrou nos documentos.
3. Proponha o plano de execução do Marco 0, com a ordem das tarefas e o que você precisa de mim (contas, chaves, domínio).

Não comece a implementar até eu aprovar o plano. Use o workflow `/nova-tarefa` para cada tarefa do roadmap, `/migracao-supabase` para mudanças de banco e `/revisao-lgpd` antes de cada deploy.

---

## O que você vai precisar ter em mãos

- Conta no Supabase (projeto criado na região São Paulo) com URL, anon key e service role key
- Conta na Vercel ligada ao repositório
- Repositório no GitHub
- Domínio ou subdomínio provisório (ex.: `prumo.tbaacademy.tech`)
- Logo da TBA em SVG ou PNG para o rodapé
