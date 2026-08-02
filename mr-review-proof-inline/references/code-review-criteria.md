# Laudite Code Review Criteria

## Source Metadata

- Team: Laudite
- Official source: https://app.notion.com/p/Padr-es-e-Crit-rios-de-Aceite-para-Code-Review-f19cadaa1f4142038d9241ce2918d1ab
- Notion page ID: `f19cadaa1f4142038d9241ce2918d1ab`
- Source title: `Padrões e Critérios de Aceite para Code Review`
- Source last edited: `2026-03-18T11:22:00.000Z`
- Snapshot captured: `2026-07-21`
- Expected official top-level named criteria: `95`

This bundled file is the sole runtime source for review criteria. The source link and dates are retained only for provenance and controlled manual updates.

## Contents

1. Laudite supplemental criteria
2. Official Notion snapshot
   - Princípios Gerais
   - Padrões de Componentes Vue.js
   - Arquitetura e Reutilização
   - Estilização
   - Nomenclatura e Convenções
   - Limpeza e Qualidade do Código
   - Gerenciamento de Memória e Ciclo de Vida
   - Processo e Colaboração

## Laudite Supplemental Criteria

These criteria extend the official snapshot and are mandatory for this skill.

### Error Contracts And Constants

- **Strings de contrato de erro:** Centralizar em constantes strings repetidas, códigos, chaves, estados e mensagens que façam parte de contratos públicos de erro ou que já possuam catálogo no domínio. Mensagens internas, únicas e sem reutilização podem permanecer inline.
- **Compatibilidade do contrato de erro:** Validar a assinatura real do construtor ou helper, o status HTTP, o código, a mensagem e os metadados enviados ao consumidor. Uma mensagem em constante não compensa argumentos invertidos ou um contrato incompatível.
- **Reutilização de catálogo de domínio:** Quando o domínio já possuir constantes de erros ou mensagens, ampliar e reutilizar esse catálogo antes de criar literais ou um segundo catálogo concorrente.

## Official Notion Snapshot

<!-- OFFICIAL_NOTION_SNAPSHOT_START -->

Este documento centraliza as boas práticas e os critérios de aceite que devem ser seguidos durante o processo de revisão de código, garantindo a qualidade, consistência e manutenibilidade do nosso software.

> 💡 Verificar também a documentação na pasta ai-tasks/prompts/code-review presente no repositório
> 

---

São as diretrizes fundamentais que norteiam todas as outras regras.

## 1. Princípios Gerais

- **Legibilidade e Eficiência:** O código deve ser sempre legível, eficiente e consistente com o restante da base de código.
- **Prevenção de Erros:** Verificar se nenhuma mudança introduz um problema, bug ou efeito colateral inesperado em outras partes do sistema.
- **Impacto Sistêmico:** Considerar o impacto das mudanças na performance geral e na arquitetura do sistema.
- **Segurança:** Garantir que nenhuma vulnerabilidade de segurança foi introduzida e que nenhuma informação sensível foi exposta.

---

## 2. Padrões de Componentes Vue.js

Regras específicas para a estrutura e implementação de componentes Vue.

### Estrutura do Arquivo

- Todo componente `.vue` deve seguir a estrutura padrão de `<template>`, `<script>` e `<style>`.
    
    ```html
    <template>
      <!-- Conteúdo HTML aqui -->
    </template>
    
    <script>
    export default {
      // Lógica do componente aqui
    }
    </script>
    
    <style scoped lang="scss">
      /* Estilos aqui */
    </style>
    
    ```
    
- Caso o estilo seja externalizado, a tag `<style>` deve referenciar o arquivo `.scss` correspondente.
    
    ```html
    <style scoped lang="scss" src="./style.scss"></style>
    
    ```
    

### Boas Práticas

- **Adicionar a propriedade `name`:** Para facilitar o debug (especialmente com Vue DevTools), todo componente deve ter a propriedade `name`.
    
    ```jsx
    export default {
      name: 'MeuComponente',
      // ...
    }
    
    ```
    
- **`v-if` vs. `v-show`:** Prefira `v-if` para renderização condicional. Use `v-show` apenas se o custo de alternar a visibilidade for alto e frequente, pois `v-if` garante que o componente não seja renderizado no DOM, economizando memória.
- **`computed` vs. `method`:** Se um método não recebe parâmetros e depende de dados reativos, transforme-o em uma `computed property`. Propriedades computadas são cacheadas e reavaliadas apenas quando suas dependências mudam.
- **`computed` vs `data`**: Se uma computed apenas retorna uma constante, a mesma poderia fazer parte do data ao invés de ser uma computed. Ao contrário de propriedades do data, que são estáticas e não são recalculadas, propriedades computadas acabam sendo recalculadas se alguma de suas dependências for modificada.
- **Computeds que retornam funções:** Se uma computed retorna uma função, o ideal seria ela ser um método.
- **Computeds que são usadas apenas uma vez:** Se uma computed é usada apenas uma vez, avaliar se essa computada pode ser um método, já que evita reprocessamento.
- **Computeds usadas apenas dentro de outros métodos:** Se uma computed é usada apenas dentro de outros métodos, avaliar se essa computada pode ser um método, já que evita reprocessamento.
- **Propriedades recebendo funções:** Se uma propriedade recebe o valor de uma função dentro de outra função, o ideal seria declará-la como um método. Exemplo:
    
    ```jsx
    async method() {
          // [...]
    
          this.innerFunc = () => {
            // [...]
          }
    
          // [...]
    }
    
    ```
    
    Nesse caso, innerFunc deveria ter sido declarado como um dos métodos do componente.
    
- **Valores hardcoded:** Evitar valores hardcoded. Quando necessário usar uma constante, criar uma propriedade no data do componente e/ou importar da pasta de constantes.
- **Props Booleanas:** Evite passar o valor `true` explicitamente para props booleanas. A simples presença da prop já a define como `true`.
    
    ```html
    <!-- ❌ Evitar -->
    <meu-componente :modal-visivel="true" />
    
    <!-- ✅ Preferir -->
    <meu-componente modal-visivel />
    
    ```
    
- **Função `data`:** Ao criar componentes, utilize a sintaxe de função para a propriedade `data`, evitando arrow functions para garantir o `this` correto.
    
    ```jsx
    data () {
      return {
        meuDado: 'valor inicial'
      }
    }
    
    ```
    
- **Evite `watch`:** Use observadores (`watch`) como último recurso. Muitas vezes, uma `computed property` ou um evento emitido pelo componente filho (`$emit`) é uma solução mais limpa e performática.
- **Lazy loading:** Sempre que possível usar lazy loading para a importação dos componentes:

```jsx
components: {
	ComponenteImportado: () => import('./caminho/para/o/Componente.vue')
},
```

- **Componentes na pasta components:** A pasta components é destinada APENAS a componentes Vue que estão sendo utilizados em ao menos dois locais não correlacionados no app.
- **Carregamento de Dados:** Ao usar v-if, priorize o carregamento de dados no hook created() ao invés de usar watchers.
- **`v-if` no componente pai:** Considere sempre colocar v-if no componente pai, pois quando utilizamos `v-if` na raiz do template, todo o componente (incluindo sua lógica JavaScript, computed properties, watchers, etc.) permanece instanciado em memória mesmo quando a condição é `false`.
- **Reset de Estado:** Encapsular reset de parâmetros padrão em um método resetDefaultParams e chamá-lo no beforeDestroy.
- **Usar const sempre que possível:** Sempre que uma constante for declarada, o ideal é usar `const` ao invés de `let`. Usar `let` apenas para variáveis que tenham seu valor alterado.
- **Propriedades adicionadas à store:** Verificar necessidade de adicionar novas propriedades em um módulo (ou na raiz) da store. Garantir que o que foi adicionado está sendo usado em algum lugar (regra válida tanto para state, quanto para os getters, mutations e actions).
- **Unicidade das propriedades da store:** Cada propriedade do state, getter, mutation e action deve desempenhar um papel único. Ter cuidado para que novas propriedades criadas não exerçam um papel que já é feito por outra existente.
- **Resolver causa raiz**: Ao codificar a solução de um problema, resolver sempre a causa raiz do mesmo ao invés de fazer workarounds.
- **Condições na função:** Evitar condições dentro da lógica que deveriam ser impossíveis de ocorrer, por exemplo, funções que recebem um argumento que nunca deveria ser null/undefined não deveria precisar checar se o mesmo tem esses valores.
- **Early returns na função pai:** Se dentro de uma cadeia de funções uma condição que causa um early return precisa ser checada, checá-la o quanto antes possível, de preferência na função pai, para evitar múltiplas checagens iguais em diferentes funções.
- **Keys de `v-for`:** Dentro de um `v-for`, é importante definir a `key` do elemento iterado. Para isso, procurar sempre usar algum id do elemento e evitar usar o index do array, para evitar problemas de renderização.
- **Usar funções utilitárias corretamente:** algumas funções utilitárias, como o debounce, tem um uso específico. Evitar usá-las para algum outro uso que não seja o pretendido originalmente. Se necessário, procurar outra função utilitária que sirva para o caso ou codificar uma nova.
- **Não reimplementar props:** Se um componente encapsula outro, não reimplementar as props do componente encapsulado. Ao invés disso, passar as props de um componente para outro usando `v-bind="$attrs"` .
- **Não chamar operações custosas repetidamente:** Evitar métodos com operações de baixa performance que sejam chamados constantemente. Exemplo: um método que faz operações no DOM sendo chamado a cada resize ou uma computada que faz cálculos custosos.

### Uso de Mixins no Vue 2

- **Evitar sempre que possível:** Mixins devem ser considerados apenas como último recurso.
- **Critério de aceite:** Só podem ser usados se o sistema depender de lifecycle hooks (`created`, `mounted`, etc.) que **não podem ser substituídos** por outras soluções.
- **Riscos conhecidos:** Mixins podem causar conflitos de nomes, dificultam rastreabilidade da lógica e tornam testes unitários mais complexos [Vue Docs]
- **Alternativas recomendadas:**
    - **Helpers (funções puras ou classes)** → para validações, formatações, cálculos.
    - **Services** → para lógica de negócio e integrações externas.
    - **Vuex** → para compartilhamento de estado entre componentes.
    - **High-order Components / composição via props e slots** → para lógica visual e reuso de comportamento.

---

## 3. Arquitetura e Reutilização

Diretrizes para manter o código organizado, modular e reutilizável.

- **Reutilize o Existente:** Antes de criar algo novo, verifique se já não existe um componente, função ou utilitário que resolva o problema.
    - **Componentes do Design System:** Nossos componentes base estão em `frontend/src/components/v1`. Utilize-os sempre que possível para evitar recriar lógicas já existentes.
    - **Demais componentes base:** Para componentes base que não estejam no design system (por exemplo: listas), verificar se não existe um componente pronto no vuetify. Caso exista, utilizar o mesmo se possível.
    - **Funções Globais:** Utilize nossas funções compartilhadas em `$utils` e `$helpers`
- **Modularização:** Mantenha os componentes pequenos e focados em uma única responsabilidade.
- **Localização do Código:** Verifique se uma nova função está no local apropriado. Ela pertence ao componente, a um `helper` global ou à `store` (Vuex)?
- **Organização de Pastas:** Mantenha a estrutura de pastas e arquivos consistente com o padrão já estabelecido no projeto.
    - **Organização de Subcomponentes:** Subcomponentes devem ser colocados dentro de uma pasta widgets.
    - **Nome do arquivo principal do componente:** O nome do arquivo principal de um componente dentro de uma pasta (ou seja, que representa o componente de mesmo nome da pasta) deve ser `index.vue`.
    - **Pasta de constantes:** os arquivos na pasta de constantes devem conter apenas constantes. Não incluir funções nos mesmos.
    - **Mocks:** mocks devem ser criados dentro da pasta `mocks` do projeto. Além disso, importante adicionar um comentário do tipo `// #TODO` lembrando de removê-los.
    - **Critérios para usar a pasta repositories/helpers/utils:**
        - Backend
            - Se a função possuir requisição para banco de dados usando mais de um Model (operação complexa): pasta repositories.
            - Se a função possuir requisição para banco de dados com apenas um Model que poderia ser um statics do Model: implementar a mesma na pasta Model.
            - Função sem requisição para banco de dados e lógica específica para uma feature: pasta feature/helper.
            - Função sem requisição para banco de dados e com lógica sem contexto específico: pasta utils.
- **Refatoração Contínua:** Se uma mudança for feita em um trecho de código que precisa ser refatorado (por razões de reusabilidade, modularidade, etc.), aplique a melhoria junto com a alteração.
- **Ordenação de Dados:** Priorizar ordenação via banco de dados (usando campos específicos como 'order') ao invés de implementar lógica de ordenação no frontend.
- **Métodos Utilitários:** Antes de criar um novo método utilitário em um componente, verificar se já não existe função similar em utils que possa ser reaproveitada.
- **Centralizar responsibilidade:** Sempre procurar centralizar as chamadas para uma função no menor número de lugares possíveis, ao invés de distribuir a responsabilidade para vários locais diferentes do código.
- **Componentes com múltiplas instâncias**: Atenção ao usar store e eventbus em componentes que podem ter múltiplas instâncias (ou cujos parents podem). Verificar quais variáveis devem ter efeito global e quais devem ter apenas efeito local (para aquele componente) a fim de evitar problemas inesperados.
- **Componentes ativados por botão**: Para componentes cuja ativação ocorre com o clique em um botão, procurar deixar o componente e o botão no mesmo arquivo, criando um slot activator.
- **Lógicas nas classes base:** Se há uma classe base da qual outras derivam, apenas colocar nela lógicas compartilhadas com todas as classes que herdam da mesma.
- **Erros mostrados ao usuário:** Para erros que devem aparecer para o usuário, utilizar a função showError. Nas mensagens para o usuário, a linguagem deve ser apropriada para o mesmo, sem usar termos técnicos que possam não ser compreendidos.
- **Early returns em eventos do editor:** Para mantermos a performance a longo prazo do editor tiny, devemos sempre pensar em otimizar os handles de eventos adicionados, adicionando “early returns” sempre que possível.
- **Chamadas para o backend:** As chamadas para o backend devem ser feitas usando a função `makeRequest` por dentro das actions da store apenas. Não fazer chamadas diretamente pelo componente.

---

## 4. Estilização (CSS/SCSS)

Critérios para garantir que os estilos sejam consistentes e não causem conflitos.

- **Estilos Escopados:** **Sempre** use `scoped` na tag `<style>` dos componentes para evitar que os estilos vazem e afetem outras partes da aplicação.
- **Evite `!important`:** O uso de `!important` é um forte indicativo de problemas de especificidade no CSS e deve ser evitado a todo custo.
- **Evite Estilos Inline:** Não aplique estilos diretamente no template (`style="..."`). Mantenha todo o CSS dentro da tag `<style>`.
    - A menos que seja para manipulação de css por javascript
        
        ```html
        :style="{ '--padding-top-custom-menu': paddingTop + 'px' }"
        ```
        
- **Use o Tema:** Para cores, utilize as variáveis definidas em nosso tema centralizado em `frontend/src/store/modules/themes/index.js` ou `shared/themes/index.js`.
- **Classes Condicionais:** Evite nomes de classes baseados em condições. Se for necessário, utilize classes fixas e aplique-as condicionalmente
- **Z-Index:** O ideal é usar o menor z-index possível ao invés de valores arbitrariamente grandes, para facilitar no posicionamento de outros componentes.
- **Seletores externos ao componente**: Seletores das regras devem referenciar classes presentes no mesmo componente sempre que possível. Se for necessário modificar uma regra para uma classe presente em outro componente, verificar se é possível colocar a regra no componente que contém a classe. Caso não seja, referenciar alguma classe do componente onde a regra foi colocada nos seletores da regra.
- **Seletores repetidos:** Juntar todas as regras de um seletor em um mesmo escopo. Não criar dois escopos de regras para um mesmo seletor em um mesmo componente.
- **Variáveis de cor:** Evitar cores hardcoded, procure sempre usar variáveis de cor. As variáveis de css que contém as cores devem ser configuradas no módulo de themes (dependendo da branch, na store do frontend ou no shared).
    - **Nomenclatura:** Os nomes das variáveis de cor devem indicar as cores usadas nos modos default e dark da aplicação. Por exemplo, se a variável se chama `-light-grey-8-dark-grey-3`, configurá-la assim:
        - no objeto do tema default:
            
            ```jsx
            '--light-grey-8-dark-grey-3': constants.colors['--app-grey-8']
            
            ```
            
        - no objeto do tema dark:
            
            ```jsx
            '--light-grey-8-dark-grey-3': constants.colors['--app-grey-3']
            
            ```
            
    - Evite uso de condicionais JavaScript para trocar cores (ex.: `darkMode ? ... : ...`). Em vez disso, use sempre um único token de cor do tema que já muda conforme o modo claro/escuro.
        - Padrão: use `:color="$css['<token-de-cor>']"`. Se o token não existir, crie-o no módulo de temas com mapeamento para default e dark.
        
        Exemplo:
        
        - Evitar: `:color="darkMode ? $css['--app-white'] : '#2E3333'"`
        - Preferir: `:color="$css['--light-grey-8-dark-grey-3']"` (com `--light-grey-8-dark-grey-3` definido em `@themes` para ambos os modos)

---

## 5. Nomenclatura e Convenções

Padrões para nomes de variáveis, funções, arquivos e textos.

- **Nomenclatura Clara:** Nomes de variáveis, funções, arquivos e componentes devem ser claros, objetivos e descrever seu propósito.
- **Classes e atributos:** nomes de classes e atributos que descrevem um elemento html (como, por exemplo, `aria-label`), devem sempre refletir o propósito do elemento ao qual fazem parte).
- **Idioma:**
    - **Funções e Variáveis:** Nomenclatura em **inglês**.
    - **Textos para o Usuário:** Todos os textos visíveis na interface (`<template>`, alertas, etc.) devem estar em **português**.
- **Evite Nomes Específicos:**
    - **Empresa:** Não use nomes como "Laudite" nas nomenclaturas.
    - **Bibliotecas:** Não use nomes de bibliotecas (ex: `axiosRequest`), pois elas podem ser substituídas no futuro.
- **Consistência na Store (Vuex):** Procure manter os mesmos nomes para `getters` e `mutations` que manipulam o mesmo estado.
- **Padrão de Métodos:** Métodos que manipulam eventos ou ações do usuário devem seguir o padrão de nomenclatura 'handleXXX'.

- **Padrão “close”:** Para métodos chamados durante o evento de `close` de um componente e/ou quando o mesmo é fechado / para fechar o mesmo, normalmente damos o nome de `onClose` ou `handleClose`.
- **Padrão da Store:** para usar a store no frontend, foram definidas algumas variáveis globais. Use-as sempre que possível:
    - Getters: `$getters['modulo/nomeDoGetter']` ou `$getters['nomeDoGetter']` se estiver na raiz da store
    - Mutation: `$mutations('modulo/nomeDaMutation', value)` ou `$mutations('nomeDaMutation', value)` se estiver na raiz da store
    - Action: `$actions('modulo/nomeDaAction', payload)` ou `$actions('nomeDaAction', payload)` se estiver na raiz da store
- **Padrão do Locale:** É importante que o caminho no locale (e, consequentemente, no argumento da função $t) descreva o contexto onde a string traduzida está presente (exemplo: `'views.userPreferences.copilot.clipboard.closeInNewReportLabel'`)
- **Padrões de ícones:** Nomes dos ícone deve estar em formato camelCase.
- **Eslint:** Sempre corrigir erros que vão de encontro às regras configuradas para o eslint em cada projeto
- **Internacionalização de textos:** Todos os textos que serão mostrados ao usuário deverão ser colocados na pasta locale e referenciados através da função `$t` da biblioteca do i18n para vue, independente se estão presentes no template ou no script.

---

## 6. Limpeza e Qualidade do Código

Práticas para manter o código limpo e de fácil manutenção.

- **Remova `console.log`:** Nenhum `console.log` ou `debugger` deve ser enviado para produção.
- **Comentários desnecessários:** Evitar comentário desnecessário e, se a lógica necessitar de um comentário, tentar colocá-lo em inglês
- **Código Morto:** Remova código comentado. O histórico de alterações já existe no Git.
- **`TODO`s:** Evite subir comentários de `TODO` não resolvidos. Se necessário, crie uma task para o débito técnico.
- **Constantes para Strings:** Se uma string se repete em vários lugares (ex: tipos de ação, chaves), armazene-a em um arquivo de constantes para evitar inconsistências e erros de digitação.
- **Estruturas Condicionais:** Use `switch case` em vez de múltiplos `if/else if` quando uma variável puder assumir três ou mais valores diferentes.
- **Exceções às Regras:** Se uma correção exige uma solução que foge a estes padrões, marque-a com um comentário explicativo: `// #FIX: [Explicação do motivo]`.
- **Código duplicado:** Evitar duplicação de código (uma dica nesses casos é usar um arquivo ou função que abrigue o código em comum, e todos os lugares que tiverem código duplicado chamarem o mesmo).
- **Números mágicos:** Evitar números mágicos no código. Se um número tem significado específico (ex: timeout de 5000ms, limite de 10 itens), armazene-o em uma constante com nome descritivo para melhor legibilidade e manutenibilidade.
- **Nome de eventos:** Caso seja necessário criar um evento (seja via `eventListener`, `eventBus`, etc), é importante que o seu nome não tenha referencia a quem consome o evento, mas sim seja sobre a regra de negocio do evento.
- **Componentes utilizados em diferentes contextos:** Se um componente é utilizado em diferentes contextos, as regras de negócio que se diferenciam em cada caso devem ser passadas por props ou slots, para que o código do componente não precise se preocupar com as regras de cada caso, o que o tornaria menos limpo e mais difícil de manter
- **Comentar funções complexas:** Quando o código não for autoexplicativo, adicionar comentários no código para facilitar leitura
- **Arquivos não utilizados:** Remover arquivos que foram adicionados mas não estão sendo utilizados em nenhum lugar do projeto.
- **Estrutura de pastas desnecessária:** Evitar criar novas estruturas de pastas no projeto sem necessidade real. Manter a organização simples e consistente com o padrão já estabelecido.

---

## 7. Gerenciamento de Memória e Ciclo de Vida

Cuidados para evitar vazamentos de memória (memory leaks).

- **Listeners de Eventos:** Sempre remova os listeners de eventos no hook `beforeDestroy` (ou `unmounted` em Vue 3) para evitar que continuem ativos após o componente ser destruído.
    
    ```jsx
    mounted() {
      document.addEventListener('click', this.handleOutsideClick)
    },
    beforeDestroy() {
      document.removeEventListener('click', this.handleOutsideClick)
    },
    
    ```
    
- **Timers (`setInterval` e `setTimeout`):** Sempre limpe os timers usando `clearInterval` ou `clearTimeout` no hook `beforeDestroy`.
    
    ```jsx
    mounted() {
      this.intervalId = setInterval(this.minhaFuncao, 1000)
    },
    beforeDestroy() {
      clearInterval(this.intervalId)
    },
    
    ```
    
- **EventBus**: Sempre limpe os eventos de eventBus usando `$off` no hook `beforeDestroy`.
    
    ```jsx
    mounted() {
      this.$eventBus.$on('event', callback)
    },
    beforeDestroy() {
      this.$eventBus.$off('event')
    },
    
    ```
    
- **Recursos a Evitar (salvo necessidade extrema):**
    - `watch`
    - `setInterval` / `setTimeout`
    - `jQuery` (não deve ser usado)
- **Componentes em Memória:** Evitar manter componentes desnecessariamente em memória durante todo o uso do app. Utilizar v-if ao invés de v-show quando o componente não precisar ser frequentemente alternado.

---

## 8. Processo e Colaboração

Ações que envolvem o time e o processo de desenvolvimento.

- **Justificativa para Novas Bibliotecas:** Se uma nova biblioteca for adicionada, a Pull Request deve conter uma justificativa clara do motivo da sua utilização.
- **Validação com QA:** Solicite testes da equipe de QA para todas as partes críticas do código que foram modificadas.
- **Remoção de código existente:** Caso seja removido código existente, verificar importância da lógica removida e efeitos colaterais.
- **Conformidade com o Design:** Verifique se a implementação está de acordo com o que foi prototipado no Figma.
- **Padrão de Ícones:** A adição de novos ícones SVG deve seguir rigorosamente o processo documentado:
    1. Adicionar o arquivo `.svg` em `frontend\src\assets\svgIcons\v1\svgs`.
    2. Criar o componente `.vue` correspondente em `frontend\src\assets\svgIcons\v1\vue`.
    3. Importar e registrar o novo componente de ícone no arquivo `frontend\src\components\Icons\icons.js`.
    4. Utilizar o ícone exclusivamente através do componente `<icons name="..." />`.
- **Remover MDs:** remover todos mds relacionados a algum plano de execução da implementação da task/feature

<!-- OFFICIAL_NOTION_SNAPSHOT_END -->
