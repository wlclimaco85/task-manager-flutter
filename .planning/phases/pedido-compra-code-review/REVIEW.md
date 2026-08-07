---
commit: a71f05f2 (remediação de 25e5aaec)
branch: card-6a3e8cb5-pedido-compra-padrao
reviewed: 2026-08-07T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - lib/windows/screens/pedido_compra_grid_screen.dart
  - lib/customization/dynamic_grid_windows_screen.dart
  - lib/windows/dialogs/pedido_compra_form_dialog.dart
  - lib/utils/grid_texts.dart
  - lib/windows/screens/bottom_navbar_screen.dart
  - lib/widgets/dashboard_area/drill_down_router.dart
findings:
  critical: 1
  warning: 4
  info: 2
  total: 7
status: issues_found
---

# Code Review: commit a71f05f2 (card 6a3e8cb5 — Pedido de Compra padrão) — Rodada 2

**Reviewed:** 2026-08-07
**Depth:** standard
**Status:** issues_found (rodada anterior sobre `25e5aaec`: reprovado)

## Rodada 1 (commit 25e5aaec) — resumo

Achados originais: CR-01 (exclusão indevida em qualquer status), CR-02 (edição genérica fora de RASCUNHO), WR-01 (grid não recarrega após ação), WR-02 (Histórico escondido quando vazio), WR-03 (RBAC `hasPermission` sempre `true`), IN-01/IN-02. Veredito: **Reprovado**.

## Rodada 2 (commit a71f05f2) — o que foi verificado

Revalidei cada remediação lendo o diff completo (`git show a71f05f2`) e os arquivos afetados por inteiro, não apenas a descrição do autor.

### CR-01 (exclusão indevida) — ✅ Corrigido
`buttonPermissions` foi corretamente propagado como parâmetro opcional de `DynamicGridWindowsScreen` até `GenericGridScreen`, com fallback para o default anterior quando omitido (`dynamic_grid_windows_screen.dart:532-539` — confirmei que o fallback reproduz exatamente o default hardcoded que existia antes em `generic_grid_windows_screen.dart:1715-1721`, então nenhuma outra tela que não passe o parâmetro é afetada). `pedido_compra_grid_screen.dart:49-55` passa `delete: false, deleteMultiple: false`. Confirmado: `flutter analyze` nos 3 arquivos tocados = 0 issues.

### CR-02 (edição fora de RASCUNHO) — ✅ Corrigido, com um bug novo introduzido (ver CR-03 abaixo)
`edit: false` remove o botão genérico; `CustomAction` "Editar" com `isVisible: (item) => item.id != null && item.status == 'RASCUNHO'` reproduz exatamente a regra antiga. `PedidoCompraFormDialog` é reaproveitado corretamente (`item: pedido.toJson()` bate com o `Map<String, dynamic>?` esperado pelo dialog). Porém a forma como o retorno do dialog é tratado introduz um bug de navegação — ver **CR-03**.

### WR-02 (Histórico escondido quando vazio) — ✅ Corrigido
`isVisible: (item) => item.id != null` — sempre visível, igual ao comportamento anterior. Confirmado que `PedidoCompraHistoricoDialog` já trata lista vazia (linha 24-27 do dialog, não alterada).

### WR-01 (grid não recarrega após ação) — ✅ Corrigido funcionalmente, novo WARNING sobre o custo do approach (ver WR-04)

## Critical Issues

### CR-03 (NOVO): Double-pop de navegação após "Editar" (RASCUNHO) e "Receber Parcial" — pode fechar a tela errada

**File:** `lib/windows/screens/pedido_compra_grid_screen.dart:128-139` (`_openEdit`, **novo** nesta rodada) e `:141-172` (`_showReceberParcial`, **já existia desde `25e5aaec` e eu não peguei isso na rodada 1 — falha minha, registrando aqui**)

**Issue:** Tanto `PedidoCompraFormDialog._save()` (`lib/windows/dialogs/pedido_compra_form_dialog.dart:231-233`) quanto `ReceberDialog._confirmar()` (`lib/windows/dialogs/receber_dialog.dart:66-68`) já chamam `Navigator.pop(context)` internamente para fechar a si mesmos **antes** de invocar `widget.onSaved()`. Mas os dois callbacks `onSaved` em `pedido_compra_grid_screen.dart` chamam `Navigator.pop(context)` **de novo**, usando o `context` capturado do item da grid (não o `context` local do dialog):

```dart
// _openEdit — NOVO nesta rodada
onSaved: () {
  Navigator.pop(context);   // <- dialog já fechou sozinho; isso fecha a PRÓXIMA rota do topo
  _reload();
},

// _showReceberParcial — já existia desde 25e5aaec
onSaved: () {
  Navigator.pop(context);   // <- mesmo problema
  ScaffoldMessenger.of(context).showSnackBar(...);
  _reload();
},
```

Como `Navigator.of(context).pop()` sempre remove a rota que estiver no topo da pilha no momento da chamada (independentemente de qual `BuildContext` válido for usado para localizar o Navigator), o segundo `pop()` não fecha "mais uma vez o dialog" — ele fecha a **rota seguinte**, que hoje é o shell principal (`WindowsBottomNavBarScreen`, já que os pedidos de compra vivem dentro de um `IndexedStack` de abas, não como rota própria — confirmei em `bottom_navbar_screen.dart:970`). Na estrutura de navegação atual isso tende a ser um no-op inofensivo (se o shell for a única rota da pilha, `pop()` simplesmente não faz nada). Mas é código objetivamente incorreto e frágil: (a) inconsistente com `_showConfirm`, que não tem esse problema porque não fecha nenhum dialog próprio antes de retornar; (b) se esta tela algum dia for aberta via rota empurrada (`Navigator.push`) — por exemplo, se `WindowsPedidoCompraGridScreen` for adicionada ao `drill_down_router.dart` no mesmo padrão já usado para `WindowsPedidoVendaGridScreen` — o segundo `pop()` fecharia a própria tela de Pedido de Compra logo após o usuário editar um RASCUNHO ou receber parcialmente um pedido, imediatamente após a ação ter sucesso. É o mesmo padrão problemático que já existe em `pedido_venda_grid_screen.dart:_showFaturarDialog` (não introduzido por este commit, mas replicado aqui).

**Fix:** Remover o `Navigator.pop(context)` redundante nos dois callbacks `onSaved` — o dialog já se fecha sozinho:
```dart
void _openEdit(BuildContext context, PedidoCompra pedido) {
  showDialog(
    context: context,
    builder: (_) => PedidoCompraFormDialog(
      item: pedido.toJson(),
      onSaved: _reload, // dialog já fecha a si mesmo em _save()
    ),
  );
}
```
```dart
onSaved: () {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(GridTexts.completedAction(GridTexts.receivePartial)),
      backgroundColor: GridColors.success,
    ),
  );
  _reload();
},
```
Recomendo corrigir antes do merge, mesmo com o risco prático baixo na navegação atual (IndexedStack/shell único) — é barato de corrigir e remove uma armadilha real para quem for adicionar uma rota de drill-down para Pedido de Compra no futuro (o card irmão de Pedido de Venda já tem esse drill-down).

## Warnings

### WR-04 (NOVO): Reload via remount completo (`key: ValueKey`) descarta filtros, paginação e ordenação da grid após toda ação de negócio

**File:** `lib/windows/screens/pedido_compra_grid_screen.dart:35-44`

**Issue:** A correção do WR-01 troca a chave (`ValueKey(_reloadToken)`) do `DynamicGridWindowsScreen` filho a cada ação bem-sucedida, forçando o Flutter a destruir e recriar todo o subtree — incluindo `_DynamicGridWindowsScreenState`, que reinicia `_telaFuture = _loadTela()` (refetch completo da configuração de tela, com até 5 tentativas e backoff, não apenas um refetch dos dados) e recria o `GenericGridScreen` do zero. Isso funciona para atualizar o status exibido (resolve o WR-01 original), mas tem dois efeitos colaterais que a versão antiga (`_load()` reaproveitando o mesmo estado do widget) não tinha: (1) qualquer filtro/busca/ordenação/página aplicada pelo usuário na grid genérica é perdida a cada Emitir/Aprovar/Cancelar/Receber/Editar bem-sucedido, porque o estado interno do `GenericGridScreen` (que guarda filtros, página atual, ordenação) é descartado junto com o widget; (2) refaz a busca da configuração de tela (`getTelaFromCache`) a cada ação, não só o fetch de dados — desnecessário, já que a tela não mudou.

**Fix:** Se o objetivo é só re-buscar os dados (não a config de tela), seria melhor expor um método de reload real em `GenericGridScreen`/`DynamicGridWindowsScreen` (ex.: via `GlobalKey<GenericGridScreenState>` chamando `_loadItems` diretamente, ou um `ValueNotifier` de "reload trigger" observado internamente sem remount) em vez de forçar remount total via `key`. Não bloqueante — é uma correção de UX/eficiência, o dado errado (WR-01 original) já não aparece mais — mas vale registrar como fast-follow, especialmente porque filtro/paginação resetados a cada ação é perceptível ao usuário em telas com muitos pedidos.

### WR-03 (mantido da rodada 1, não tratado): RBAC `hasPermission` sempre `true`

Sem mudanças. Classificado como dívida técnica sistêmica na rodada 1; mantenho a mesma classificação — não bloqueia esta entrega.

### WR-05: Fixação não testada da remediação (ausência de teste automatizado cobrindo CR-01/CR-02/CR-03)

**File:** `lib/windows/screens/pedido_compra_grid_screen.dart`

**Issue:** Nenhum teste widget foi adicionado cobrindo: (a) que "Excluir"/"Editar genérico" não aparecem mais no menu de ações para nenhum status; (b) que "Editar" (CustomAction) só aparece em RASCUNHO; (c) o comportamento de navegação após salvar via `_openEdit`/`_showReceberParcial` (que teria pego o CR-03 antes de chegar ao code review). Dado que o projeto lista TDD como prática recomendada para "regras de negócio, bugs reproduzíveis e funções isoladas" (CLAUDE.md), a ausência de cobertura aqui é uma lacuna, principalmente porque `buttonPermissions` é uma peça de segurança/integridade de dado (CR-01/CR-02), não só UX.

**Fix:** Adicionar ao menos um teste de widget instanciando `WindowsPedidoCompraGridScreen` (ou testando `DynamicGridWindowsScreen` com `buttonPermissions` customizado) que verifique a ausência de "Excluir"/"Editar" genéricos e a presença condicional da `CustomAction` "Editar" por status. Não bloqueante para este ciclo dado o tempo já investido, mas recomendo antes de fechar o card.

## Info

### IN-01/IN-02 (mantidos da rodada 1)

Sem mudanças — duplicação de `_showConfirm` entre telas e `try/catch` redundante sobre services que já tratam erro internamente. Seguem como sugestões não bloqueantes.

## Verdict

**Aprovado com ressalvas.**

CR-01 e CR-02 da rodada 1 foram corrigidos corretamente e de forma verificável (li o diff completo, não apenas a descrição). WR-02 foi revertido corretamente. WR-01 foi resolvido funcionalmente, ainda que com uma abordagem mais custosa que o ideal (WR-04).

Encontrei um bug novo durante a revalidação (**CR-03**, double-pop de navegação), que também expôs uma instância idêntica já existente desde a rodada 1 em `_showReceberParcial` que eu não tinha identificado antes — registro isso explicitamente como uma lacuna da minha própria revisão anterior, não como algo introduzido só agora. O risco prático de CR-03 é baixo na estrutura de navegação atual (tela vive dentro de `IndexedStack`, não como rota própria — o `pop()` extra tende a ser um no-op), mas é código incorreto, barato de corrigir, e vira um problema real no dia em que Pedido de Compra ganhar uma rota de drill-down (como Pedido de Venda já tem).

Recomendação: corrigir CR-03 antes de mover para QA (fix é de poucas linhas, baixo risco de regressão, e evita um comportamento surpreendente para o usuário caso a navegação da tela mude no futuro). WR-04 e WR-05 podem ser tratados como fast-follow sem bloquear o card, desde que registrados no Trello.

---

_Reviewed: 2026-08-07_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
