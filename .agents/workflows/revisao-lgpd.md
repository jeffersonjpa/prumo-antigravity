---
description: Revisar uma funcionalidade quanto a privacidade, LGPD e segurança antes de publicar
---

Revise as mudanças pendentes e responda, item a item, com "ok" ou com o problema e o arquivo:

1. Algum dado pessoal novo é coletado? Ele é necessário? Há aviso de privacidade e consentimento registrado?
2. Alguma tabela nova ou alterada está sem RLS ou sem política explícita?
3. O cliente `admin` (service role) aparece em código que roda no navegador?
4. Alguma tela ou consulta expõe resposta individual do diagnóstico ou recorte com menos de 3 respostas?
5. Algum valor preenchido pelo usuário em prompts é enviado ao servidor?
6. Há segredo em código, em log ou em variável `NEXT_PUBLIC_*` indevida?
7. Algum texto de interface usa termos proibidos no `AGENTS.md` ou faz referência partidária?
8. A funcionalidade funciona em 375 px e com navegação por teclado?

Termine com uma lista do que precisa ser corrigido antes do deploy.
