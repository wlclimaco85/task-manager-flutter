---
phase: card-6f94hyxf-nfse-layout-v3
reviewed: 2026-08-10T00:00:00Z
depth: deep
files_reviewed: 7
files_reviewed_list:
  - lib/windows/screens/details/nfse_detail_screen.dart
  - lib/web/screens/details/nfse_detail_screen.dart
  - lib/widgets/searchable_dropdown.dart
  - lib/utils/grid_colors.dart
  - test/widgets/nfse_detail_layout_test.dart
  - test/windows/screens/details/nfse_detail_screen_test.dart
  - test/web/screens/details/nfse_detail_screen_test.dart
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
status: issues_found
---

# Code Review: commit 5521d39d — Card 6F94hyxf (NFSe layout v3)

**Reviewed:** 2026-08-10
**Depth:** deep (leitura completa dos 4 arquivos de produção + 3 arquivos de teste, diff linha a linha contra `origin/desenv`, `dart analyze` e `flutter test` executados)
**Files Reviewed:** 7
**Status:** issues_found (nenhum bloqueador; 2 avisos, 3 sugestões)

## Resumo

Revisei o commit `5521d39d` (`task_manager_flutter`, branch `card-6f94hyxf-nfse-layout-v3`) contra `origin/desenv`. Rodei `dart analyze` nos 4 arquivos de produção (0 issues) e `flutter test` nos 3 arquivos de teste tocados (16/16 passando). Também rodei a suíte completa — há falhas pré-existentes e não relacionadas (`test/models/nfe_models_test.dart` tem um erro de sintaxe de `$` não escapado numa string, `test/integration/nfe_repository_integration_test.dart` etc.), confirmado como não tocado por este commit e fora de escopo.

**Achado principal (positivo):** o bug de memory leak/corrupção de dados (CR-01/CR-02) está genuinamente corrigido. Comparei o código antigo (`origin/desenv`) com o novo: o método antigo `_iInp(String label, Map item, String key)` de fato criava `final ctrl = TextEditingController(text: item[key]?.toString() ?? '');` a cada chamada de `build()`, sem cache por item e sem `dispose()` — confirmando a causa raiz descrita no commit. O novo `_NfseItemFormFields` (StatefulWidget próprio, `Key` estável por item, controllers criados uma única vez em `initState`, sincronizados em `didUpdateWidget`, liberados em `dispose`) resolve o problema corretamente. Também não há caminho, dentro do código revisado, em que um rebuild do pai sem troca de `Key` force recriação de controllers — `didUpdateWidget` só atualiza texto, nunca recria o `Map<String, TextEditingController>`.

O overlay inline (`_openInlineOverlay`/`_InlineSearchPopover`) também gerencia corretamente o ciclo de vida do `OverlayEntry`: fecha o anterior antes de abrir um novo, remove no `dispose()` do `_SearchableDropdownFieldState` (evitando vazamento quando o campo sai da árvore com o popover aberto), e cancela o `Timer` de debounce e o `FocusNode` no `dispose()` do popover. O caminho `Dialog` (usado pelas demais telas do app) não foi alterado — apenas envolvido por um `CompositedTransformTarget`/`LayerLink`, que é um no-op para quem não usa `inline: true`. Confirmado via `grep` que nenhuma outra tela passa `inline: true`.

Nenhum campo do formulário antigo desapareceu na reorganização em 6 cards (comparação campo a campo feita entre `origin/desenv` e o novo arquivo). Backend/migrations não foram tocados — o commit é 100% Flutter, como esperado para este card.

## Warnings

### WR-01: Teste "Selecionar produto... atualiza os campos sem recriar o controller" não testa o que o título afirma

**File:** `test/windows/screens/details/nfse_detail_screen_test.dart:105-132`
**Issue:** O teste se chama "Selecionar produto no formulário do item atualiza os campos sem recriar o controller", mas o corpo do teste nunca seleciona um produto — não há produtos carregados no ambiente de teste (sem backend), então o teste apenas digita texto diretamente no campo "Descrição" e verifica que nenhuma exceção é lançada. A asserção real não cobre o caminho que o título promete verificar: a sincronização de `_controllers[campo].text` a partir de `item[campo]` feita em `didUpdateWidget`, disparada quando `_ddObjItem`'s `onChanged` (em `_NfseItemFormFieldsState`) muta `item['descricao']`, `item['valorUnitario']`, `item['aliquotaIss']` e `item['codigoTributacaoMunicipal']` via `setState()` local e depois chama `widget.onProdutoSelecionado(item)` — que por sua vez dispara um `setState(() {})` no *pai* (`_NfseDetailScreenState`).

Esse é exatamente o tipo de problema que o próprio commit diz ter corrigido em outro teste ("O teste antigo tinha título enganoso... corrigido para refletir o comportamento inline real") — aqui o padrão se repete: o título promete uma cobertura que a asserção não entrega. A lógica de sincronização em si parece corretamente implementada (o pai é ancestral do `_NfseItemFormFields` na árvore de widgets, e o Flutter garante que elementos ancestrais são reconstruídos antes dos descendentes dentro do mesmo frame — então `didUpdateWidget` sempre roda com o mapa já mutado antes de qualquer uso do texto desatualizado), mas essa garantia depende inteiramente de `widget.onProdutoSelecionado` ser sempre chamado após a mutação do item. Se esse callback for removido ou alterado num refactor futuro, os campos de texto (`_controllers`) ficarão sincronizados apenas até a próxima interação do usuário que force o pai a reconstruir — um regressão silenciosa, sem teste que a pegue.
**Fix:** Reescrever o teste para de fato injetar uma lista de produtos (ex: passar `item: {...}` com um item que já tenha um `produto` associado, ou refatorar `_NfseItemFormFieldsState`/`_produtos` para permitir injeção via construtor em teste de widget isolado) e then abrir o dropdown "Produto (Serviço)", selecionar uma opção, e então afirmar `find.widgetWithText(TextFormField, 'Descrição')` (ou o `controller.text`) reflete o valor do produto selecionado — como já é feito corretamente no teste de regressão CR-01/CR-02 em `nfse_detail_layout_test.dart`.

### WR-02: Overlays inline concorrentes não se fecham entre si de forma explícita

**File:** `lib/widgets/searchable_dropdown.dart:215-257`
**Issue:** Cada `SearchableDropdownField` com `inline: true` mantém seu próprio `_overlayEntry` isolado no seu próprio `State`. Não existe nenhum registro global/coordenação entre instâncias — se o usuário abrir o popover do campo "Série" e, sem fechá-lo, tocar diretamente no campo "Município de Prestação" (ambos visíveis simultaneamente na tela, já que não há mais `Dialog` bloqueando o resto do formulário), o fechamento do primeiro popover depende inteiramente de o `GestureDetector` translúcido (`Positioned.fill` inserido por cima de toda a tela) conseguir interceptar o mesmo toque que abre o segundo campo. Isso funciona hoje porque `HitTestBehavior.translucent` permite que o toque seja processado tanto pelo barrier quanto pelo `InkWell` do campo abaixo dele — mas é um comportamento implícito da árvore de hit-testing, não uma garantia arquitetural. Qualquer widget interposto entre o barrier e o campo-alvo que use hit-testing opaco (ex: um futuro `AbsorbPointer`, `Material` com `InkResponse` customizado, ou um novo overlay de outro tipo) quebraria esse acoplamento silenciosamente, deixando dois popovers abertos ao mesmo tempo.
**Fix:** Centralizar o controle de "qual overlay inline está aberto" fora do State individual — por exemplo, um `ValueNotifier<_SearchableDropdownFieldState?>` estático/injetado via `InheritedWidget`, ou simplesmente fazer `_openInlineOverlay()` fechar explicitamente qualquer outro overlay conhecido antes de abrir o seu (um registro estático simples de `OverlayEntry` "ativo" por `Overlay` seria suficiente). Isso remove a dependência de comportamento incidental de hit-test.

## Info

### IN-01: `lib/web/.../nfse_detail_screen.dart` e `lib/windows/.../nfse_detail_screen.dart` são idênticos byte a byte

**File:** `lib/web/screens/details/nfse_detail_screen.dart`, `lib/windows/screens/details/nfse_detail_screen.dart`
**Issue:** Os dois arquivos de 1273 linhas são cópias exatas um do outro (mesmo nome de classe `NfseDetailScreen`, mesmo corpo completo). Esse padrão de duplicação total já existia no código anterior a este commit (não foi introduzido agora — a versão web antiga tinha um layout diferente, mas a estrutura de duplicação windows/web já era a norma no projeto), então não é uma regressão deste commit, mas o commit dobra o tamanho da duplicação (883 + 621 linhas de diff) sem extrair a lógica compartilhada. Qualquer bug futuro corrigido em um arquivo (ex: os dois warnings acima) exige lembrar de replicar manualmente no outro.
**Fix:** Fora do escopo deste card, mas vale considerar extrair `_NfseDetailScreenState`/`_NfseItemFormFields` para um widget compartilhado parametrizado por diferenças de plataforma (se houver), reduzindo a superfície de duplicação em revisões futuras.

### IN-02: `_empresas` list nunca é populada (dropdown "Empresa" sempre vazio quando não há sessão)

**File:** `lib/windows/screens/details/nfse_detail_screen.dart:59, 562-563` (idêntico no web)
**Issue:** `final List<Map<String, dynamic>> _empresas = [];` nunca recebe dados — não há chamada a `_loadList` para preenchê-la em `_loadDropdowns()`. Quando `hasSession` é `false` ou `_empresaNome` é `null`, o card "Cliente / Tomador" renderiza `_ddObj('Empresa', _empresaId, _empresas, ...)` com uma lista sempre vazia, tornando o dropdown de Empresa inutilizável nesse cenário. Confirmado que esse comportamento já existia identicamente em `origin/desenv` — não é uma regressão deste commit, mas passou despercebido nas duas reescritas anteriores do card também.
**Fix:** Fora do escopo direto deste commit, mas registrar como débito técnico — carregar `_empresas` via `/api/empresa` em `_loadDropdowns()`, análogo ao que já é feito para `_tomadores`/`_series`/`_cidades`.

### IN-03: Falhas de chamadas de API são engolidas silenciosamente sem feedback ao usuário

**File:** `lib/windows/screens/details/nfse_detail_screen.dart:252-277` (`_loadList`), idêntico no web
**Issue:** `catch (_) {}` em `_loadList` (usado para carregar tomadores, séries, cidades e produtos) faz com que qualquer falha de rede/servidor deixe os dropdowns correspondentes silenciosamente vazios, sem `SnackBar` ou indicação visual de erro — diferente do padrão usado em `_salvarCabecalho`/`_salvarItem`, que mostram erro ao usuário. Padrão pré-existente, não introduzido por este commit.
**Fix:** Fora do escopo deste commit; considerar padronizar tratamento de erro de carregamento de dropdowns com feedback visual (ex: mensagem "Não foi possível carregar X") em uma iteração futura.

---

## Veredito

**Aprovado com ressalvas.**

A correção do memory leak/corrupção de dados (CR-01/CR-02) está tecnicamente correta e validada por testes que realmente exercitam o cenário de regressão (criar item 1, editar, criar item 2, navegar entre eles sem misturar valores — `nfse_detail_layout_test.dart:170-241`). O overlay inline não vaza `OverlayEntry`/`Timer`/`FocusNode` e não usa `context` após unmount nos caminhos analisados. `dart analyze` limpo, testes dos arquivos tocados passam 16/16, nenhum campo do formulário anterior foi perdido, e o backend não foi tocado (consistente com o escopo do card).

As ressalvas (WR-01, WR-02) não são bloqueadoras — não encontrei um caminho comprovado que efetivamente quebre em produção — mas WR-01 é relevante porque repete, num novo teste, o mesmo padrão de "título de teste que não testa o que promete" que já causou duas reprovações anteriores deste card no QA. Recomendo corrigir WR-01 antes de mover para QA novamente, para não repetir o histórico do card.
