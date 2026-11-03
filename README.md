# Prumo

Plataforma da TBA – Technology Business Academy para lideranças públicas usarem dados e IA com segurança. "Prumo" é um codinome provisório.

Versão 1: núcleo (contas, órgãos, equipes), módulo **Maturidade em Dados e IA** e módulo **Prompts**.

## Estrutura deste pacote

| Caminho | Conteúdo |
| --- | --- |
| `AGENTS.md` | Regras do projeto, lidas automaticamente pelo agente do Antigravity |
| `.agents/workflows/` | Workflows do Antigravity: `/nova-tarefa`, `/migracao-supabase`, `/revisao-lgpd` |
| `docs/00-prompt-inicial.md` | Primeiro prompt para colar no Antigravity |
| `docs/01` a `docs/07` | Visão do produto, arquitetura, dados, módulos, roadmap e design |
| `supabase/migrations/0001_init.sql` | Esquema inicial com RLS |
| `supabase/seed/` | Questionário de maturidade, recomendações e primeiros prompts |

## Como começar

1. Descompacte esta pasta e abra no Antigravity.
2. Crie o projeto no Supabase (região São Paulo) e tenha as chaves em mãos.
3. Cole o texto de `docs/00-prompt-inicial.md` na primeira conversa com o agente.
4. Aprove o plano do Marco 0 e siga o roadmap tarefa a tarefa.

Stack: Next.js, TypeScript, Supabase, Tailwind, shadcn/ui, Vercel.
