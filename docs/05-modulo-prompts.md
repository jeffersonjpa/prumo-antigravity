# 05 — Módulo Prompts

## Objetivo

Biblioteca de modelos de prompt para documentos e rotinas da gestão pública. É a porta de entrada do Prumo: os participantes das oficinas chegam pelo QR code, usam os prompts gratuitos e são convidados a assinar para acessar a biblioteca completa.

## Fluxo

1. Usuário abre `/prompts` (ou chega por `/oficina/[slug]`)
2. Navega por categoria ou busca por palavra
3. Abre um prompt: vê o resumo, as dicas e o formulário de variáveis
4. Preenche as variáveis (ex.: destinatário, assunto); o texto final é montado em tempo real
5. Toca em **Copiar** e cola no ChatGPT, Gemini ou NotebookLM
6. Botões de atalho abrem o ChatGPT e o Gemini em nova aba (sem integração; só o link)

Prompts premium aparecem na lista com cadeado. Ao abrir, o usuário vê título, resumo e variáveis, mas o corpo vem `null` da view `prompts_public` e a tela mostra o convite para assinar.

## Variáveis

O corpo usa `{{chave}}`. O campo `variables` descreve cada uma:

```json
[
  { "key": "destinatario", "label": "Destinatário (cargo e órgão)", "placeholder": "Secretário Municipal de Saúde", "required": true },
  { "key": "assunto", "label": "Assunto", "placeholder": "Solicitação de dados de atendimento", "required": true }
]
```

Regras de montagem (`src/modules/prompts/render.ts`, com testes):
- Variável preenchida: substitui `{{chave}}` pelo valor
- Variável vazia e obrigatória: botão Copiar desabilitado
- Variável vazia e opcional: substitui por `[chave]` para o usuário completar depois
- Nunca enviar os valores preenchidos ao servidor; a montagem acontece no navegador

## Aviso fixo em toda tela de prompt

> Antes de colar em uma ferramenta de IA, confira se o texto não contém dados pessoais, informações sigilosas ou números de processos sob sigilo. Revise sempre a resposta antes de usar.

## Eventos registrados

- `prompt.viewed` (slug)
- `prompt.copied` (slug, categoria)
- `prompt.locked_view` (slug) — interesse em conteúdo premium
- `prompt.favorited` (slug)

Esses eventos alimentam a decisão sobre quais prompts produzir e quais liberar.

## Categorias iniciais

| Slug | Nome |
| --- | --- |
| `documentos-oficiais` | Documentos oficiais |
| `sintese-e-leitura` | Síntese e leitura de documentos |
| `planejamento` | Planejamento e acompanhamento |
| `comunicacao` | Comunicação institucional |
| `analise-de-dados` | Análise de dados |
| `verificacao` | Verificação e revisão |

Os primeiros prompts estão em `supabase/seed/prompts_v1.json`. A meta é chegar a 40 prompts até março de 2027, com cerca de 1/3 gratuito.

## Critérios de aceite

- [ ] Biblioteca e prompts gratuitos funcionam sem login, no celular
- [ ] Prompt premium nunca entrega o corpo a quem não tem plano (testar pela view, não só pela tela)
- [ ] Montagem com variáveis coberta por testes (obrigatória vazia, opcional vazia, caracteres especiais, variável repetida)
- [ ] Copiar funciona em iOS Safari e Android Chrome
- [ ] Favoritos só para usuários logados
- [ ] Busca por título, resumo e tags
