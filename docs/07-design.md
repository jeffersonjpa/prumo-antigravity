# 07 — Design

## Princípios

- **Celular primeiro.** O primeiro contato é quase sempre por QR code. Projete em 375 px e amplie.
- **Sóbrio e institucional.** O público são secretários e gestores. Nada de visual de infoproduto, contagem regressiva ou excesso de emoji.
- **Uma ação principal por tela.** Especialmente no questionário e na cópia de prompts.
- **Confiança visível.** Avisos de privacidade e anonimato sempre próximos do ponto de decisão, em linguagem simples.

## Cores (marca TBA)

Declare como tokens no `tailwind.config.ts`:

| Token | Nome | Hex | Uso |
| --- | --- | --- | --- |
| `brand-orange` | Laranja Energia | `#ED6400` | Botão principal, destaques |
| `brand-orange-light` | Laranja Inovação | `#F58634` | Hover, ilustrações |
| `brand-navy` | Azul Profundidade | `#1E3A8A` | Títulos, cabeçalho, gráficos (série principal) |
| `brand-blue` | Azul Conexão | `#0057FF` | Links, série secundária dos gráficos |
| `brand-gray` | Cinza Estabilidade | `#6C757D` | Texto secundário |
| `brand-gray-light` | Cinza Neutro | `#D3D3D3` | Bordas, divisórias |

Verifique contraste AA: texto branco sobre `#ED6400` funciona em botões com fonte de 16 px em negrito; para texto corrido, use `brand-navy` sobre fundo claro.

Cores dos níveis de maturidade (escala sequencial, do mais claro ao mais escuro em azul), para não sugerir "vermelho = ruim" em um diagnóstico de equipe.

## Tipografia

- Inter (ou a fonte do sistema) para interface
- Títulos em `brand-navy`, peso 600 a 700
- Corpo com 16 px no celular

## Componentes-chave

- **Cartão de prompt:** título, categoria, resumo em 2 linhas, cadeado se premium
- **Formulário de variáveis:** um campo por variável, prévia do texto final logo abaixo, botão Copiar fixo no rodapé do celular
- **Pergunta do diagnóstico:** afirmação em destaque, 5 botões grandes empilhados com o rótulo completo, e "Não sei avaliar" separado
- **Radar de maturidade:** 6 eixos, série do ciclo atual em `brand-navy` e do ciclo anterior em `brand-gray`
- **Alerta:** ícone, frase curta e o que fazer, sem tom alarmista

## Logo

Use o logo da TBA no rodapé ("uma solução TBA – Technology Business Academy"). O nome Prumo é provisório; até a decisão final, use um logotipo apenas tipográfico.
