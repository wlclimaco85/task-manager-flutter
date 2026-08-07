---
commit: 25e5aaec
branch: card-6a3e8cb5-pedido-compra-padrao
reviewed: 2026-08-07T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - lib/windows/screens/pedido_compra_grid_screen.dart
  - lib/utils/grid_texts.dart
  - lib/windows/screens/bottom_navbar_screen.dart
  - lib/widgets/dashboard_area/drill_down_router.dart
findings:
  critical: 2
  warning: 3
  info: 2
  total: 7
status: issues_found
---

# Code Review: commit 25e5aaec (card 6a3e8cb5 — Pedido de Compra padrão)

**Reviewed:** 2026-08-07
**Depth:** standard (leitura completa dos 4 arquivos alterados + arquivos chamados: `pedido_compra_service.dart`, `receber_dialog.dart`, `pedido_compra_historico_dialog.dart`, `pedido_compra_model.dart`, `dynamic_grid_windows_screen.dart`, `generic_grid_windows_screen.dart`, comparação com `pedido_venda_grid_screen.dart` e com a versão anterior do arquivo em `fb16b64f`)
**Status:** issues_found

## Summary

A migração de `WindowsPedidoCompraGridScreen` para `DynamicGridWindowsScreen<PedidoCompra>` está bem executada no que diz respeito às `CustomAction` de negócio: a visibilidade por status (Emitir/Aprovar/Receber Parcial/Receber Total/Cancelar/Histórico) reproduz fielmente a versão anterior, e as assinaturas de `PedidoCompraService`, `ReceberDialog` e `PedidoCompraHistoricoDialog` batem exatamente com o que o novo arquivo espera — confirmado por leitura direta do código, não apenas pela análise estática.

Porém, adotar o widget genérico `DynamicGridWindowsScreen`/`GenericGridScreen` introduz duas capacidades que **não existiam** na tela anterior e que não foram mencionadas no card nem no commit: um botão genérico "Editar" disponível para pedidos em **qualquer status** (antes só RASCUNHO podia ser editado) e um botão genérico "Excluir" (exclusão definitiva) disponível para **qualquer pedido, em qualquer status**, algo que a tela anterior simplesmente não oferecia. Combinado com `hasPermission: (perm) => true` (linha adicionada em `bottom_navbar_screen.dart`), isso significa que qualquer usuário que acesse esta tela Windows pode editar ou apagar definitivamente um pedido de compra já aprovado/recebido, contornando toda a máquina de estados (Emitir → Aprovar → Receber → Cancelar) que o restante da tela tenta preservar. Isso é tratado como BLOCKER porque afeta integridade de um documento financeiro/fiscal (pedido de compra), não é coberto pelos critérios de aceite do card, e é silencioso — não há teste, warning de UI ou log que avise sobre o risco.

Adicionalmente, as `CustomAction` de negócio (Emitir/Aprovar/Cancelar/Receber Total/Receber Parcial) não disparam nenhum recarregamento da grid após sucesso — diferente do código antigo, que chamava `_load()` após cada ação bem-sucedida. O usuário só vê o status atualizado após um refresh manual.

Nota: o padrão `hasPermission: (perm) => true` e a ausência de recarregamento pós-ação já existem hoje em `pedido_venda_grid_screen.dart` (aprovado anteriormente) — não são inéditos deste commit, mas o commit os estende para Pedido de Compra sem qualquer ressalva, e o risco de exclusão indevida é particularmente sensível em compras (documento com efeito financeiro/estoque).

Os itens de `grid_texts.dart`, `bottom_navbar_screen.dart` e a correção pré-existente em `drill_down_router.dart` estão corretos e conferidos linha a linha.

## Critical Issues

### CR-01: Exclusão definitiva (hard delete) de pedidos de compra em qualquer status, sem essa opção existir antes

**File:** `lib/windows/screens/pedido_compra_grid_screen.dart` (todo o arquivo, por herdar de `DynamicGridWindowsScreen`) + `lib/widgets/generic_grid_windows_screen.dart:4488-4497,3094-3127` + `lib/windows/screens/bottom_navbar_screen.dart:426`

**Issue:** A tela antiga (`fb16b64f:lib/windows/screens/pedido_compra_grid_screen.dart`) não tinha NENHUM botão de exclusão — só Visualizar/Editar(RASCUNHO)/Emitir/Aprovar/Cancelar/Receber/Histórico. Ao migrar para `GenericGridScreen`, o menu de ações passa a incluir "Excluir" sempre que `hasPermission('delete') && buttonPermissions['delete']` (linha 4488). `buttonPermissions` não é passado por `DynamicGridWindowsScreen` nem por `WindowsPedidoCompraGridScreen`, então usa o default `{'delete': true, ...}` (generic_grid_windows_screen.dart:1715-1721). E `hasPermission` chega hardcoded como `(perm) => true` a partir de `bottom_navbar_screen.dart:426`. Resultado: **qualquer usuário** que abra a tela de Pedidos de Compra pelo menu lateral Windows pode clicar em "Excluir" em um pedido `APROVADO`, `RECEBIDO_PARCIAL` ou `RECEBIDO_TOTAL` e apagá-lo permanentemente (`_deleteItem` dispara `DELETE` direto no endpoint configurado pela tela, sem checagem de status — `generic_grid_windows_screen.dart:3094-3127`). Isso ignora toda a máquina de estados que as `CustomAction` tentam preservar e pode causar perda de dado fiscal/financeiro sem qualquer trilha de auditoria além do que o backend registrar no DELETE.

**Fix:** Desabilitar o botão de exclusão genérico para esta tela (ela nunca teve essa opção) e, se exclusão de RASCUNHO for desejada no futuro, tratá-la como uma `CustomAction` própria com checagem de status, igual às demais:
```dart
return DynamicGridWindowsScreen<PedidoCompra>(
  telaNome: 'pedido_compra',
  hasPermission: hasPermission,
  buttonPermissions: const {
    'create': true,
    'edit': false,   // ver CR-02 — edição deve ser feita via CustomAction restrita a RASCUNHO
    'delete': false, // pedido de compra nunca teve exclusão direta nesta tela
    'deleteMultiple': false,
    'export': true,
  },
  ...
);
```
(Confirmar se `DynamicGridWindowsScreen`/`GenericGridScreen` já expõe `buttonPermissions` como parâmetro passável — hoje `DynamicGridWindowsScreen` não repassa esse campo do widget pai para `GenericGridScreen`, então também será necessário adicionar esse plumbing, ou resolver via `hasPermission` retornando `false` para `'delete'`/`'edit'` especificamente nesta tela em vez de `(perm) => true` genérico.)

### CR-02: Edição genérica liberada para pedidos em qualquer status (antes só RASCUNHO podia ser editado)

**File:** `lib/windows/screens/pedido_compra_grid_screen.dart` (todo o arquivo) + `lib/widgets/generic_grid_windows_screen.dart:4470-4478,3015`

**Issue:** No código antigo, o botão "Editar" só aparecia quando `status == 'RASCUNHO'` (`_buildActions`, linha `if (status == 'RASCUNHO') [...editar...]`). No `GenericGridScreen`, o item de menu "Editar" só depende de `hasPermission('edit') && buttonPermissions['edit']` — não há nenhuma checagem de `item.status` (linha 4470). Com `hasPermission: (perm) => true`, um pedido `EMITIDO`, `APROVADO` ou `RECEBIDO_PARCIAL/TOTAL` pode ser aberto no formulário genérico e ter seus campos (fornecedor, itens, valores, centro de custo) alterados livremente, o que corrompe o histórico/consistência entre o que foi aprovado/recebido e o que está salvo, sem passar pelo fluxo de "nova versão"/histórico que `PedidoCompraHistoricoDialog` sugere existir no backend.

**Fix:** Restringir "Editar" a RASCUNHO. Duas abordagens possíveis: (a) usar `buttonPermissions: {'edit': false}` e implementar edição de RASCUNHO como `CustomAction` própria (mesmo padrão de Emitir/Aprovar), ou (b) se o componente genérico suportar, condicionar a visibilidade do botão "Editar" por item — hoje ele não suporta isso (é global por tela), então a opção (a) é a mais segura dado o estado atual do componente compartilhado.

## Warnings

### WR-01: Grid não recarrega automaticamente após Emitir/Aprovar/Cancelar/Receber Total/Receber Parcial

**File:** `lib/windows/screens/pedido_compra_grid_screen.dart:118-164` (`_showConfirm`) e linhas do bloco `_showReceberParcial`

**Issue:** O código antigo chamava `_load()` após toda ação de negócio bem-sucedida (`if (success) _load();` em `_confirmAction`, e `onSaved: _load` no `ReceberDialog`). O novo `_showConfirm` só exibe um `SnackBar` de sucesso/erro e não dispara nenhum recarregamento da grid; o mesmo vale para o callback `onSaved` passado a `ReceberDialog` (só fecha o diálogo e mostra snackbar). Como o `GenericGridScreen` não observa automaticamente o retorno de uma `CustomAction` para decidir se deve recarregar (`generic_grid_windows_screen.dart:4562-4567` só chama `action.onPressed`, sem `_loadItems` depois), o usuário continua vendo o status antigo (e, portanto, as ações antigas — ex.: "Emitir" ainda visível depois de emitido) até clicar manualmente no botão de refresh da toolbar. Isso pode levar a cliques duplicados na mesma ação (ex.: tentar "Emitir" duas vezes) achando que a primeira não funcionou.

**Fix:** Expor um callback de reload que a `CustomAction` possa chamar após sucesso. Se `GenericGridScreen` não expõe isso hoje, uma alternativa mais simples é usar uma `GlobalKey<State<GenericGridScreen<PedidoCompra>>>`/callback passado via `onAfterSave`-like hook, ou (mínimo) instruir o usuário via snackbar a atualizar, mas o ideal é reintroduzir o reload automático equivalente ao antigo `_load()`.

### WR-02: `isVisible` do Histórico mudou de "sempre visível" para "só quando não vazio" sem registro dessa mudança de comportamento

**File:** `lib/windows/screens/pedido_compra_grid_screen.dart` (CustomAction "Histórico": `isVisible: (item) => item.historico != null && item.historico!.isNotEmpty`)

**Issue:** No código antigo, o ícone de "Histórico" sempre aparecia (`_actionIcon(Icons.history, 'Histórico', ..., () => _showHistorico(historico))`), abrindo um diálogo que já tratava o caso de lista vazia (`PedidoCompraHistoricoDialog` tem branch `if (historico.isEmpty) ... 'Nenhum histórico disponível'`). O novo código esconde a ação inteira quando `historico` é nulo/vazio. Isso não é necessariamente errado (evita clique inútil), mas contradiz a afirmação de que a paridade de comportamento com a versão anterior foi total — é uma mudança de UX não documentada. Além disso, se a API de listagem (`fetchAll`) não retornar o campo `historico` populado no payload de lista (comum em APIs que só populam nested collections no fetch por ID), a ação "Histórico" pode nunca aparecer mesmo quando existe histórico real, silenciosamente escondendo uma funcionalidade que antes sempre estava acessível.

**Fix:** Confirmar com o backend se `GET /api/compras/pedidos` (listagem) inclui `historico` por item. Se não incluir, ou trocar a condição de visibilidade para sempre mostrar a ação (deixando o diálogo tratar lista vazia, como fazia antes), ou buscar o histórico sob demanda ao clicar.

### WR-03: `hasPermission: (perm) => true` desabilita RBAC nesta tela

**File:** `lib/windows/screens/bottom_navbar_screen.dart:426`, `lib/widgets/dashboard_area/drill_down_router.dart:117,119` (padrão idêntico já usado para Pedido de Venda)

**Issue:** Isso não é uma regressão exclusiva deste commit (o mesmo padrão já existe hoje para `WindowsPedidoVendaGridScreen`, `WindowsContaBancariaGridScreen` etc.), mas ao estendê-lo para Pedido de Compra o commit propaga o mesmo problema: nenhuma verificação real de permissão de usuário é feita para criar/editar/excluir/exportar pedidos de compra — todo usuário autenticado tem acesso total pela tela Windows. Combinado com CR-01/CR-02, o impacto é maior aqui do que em telas de leitura pura.

**Fix:** Fora do escopo estrito deste card (é uma dívida técnica sistêmica), mas vale registrar como item de backlog: substituir `(perm) => true` por uma checagem real de permissão do usuário logado (ex.: via `TenantContext`/claims de role), pelo menos para os módulos financeiros/fiscais mais sensíveis (Pedido de Compra, Pedido de Venda, Contas).

## Info

### IN-01: Duplicação de padrão `_showConfirm`/`_showReceberParcial` entre `pedido_compra_grid_screen.dart` e `pedido_venda_grid_screen.dart`

**File:** `lib/windows/screens/pedido_compra_grid_screen.dart:86-164`, comparar com `lib/windows/screens/pedido_venda_grid_screen.dart:147-224`

**Issue:** Os métodos `_showConfirm` (diálogo de confirmação genérico com snackbar de sucesso/erro) são praticamente idênticos entre os dois arquivos (mesma lógica, mesmos estilos). Isso é duplicação de código que provavelmente já existia antes desta migração (mesmo padrão em `conta_bancaria_grid_screen.dart` possivelmente), então não é introduzido por este commit especificamente, mas a oportunidade de extrair um helper compartilhado (ex.: `GridActionHelpers.showConfirm(context, title, message, action)`) fica mais evidente agora que dois arquivos praticamente idênticos coexistem.

**Fix:** Considerar extrair `_showConfirm` para um mixin/helper compartilhado em `lib/widgets/` reutilizável por todas as telas Windows baseadas em `DynamicGridWindowsScreen` com `CustomAction`. Sugestão de melhoria, não bloqueante.

### IN-02: `try/catch` em `_showConfirm`/`_showReceberParcial` é código defensivo mas provavelmente morto

**File:** `lib/windows/screens/pedido_compra_grid_screen.dart:146-163,89-115`

**Issue:** Todos os métodos de `PedidoCompraService` (`emitir`, `aprovar`, `cancelar`, `receberTotal`, `receberParcial`) já capturam suas próprias exceções internamente e retornam `false` em caso de erro (`lib/services/pedido_compra_service.dart` — todo método tem `try { ... } catch (_) { return false; }`). Isso significa que os blocos `try/catch` em `_showConfirm` e `_showReceberParcial` no arquivo revisado nunca deveriam, na prática, capturar uma exceção vinda de `action()` — é redundância defensiva. Não é um bug, mas indica que o tratamento de erro está duplicado em duas camadas (service e UI) sem um contrato claro de "quem lança o quê".

**Fix:** Nenhuma ação obrigatória. Se quiser simplificar, considerar padronizar: services nunca lançam (sempre retornam bool/null) e a UI trata só o `success == false`, removendo o `try/catch` supérfluo — ou o inverso, deixando os services propagarem exceções e a UI ser a única camada de tratamento. Mistura hoje é aceitável, mas vale nota para consistência futura.

## Verdict

**Reprovado.**

Os dois achados críticos (CR-01 exclusão definitiva de pedidos de compra em qualquer status, CR-02 edição liberada para pedidos fora de RASCUNHO) representam uma mudança de comportamento não intencional e não coberta pelos critérios de aceite do card ("preservar a mesma visibilidade por status das ações de negócio" foi cumprido só para as `CustomAction`, não para as ações genéricas Editar/Excluir que vieram "de brinde" ao adotar `DynamicGridWindowsScreen`). Isso é um risco real de perda/corrupção de dado em um documento financeiro (pedido de compra aprovado/recebido), não apenas uma questão de UX.

Recomendação: resolver CR-01 e CR-02 antes de mover o card para QA — no mínimo desabilitando `buttonPermissions['delete']` e restringindo `edit` a RASCUNHO (ou implementando "Editar" como `CustomAction` visível só para RASCUNHO, retirando a dependência do botão genérico). WR-01 (falta de reload pós-ação) deveria idealmente ser corrigido também, pois afeta diretamente a percepção de sucesso da ação pelo usuário, mas não bloqueia por si só — pode ser tratado como fast-follow se houver pressão de prazo, desde que documentado.

---

_Reviewed: 2026-08-07_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
