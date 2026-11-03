# 01 — Visão do produto

## O que é

Prumo é uma plataforma web, instalável no celular, para lideranças públicas usarem dados e IA com segurança. É organizada em módulos que compartilham um núcleo comum (contas, órgãos, equipes, planos e registro de uso).

Nasce das oficinas de letramento em IA que a TBA conduz para o Instituto Motriz com secretários e gestores públicos (Manaus em 12/11/2026, Teresina em 19/11/2026 e Porto Alegre em 14/12/2026, cerca de 100 pessoas em cada).

## Problema

- Gestores públicos já usam IA generativa por conta própria, sem diretrizes e sem saber o que não podem inserir nas ferramentas.
- Órgãos não sabem em que ponto estão no uso de dados e IA, nem por onde começar.
- Quem financia formação em escala (como a Motriz) precisa medir a evolução dos territórios ao longo do tempo.

## Público

| Perfil | O que quer | Como paga |
| --- | --- | --- |
| Gestor público (secretário, diretor, coordenador) | Usar IA no trabalho com segurança e rapidez | Plano individual no cartão |
| Órgão (prefeitura, secretaria, autarquia) | Saber seu nível de maturidade e ter um plano de ação | Contrato anual |
| Financiador de formação (ex.: Motriz) | Acompanhar vários territórios e comparar evolução | Contrato anual |
| Servidor da equipe | Responder o diagnóstico e usar os prompts | Não paga; é convidado pelo gestor |

## Escopo da versão 1

**Núcleo**
- Cadastro e login por link mágico ou Google
- Organizações (órgãos), setores e membros com papéis `admin`, `gestor` e `membro`
- Captura de leads pelo QR code das oficinas, com consentimento LGPD
- Registro de eventos de uso para o painel e para métricas do produto
- Campo de plano (`free`, `individual`, `equipe`, `orgao`) já no banco; cobrança fica para o Marco 3

**Módulo Maturidade em Dados e IA** (detalhes em `04-modulo-maturidade.md`)
- Questionário com 6 dimensões e 24 afirmações em escala de 1 a 5
- O gestor abre um ciclo de diagnóstico e convida a equipe por link ou QR code
- Servidores respondem sem precisar criar conta
- Painel consolidado: índice geral, nível, radar por dimensão, comparação gestão × equipe, divergências e plano de ação sugerido
- Reavaliação: novos ciclos mostram a evolução em relação ao anterior

**Módulo Prompts** (detalhes em `05-modulo-prompts.md`)
- Biblioteca de modelos de prompt para documentos e rotinas públicas, com variáveis para preencher
- Parte gratuita sem login (porta de entrada pelas oficinas) e parte premium para assinantes
- Copiar o prompt preenchido com um toque, para colar no ChatGPT, Gemini ou NotebookLM
- Favoritos e registro de uso

## Fora da versão 1

- Módulos Redação, Formação e Verifica (planejados, ver `06-roadmap.md`)
- Chamadas a APIs de IA dentro da plataforma
- Cobrança automática (entra no Marco 3, com Asaas)
- Painel multi-território para financiadores (entra depois do primeiro contrato)
- Login gov.br

## Métricas de sucesso do primeiro trimestre

- 50% dos participantes das oficinas se cadastram pelo QR code
- 10% dos cadastrados viram assinantes em até 60 dias
- Pelo menos 3 órgãos completam um ciclo de diagnóstico com 10 ou mais respostas
- Pelo menos 1 contrato anual com órgão ou financiador até março/2027
- Cancelamento mensal de assinantes abaixo de 6%
