# My Skills

Skills que uso para tornar conversas, estudos e trabalho de desenvolvimento mais claros e verificáveis. Cada pasta contém um `SKILL.md`; algumas também incluem referências, modelos ou scripts usados pela própria skill.

<p align="center">
  <a href="https://ko-fi.com/gerson_dantas" target="_blank" rel="noopener noreferrer">
    <img src="https://github.com/GersonDantas/img/blob/b81c0ba4adb694a7a65a91f64f7a1670d4d5c101/qrcode.png" alt="Apoie meu trabalho com um café no Ko-fi" height="200">
  </a>
</p>

<p align="center">Se estas skills ajudam no seu trabalho, você pode <a href="https://ko-fi.com/gerson_dantas">me pagar um café ☕</a>.</p>

## Por que estas skills existem

Uma skill registra um jeito de trabalhar que vale repetir. A intenção desta coleção é reduzir explicações recomeçadas, preservar decisões importantes e pedir evidências antes de concluir que um problema foi resolvido. Algumas skills ajudam a conversar e aprender; outras organizam revisão de código, provas de bugs e merges.

Elas não substituem as regras do projeto nem as decisões de quem está trabalhando nele. Antes de usar uma skill em um repositório, confira suas instruções, dependências e limites de autorização.

## Escolha pelo momento do trabalho

| Situação | Skill | O que faz | Como ajuda |
| --- | --- | --- | --- |
| Preciso de uma resposta curta | [`caveman`](./caveman/SKILL.md) | Reduz texto supérfluo em níveis de concisão, preservando precisão técnica. | Facilita ler atualizações e decisões sem perder fatos, riscos ou comandos. |
| Quero entender um assunto aos poucos | [`explain-in-steps`](./explain-in-steps/SKILL.md) | Apresenta uma ideia por vez e avança quando eu pedir. | Evita uma explicação longa antes de eu compreender a base. |
| Preciso enxergar um fluxo ou conceito | [`show-me`](./show-me/SKILL.md) | Usa diagramas, esboços de código e visuais no nível de detalhe escolhido. | Torna relações e alternativas mais fáceis de discutir. |
| Quero testar uma ideia antes de construir | [`grill-me`](./grill-me/SKILL.md) | Entrevista sobre um plano, uma pergunta de cada vez, com resposta recomendada. | Expõe decisões pendentes e dependências cedo. |
| Quero aprender um tema ao longo de sessões | [`teach`](./teach/SKILL.md) | Mantém missão, recursos, lições e registros de aprendizado em um espaço de estudo. | Dá continuidade ao aprendizado e cria material de consulta. |
| Preciso escrever uma mensagem de commit | [`commit-message-copy`](./commit-message-copy/SKILL.md) | Produz uma mensagem curta, em estilo Git, a partir da mudança. | Poupa tempo e deixa o histórico mais legível. |
| Encontrei um bug e quero prová-lo | [`test-proof`](./test-proof/SKILL.md) | Define o comportamento esperado e cria o menor teste que falha pelo motivo certo. | Separa evidência do defeito da correção de produção. |
| Vou revisar um PR ou MR | [`review-proof-inline`](./review-proof-inline/SKILL.md) | Revisa comportamento e complexidade, verifica achados e controla separadamente prova e publicação de comentários. | Ajuda a evitar apontamentos sem evidência ou comentários publicados antes da triagem. |
| O PR ou MR envolve Go | [`review-go-proof-inline`](./review-go-proof-inline/SKILL.md) | Acrescenta critérios específicos de Go ao fluxo da revisão geral. | Considera contratos, concorrência, erros e testes sem transformar preferências de estilo em bugs. |
| Surgiram conflitos de merge | [`resolve-conflicts`](./resolve-conflicts/SKILL.md) | Planeja a resolução, combina mudanças compatíveis e valida o resultado. | Reduz a chance de descartar comportamento de um dos lados. |
| Estou resolvendo conflitos de um MR em um worktree | [`resolve-mr-conflicts`](./resolve-mr-conflicts/SKILL.md) | Registra decisões, preserva o comportamento da branch de destino e executa verificações focadas. | Mantém a resolução auditável e evita misturar mudanças alheias. |
| O merge é grande ou os dois lados mudaram o mesmo fluxo | [`merge-conductor`](./merge-conductor/SKILL.md) | Mapeia conflitos textuais e semânticos, conduz a resolução por etapas e compara o resultado com os dois lados originais. | Ajuda a detectar regressões mesmo quando o Git conclui o merge sem conflitos aparentes. |

## Como elas se encaixam no dia a dia

**Antes de implementar:** `grill-me` ajuda a fechar decisões; `show-me` e `explain-in-steps` ajudam a compartilhar o entendimento. Quando o objetivo é aprender um assunto de forma contínua, `teach` mantém o contexto entre sessões.

**Durante o desenvolvimento:** `test-proof` transforma uma suspeita de bug em um teste observável. `commit-message-copy` ajuda a registrar mudanças de forma breve. `caveman` mantém a comunicação enxuta quando esse estilo é útil.

**Na revisão e integração:** `review-proof-inline` organiza evidência e triagem; `review-go-proof-inline` acrescenta critérios de Go. `resolve-conflicts` atende conflitos comuns, `resolve-mr-conflicts` cuida do fluxo de um MR, e `merge-conductor` entra quando a divergência exige análise mais profunda.

## Uso

Abra a pasta da skill desejada e leia o `SKILL.md`. Para usar no Codex, instale ou compartilhe a pasta completa da skill, inclusive `references/`, `assets/`, `scripts/` e `agents/` quando existirem. Algumas skills dependem de ferramentas ou de aprovação explícita para certas ações; esses requisitos estão descritos no respectivo arquivo.

A skill `resolve-conflicts` declara como fonte o [projeto Forge](https://github.com/antinomyhq/forge/tree/main/.forge/skills/resolve-conflicts). Consulte o arquivo antes de reutilizá-la ou adaptá-la.

> Este catálogo descreve as skills pessoais sem vínculo com a Laudite. A pasta `mr-review-proof-inline`, já existente neste repositório, é específica da Laudite e não faz parte da lista acima.
