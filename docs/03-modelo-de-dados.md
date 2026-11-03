# 03 — Modelo de dados

O esquema completo está em `supabase/migrations/0001_init.sql`. Este documento explica as decisões.

## Núcleo

| Tabela | Para que serve |
| --- | --- |
| `profiles` | Um registro por usuário do Supabase Auth, criado por trigger no cadastro |
| `organizations` | Órgãos públicos (prefeitura, secretaria, autarquia etc.) |
| `memberships` | Quem pertence a qual órgão e com que papel (`admin`, `gestor`, `membro`) |
| `org_units` | Setores do órgão, usados para recortar o diagnóstico |
| `subscriptions` | Plano de um usuário **ou** de um órgão (`free`, `individual`, `equipe`, `orgao`) |
| `leads` | Contatos captados pelo QR code das oficinas e pela landing, com consentimento |
| `usage_events` | Eventos de uso (`prompt.copied`, `cycle.opened`, `response.submitted` etc.) |

Regras:
- Quem cria um órgão vira `admin` dele automaticamente (trigger `on_org_created`).
- Todo usuário novo recebe um plano `free` pessoal (trigger `on_auth_user_created`).
- O plano efetivo é o maior entre o pessoal e o dos órgãos do usuário (`current_plan()`).
- `leads` e `usage_events` não têm política de acesso para o cliente: só server actions com service role gravam e leem.

## Módulo Maturidade

```
assessment_templates ─┬─ assessment_dimensions ─┬─ assessment_questions
                      │                         └─ assessment_recommendations
                      └─ assessment_cycles ── assessment_responses ── assessment_answers
```

| Tabela | Para que serve |
| --- | --- |
| `assessment_templates` | Versão do questionário (`maturidade-dados-ia`, versão 1) |
| `assessment_dimensions` | As 6 dimensões |
| `assessment_questions` | As 24 afirmações |
| `assessment_recommendations` | Recomendação por dimensão e faixa (`baixo`, `medio`, `alto`) |
| `assessment_cycles` | Uma rodada de diagnóstico de um órgão, com `invite_token` |
| `assessment_responses` | Uma resposta anônima: setor e perfil (`gestao` ou `equipe`), sem identificar a pessoa |
| `assessment_answers` | O valor de 1 a 5 de cada afirmação; `null` significa "não sei avaliar" |

Regras:
- Respostas não guardam usuário, e-mail ou IP. O limite de envios usa um hash de IP que fica fora do banco (cache em memória ou KV).
- Nenhuma política RLS libera leitura de `assessment_responses` ou `assessment_answers`. O painel usa `get_cycle_results()`, que exige papel `admin` ou `gestor` e descarta grupos com menos de 3 respostas.
- Mudanças no questionário geram uma nova `version` do template. Ciclos antigos continuam ligados à versão com que foram respondidos, o que preserva a comparação histórica.

## Módulo Prompts

| Tabela | Para que serve |
| --- | --- |
| `prompt_categories` | Categorias da biblioteca |
| `prompts` | Modelos, com corpo em texto e variáveis `{{chave}}` descritas em `variables` |
| `prompt_favorites` | Favoritos de cada usuário |
| `prompts_public` (view) | Lista pública que devolve `body = null` para prompts premium quando o usuário não tem plano pago |

A interface deve sempre ler de `prompts_public`, nunca de `prompts` diretamente.

## Carga inicial

`supabase/seed/` traz o conteúdo em JSON:
- `maturidade_v1.json` — template, dimensões, afirmações e recomendações
- `prompts_v1.json` — categorias e primeiros prompts

Crie um script `scripts/seed.ts` que leia esses arquivos e faça upsert usando a service role. O script deve ser idempotente: rodar duas vezes não duplica nada.
