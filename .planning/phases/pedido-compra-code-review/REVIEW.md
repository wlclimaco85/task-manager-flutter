---
commit: 8a4b16eb (remediação de a71f05f2, que remediou 25e5aaec)
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
  critical: 0
  warning: 2
  info: 2
  total: 4
status: clean
---

# Code Review: commit 8a4b16eb (card 6a3e8cb5 — Pedido de Compra padrão) — Rodada 3

**Reviewed:** 2026-08-07
**Depth:** standard
**Status:** clean (sem críticos abertos)

## Histórico

- **Rodada 1** (`25e5aaec`): CR-01 (exclusão indevida em qualquer status), CR-02 (edição genérica fora de RASCUNHO), WR-01 (grid não recarrega após ação), WR-02 (Histórico escondido quando vazio), WR-03 (RBAC `hasPermission` sempre `true`), IN-01/IN-02. Veredito: **Reprovado**.
- **Rodada 2** (`a71f05f2`): CR-01, CR-02 e WR-02 confirmados corrigidos; WR-01 corrigido funcionalmente (com ressalva de custo, WR-04). Achado novo **CR-03** (double-pop de navegação em `_openEdit`/`_showReceberParcial` — instância em `_showReceberParcial` já existia desde a rodada 1 e não tinha sido identificada por mim até então). Veredito: **Aprovado com ressalvas** (CR-03 recomendado antes de QA).
- **Rodada 3** (`8a4b16eb`, esta): CR-03 corrigido.

## Rodada 3 — o que foi verificado

Li o diff completo (`git show 8a4b16eb`) e o arquivo `pedido_compra_grid_screen.dart` por inteiro após a mudança, não apenas a descrição do commit.

### CR-03 (double-pop de navegação) — ✅ Corrigido

Os dois `Navigator.pop(context)` redundantes foram removidos:

```dart
void _openEdit(BuildContext context, PedidoCompra pedido) {
  showDialog(
    context: context,
    builder: (_) => PedidoCompraFormDialog(
      item: pedido.toJson(),
      onSaved: () {
        _reload();
      },
    ),
  );
}
```

```dart
onSaved: () {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(GridTexts.completedAction(GridTexts.receivePartial)),
      backgroundColor: GridColors.success,
    ),
  );
  _reload();
},
```

Confirmado: `PedidoCompraFormDialog._save()` e `ReceberDialog._confirmar()` continuam responsáveis por fechar o próprio dialog (`Navigator.pop(context)` interno, não tocado) antes de invocar `onSaved`; o callback do lado da grid agora só reage ao sucesso (snackbar + `_reload()`), sem tentar fechar nada. `flutter analyze lib/windows/screens/pedido_compra_grid_screen.dart` = 0 issues.

Nota menor (não bloqueante, não vira item novo de severidade): o `onSaved` de `_showReceberParcial` usa `ScaffoldMessenger.of(context)` sem checar `context.mounted` antes — na prática o widget pai (`WindowsPedidoCompraGridScreen`) dificilmente é desmontado nesse meio-tempo (tela vive num `IndexedStack`, não é removida durante a chamada), então o risco de exception é teoricamente baixo, mas seria mais defensivo adicionar o guard `if (!context.mounted) return;` no início do callback, no mesmo padrão já usado em `_showConfirm` (linha 204 do mesmo arquivo).

## Critical Issues

Nenhum item crítico aberto nesta rodada.

## Warnings

### WR-04 (mantido da rodada 2, não tratado): Reload via remount completo (`key: ValueKey`) descarta filtros, paginação e ordenação da grid após toda ação de negócio

**File:** `lib/windows/screens/pedido_compra_grid_screen.dart:35-44`

**Issue:** A correção do WR-01 troca a chave (`ValueKey(_reloadToken)`) do `DynamicGridWindowsScreen` filho a cada ação bem-sucedida, forçando destruição/recriação de todo o subtree — incluindo `_DynamicGridWindowsScreenState`, que reinicia `_telaFuture = _loadTela()` (refetch completo da configuração de tela, com até 5 tentativas e backoff) e recria o `GenericGridScreen` do zero. Efeitos colaterais frente ao antigo `_load()`: (1) filtro/busca/ordenação/página aplicados pelo usuário são perdidos a cada Emitir/Aprovar/Cancelar/Receber/Editar bem-sucedido; (2) refaz a busca da configuração de tela a cada ação, não só o fetch de dados.

**Fix:** Sugerido na rodada 2 — expor um método de reload real (`GlobalKey`/`ValueNotifier`) em vez de remount total via `key`. Não bloqueante.

### WR-05 (mantido da rodada 2, não tratado): Ausência de teste automatizado cobrindo `buttonPermissions`/`CustomAction` por status

**File:** `lib/windows/screens/pedido_compra_grid_screen.dart`

**Issue:** Nenhum teste widget cobre a ausência de "Excluir"/"Editar" genéricos nem a visibilidade condicional da `CustomAction` "Editar" por status. Como `buttonPermissions` aqui é uma peça de integridade de dado (CR-01/CR-02 da rodada 1), não só UX, a falta de cobertura é uma lacuna que vale registrar.

**Fix:** Adicionar ao menos um teste de widget verificando a ausência dos botões genéricos e a presença condicional de "Editar" por status. Não bloqueante para este ciclo.

### WR-03 (mantido da rodada 1, não tratado): RBAC `hasPermission` sempre `true`

Sem mudanças. Classificado como dívida técnica sistêmica desde a rodada 1 (mesmo padrão em `pedido_venda_grid_screen.dart`, `conta_bancaria_grid_screen.dart` etc.) — não bloqueia esta entrega.

## Info

### IN-01/IN-02 (mantidos da rodada 1)

Sem mudanças — duplicação de `_showConfirm` entre telas e `try/catch` redundante sobre services que já tratam erro internamente. Sugestões não bloqueantes.

## Verdict

**Aprovado.**

Os dois achados críticos originais (CR-01 exclusão indevida, CR-02 edição fora de RASCUNHO) e o achado crítico levantado na rodada 2 (CR-03 double-pop de navegação) estão corrigidos e verificados por leitura direta do código e diff, não apenas por `flutter analyze` ou pela descrição do autor. Nenhum item bloqueante permanece aberto.

Itens não bloqueantes que seguem em aberto e recomendo registrar no Trello como fast-follow (não impedem mover o card para QA): WR-03 (RBAC `hasPermission` sempre `true` — dívida técnica sistêmica, não exclusiva deste card), WR-04 (reload por remount completo descarta filtros/paginação da grid a cada ação), WR-05 (falta de teste automatizado cobrindo as regras de `buttonPermissions`/`CustomAction` por status), IN-01 (duplicação de `_showConfirm` entre telas) e IN-02 (`try/catch` redundante na UI sobre services que já tratam erro internamente).

---

_Reviewed: 2026-08-07_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
