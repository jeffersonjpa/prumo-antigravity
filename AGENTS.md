# Prumo — regras do projeto

Prumo é o codinome de uma plataforma da TBA – Technology Business Academy para lideranças públicas usarem dados e IA com segurança. O nome pode mudar: concentre o nome do produto em `src/config/brand.ts` e nunca o repita em textos fixos espalhados pelo código.

Leia `docs/` antes de implementar qualquer funcionalidade. A ordem de leitura é: `01-visao-produto.md`, `02-arquitetura.md`, `03-modelo-de-dados.md`, depois o documento do módulo em que você vai trabalhar e `06-roadmap.md` para saber o marco atual.

## Stack

- Next.js (App Router) com TypeScript em modo `strict`
- Supabase: Postgres, Auth (link mágico por e-mail e Google) e Row Level Security
- Tailwind CSS e shadcn/ui
- Zod para validar toda entrada de formulário e de server action
- Recharts para gráficos do painel de maturidade
- Deploy na Vercel; banco na região `sa-east-1` (São Paulo)
- PWA instalável (manifest e service worker simples), sem app nativo

## Organização do código

- `src/app/(public)` — páginas sem login: landing, biblioteca gratuita de prompts, resposta ao diagnóstico por convite
- `src/app/(app)` — área logada: painel, órgão, módulos
- `src/modules/<modulo>/` — código de cada módulo (`maturidade`, `prompts`): componentes, server actions, consultas e tipos
- `src/core/` — núcleo compartilhado: auth, organizações, permissões, planos, eventos de uso
- `src/lib/supabase/` — clientes do Supabase (`server.ts`, `client.ts`, `admin.ts`)
- `supabase/migrations/` — toda mudança de banco é uma migração SQL nova; nunca edite migração já aplicada
- `supabase/seed/` — conteúdo inicial em JSON (questionário, recomendações, prompts)

Um módulo nunca importa código de outro módulo. O que for compartilhado vai para `src/core/`.

## Segurança e LGPD (obrigatório)

- Toda tabela com dado de órgão ou usuário tem RLS ativado e políticas explícitas. Sem exceção.
- O cliente `admin` (service role) só pode ser usado em server actions e rotas de servidor, nunca em componente cliente. Cada uso precisa de um comentário explicando por quê.
- Respostas individuais do diagnóstico de maturidade nunca são exibidas ao gestor. O painel mostra apenas agregados, e só quando houver pelo menos 3 respostas no recorte (ciclo, setor ou perfil).
- Não coletar CPF, matrícula, telefone ou dados sensíveis. E-mail, nome, cargo e órgão bastam.
- Todo formulário que coleta dado pessoal mostra o aviso de privacidade e registra o consentimento (`consent_lgpd = true` e data).
- Nenhum dado de usuário é enviado a APIs de IA na versão 1. Se isso mudar, a chamada passa obrigatoriamente pela camada de proteção descrita em `docs/02-arquitetura.md`.
- Segredos só em variáveis de ambiente. Nunca em código, nunca em `NEXT_PUBLIC_*`, exceto a URL e a anon key do Supabase.

## Interface e texto

- Toda a interface em português do Brasil.
- Mobile first: a maior parte do uso começa por QR code no celular. Teste cada tela em 375 px de largura.
- Cores da marca TBA em `docs/07-design.md`. Use tokens do Tailwind, nunca hex solto no componente.
- Textos diretos e concretos. Não use: "muda tudo", "transforma completamente", "é revolucionário", "game changer", "nunca mais será o mesmo", "impacto transformador". Evite construções como "não é apenas X, é Y".
- Linguagem neutra e suprapartidária: nada de referência a partidos, governos ou candidatos em textos, exemplos ou dados de demonstração.
- Acessibilidade: contraste AA, rótulos em todos os campos, navegação por teclado.

## Qualidade

- Antes de concluir uma tarefa: `npm run lint`, `npm run typecheck` e `npm run test` sem erros.
- Testes unitários (Vitest) para toda regra de cálculo, em especial o cálculo de maturidade em `src/modules/maturidade/scoring.ts`.
- Teste de RLS para cada tabela nova: um usuário de outro órgão não consegue ler nem escrever.
- Commits pequenos, mensagem em português no imperativo ("Adiciona convite do ciclo de diagnóstico").
- Ao terminar uma tarefa do roadmap, marque-a em `docs/06-roadmap.md`.

## Como trabalhar comigo

- Antes de uma mudança grande (nova tabela, novo módulo, mudança de fluxo), apresente um plano curto e espere aprovação.
- Se algo nos documentos estiver ambíguo ou contraditório, pergunte em vez de supor.
- Não adicione dependências novas sem justificar em uma linha.
