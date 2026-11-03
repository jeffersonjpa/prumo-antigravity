---
description: Criar uma nova migração de banco no Supabase com RLS e teste
---

1. Nunca altere uma migração já aplicada. Crie `supabase/migrations/NNNN_descricao.sql` com o próximo número.
2. Para cada tabela nova:
   - `enable row level security`
   - políticas explícitas de select, insert, update e delete, usando `is_member()` e `has_role()`
   - índices nas chaves estrangeiras usadas em filtros
3. Se a tabela guardar dado pessoal, justifique no topo do arquivo por que o dado é necessário.
4. Atualize `docs/03-modelo-de-dados.md`.
5. Gere os tipos: `npx supabase gen types typescript --linked > src/lib/supabase/database.types.ts`.
6. Escreva um teste de RLS: um usuário de outro órgão não lê nem altera os registros.
7. Mostre o SQL completo e espere minha aprovação antes de aplicar no projeto remoto.
