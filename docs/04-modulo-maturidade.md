# 04 — Módulo Maturidade em Dados e IA

## Objetivo

Mostrar a um órgão público em que ponto ele está no uso de dados e IA, onde gestão e equipe enxergam a situação de forma diferente, e quais os próximos passos. É a versão em software do Painel de Maturidade da metodologia AGIA da TBA.

## Fluxo

```
Gestor cria ciclo ──► Gestor compartilha link/QR ──► Servidores respondem (sem conta)
       │                                                        │
       └──────────── Painel consolidado (mín. 3 respostas) ◄────┘
                              │
                     Gestor encerra o ciclo
                              │
              Relatório + plano de ação  ──►  Novo ciclo em 3 a 6 meses (evolução)
```

### 1. Criar ciclo (gestor)
- Título (ex.: "Diagnóstico 1º semestre 2027"), datas de abertura e encerramento opcionais
- Escolhe os setores que aparecerão como opção para os respondentes (ou nenhum)
- Status inicial `draft`; ao abrir, vira `open` e o convite passa a funcionar

### 2. Convite
- Tela com link `/d/[token]`, QR code para projetar ou imprimir e botão de copiar
- Texto pronto para mandar no WhatsApp da equipe
- Contador de respostas atualizado (`get_cycle_response_count`)

### 3. Responder (servidor, celular)
- Tela de boas-vindas: o que é, quanto tempo leva (cerca de 7 minutos), aviso de anonimato e de privacidade
- Perfil: "Faço parte da gestão (secretário, diretor, coordenador)" ou "Faço parte da equipe"
- Setor (se o gestor cadastrou setores)
- Uma dimensão por tela, com as 4 afirmações; escala de 1 a 5 e opção "Não sei avaliar"
- Barra de progresso; respostas guardadas no navegador até o envio, para não perder se a conexão cair
- Confirmação final com convite opcional para conhecer o Prumo (lead, com consentimento separado)

### 4. Painel (gestor)
- Só aparece com 3 ou mais respostas; antes disso, mostra o contador e a mensagem "faltam X respostas"
- Índice geral (0 a 100) e nível
- Radar com as 6 dimensões
- Barras gestão × equipe por dimensão, quando cada grupo tiver 3 ou mais respostas
- Alertas de divergência (ver cálculo)
- Percentual de "não sei avaliar" por dimensão (indica falta de informação na equipe)
- Plano de ação: as 3 dimensões com menor pontuação e a recomendação da faixa correspondente
- Filtro por setor (respeitando o mínimo de 3)
- Comparação com o ciclo anterior do mesmo órgão, quando existir
- Exportar relatório em PDF (Marco 2)

## Escala de resposta

| Valor | Rótulo |
| --- | --- |
| 1 | Não existe ou não acontece |
| 2 | Existem iniciativas isoladas |
| 3 | Existe, mas de forma parcial |
| 4 | Existe e é aplicado na maior parte do órgão |
| 5 | Está consolidado e é acompanhado |
| — | Não sei avaliar (não entra no cálculo) |

## Cálculo (`src/modules/maturidade/scoring.ts`)

Implementar como funções puras, cobertas por testes unitários.

1. **Média da dimensão por respondente**: média das afirmações respondidas daquela dimensão (ignora "não sei"). Se o respondente marcou "não sei" em todas, ele não entra naquela dimensão.
2. **Média da dimensão no grupo**: média das médias individuais (é o que `get_cycle_results` devolve).
3. **Pontuação da dimensão (0 a 100)**: `(média − 1) / 4 × 100`, arredondada para inteiro.
4. **Índice geral**: média simples das 6 pontuações de dimensão.
5. **Nível**:

| Índice | Nível | Leitura |
| --- | --- | --- |
| 0 a 19 | 1 — Inicial | Uso de dados e IA esporádico e individual |
| 20 a 39 | 2 — Exploratório | Iniciativas pontuais, sem coordenação |
| 40 a 59 | 3 — Estruturado | Há regras e responsáveis, mas a aplicação é desigual |
| 60 a 79 | 4 — Integrado | Dados e IA fazem parte dos processos principais |
| 80 a 100 | 5 — Avançado | Uso acompanhado por indicadores e revisado com frequência |

6. **Faixa para recomendação**: pontuação da dimensão < 40 → `baixo`; 40 a 69 → `medio`; ≥ 70 → `alto`.
7. **Alertas**:
   - *Divergência na equipe*: desvio padrão da dimensão ≥ 1,0 → "As respostas variam muito: vale conversar com a equipe sobre esta dimensão."
   - *Gestão × equipe*: diferença entre as médias dos dois perfis ≥ 0,75 → "Gestão e equipe enxergam esta dimensão de formas diferentes."
   - *Falta de informação*: 30% ou mais de "não sei avaliar" na dimensão → "Parte da equipe não sabe como esta dimensão funciona no órgão."

## Dimensões

| Código | Dimensão | O que avalia |
| --- | --- | --- |
| EST | Estratégia e liderança | Objetivos, responsáveis, recursos e acompanhamento |
| GOV | Governança, ética e LGPD | Regras de uso, proteção de dados e revisão humana |
| DAD | Dados | Disponibilidade, qualidade, integração e abertura dos dados |
| PES | Pessoas e competências | Capacitação, senso crítico e segurança para experimentar |
| USO | Processos e uso | Uso real da IA no dia a dia e projetos com resultado medido |
| INF | Infraestrutura e ferramentas | Acesso a ferramentas, conectividade, sistemas e apoio da TI |

As 24 afirmações e as 18 recomendações estão em `supabase/seed/maturidade_v1.json`.

## Critérios de aceite

- [ ] Gestor cria, abre e encerra um ciclo
- [ ] Link e QR code do convite funcionam no celular; ciclo `draft` ou `closed` mostra mensagem clara
- [ ] Servidor responde em até 7 minutos no celular, sem criar conta, e não consegue enviar duas vezes do mesmo navegador
- [ ] Gestor de outro órgão não acessa ciclo nem resultados (teste de RLS)
- [ ] Painel não exibe nada com menos de 3 respostas no recorte
- [ ] Cálculos de pontuação, nível, faixa e alertas cobertos por testes com casos de borda (tudo "não sei", uma dimensão sem respostas, empate)
- [ ] Plano de ação mostra as 3 dimensões mais baixas com as recomendações certas
