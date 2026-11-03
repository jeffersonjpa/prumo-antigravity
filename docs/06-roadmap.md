# 06 — Roadmap e tarefas

Datas de referência: oficinas em Manaus (12/11/2026), Teresina (19/11/2026) e Porto Alegre (14/12/2026).

Marque `[x]` ao concluir cada tarefa.

## Marco 0 — Fundação e porta de entrada (até 10/11/2026)

Objetivo: ter a biblioteca gratuita de prompts e a captura de leads no ar antes da oficina de Manaus.

- [ ] Criar projeto Next.js + TypeScript strict + Tailwind + shadcn/ui
- [ ] Configurar projeto Supabase em `sa-east-1` e aplicar `0001_init.sql`
- [ ] Clientes Supabase em `src/lib/supabase/` (server, client, admin)
- [ ] `src/config/brand.ts` com nome, cores e textos de marca
- [ ] Script `scripts/seed.ts` idempotente para `prompts_v1.json` e `maturidade_v1.json`
- [ ] Landing `/` simples (o que é, módulos, contato da TBA)
- [ ] `/oficina/[slug]`: formulário de lead com consentimento LGPD, depois redireciona para `/prompts`
- [ ] `/prompts` e `/prompts/[slug]` com montagem de variáveis, cópia e aviso de dados
- [ ] Registro de eventos `prompt.viewed`, `prompt.copied`, `prompt.locked_view`
- [ ] Página de privacidade
- [ ] PWA: manifest, ícones, instalação no celular
- [ ] Deploy na Vercel com domínio provisório
- [ ] Gerar QR codes de `/oficina/manaus-2026-11` e `/oficina/teresina-2026-11`

## Marco 1 — Núcleo e diagnóstico de maturidade (até 05/12/2026)

Objetivo: gestores criam órgão, abrem um ciclo e veem o painel.

- [ ] Login por link mágico e Google (`/entrar`), middleware protegendo `(app)`
- [ ] Criar órgão, setores e convidar membros por e-mail
- [ ] Troca de órgão ativo para quem participa de mais de um
- [ ] `/maturidade`: criar, abrir e encerrar ciclo
- [ ] Tela de convite com link, QR code e texto para WhatsApp
- [ ] `/d/[token]`: resposta anônima no celular, uma dimensão por tela, rascunho no navegador
- [ ] Limite de envios por IP e bloqueio de reenvio no mesmo navegador
- [ ] `scoring.ts` com testes (pontuação, nível, faixa, alertas)
- [ ] `/maturidade/[cicloId]`: índice, nível, radar, gestão × equipe, alertas, "não sei avaliar", plano de ação
- [ ] Filtro por setor respeitando o mínimo de 3 respostas
- [ ] Testes de RLS: usuário de outro órgão não lê ciclo nem resultados
- [ ] Favoritos de prompts para usuários logados

## Marco 2 — Demonstração e relatório (até 14/12/2026)

Objetivo: usar o diagnóstico como demonstração na oficina de Porto Alegre, se a Motriz autorizar.

- [ ] Comparação com o ciclo anterior do mesmo órgão
- [ ] Exportar relatório do ciclo em PDF
- [ ] Ciclo de demonstração com dados fictícios para apresentar em oficina
- [ ] QR code de `/oficina/porto-alegre-2026-12`
- [ ] Painel interno da TBA: leads por origem, prompts mais copiados, ciclos abertos

## Marco 3 — Cobrança e plano individual (janeiro de 2027)

- [ ] Integração com Asaas: assinatura mensal no cartão para o plano `individual`
- [ ] Webhook do Asaas atualiza `subscriptions` (ativa, em atraso, cancelada)
- [ ] Página de planos e de gestão da assinatura
- [ ] Fluxo de contrato para órgãos: plano `orgao` ativado manualmente pela TBA
- [ ] E-mails de boas-vindas e de reengajamento para leads das oficinas
- [ ] Ampliar a biblioteca para 40 prompts

## Depois (2027)

- Painel multi-território para financiadores de formação
- Módulo Formação (micro-aulas, encontros ao vivo, certificado)
- Módulo Verifica (protocolo e alertas sobre deepfakes)
- Módulo Redação, com IA embarcada passando pela camada de proteção de dados
- Login gov.br
