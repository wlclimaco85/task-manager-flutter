---
phase: 02-code-review-card-282
reviewed: 2026-08-06T15:30:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - lib/windows/screens/pedido_venda_grid_screen.dart
  - lib/web/screens/pedido_venda_grid_screen.dart
findings:
  critical: 3
  warning: 4
  info: 2
  total: 9
status: issues_found
---

# Phase 02: Code Review Report — Card 282 Pedido Venda (Windows + Web)

**Reviewed:** 2026-08-06 15:30 UTC  
**Depth:** standard  
**Files Reviewed:** 2  
**Status:** ⚠️ **BLOCKER** — Critical and Warning issues found; must fix before QA

---

## Summary

Reviewed implementation of Pedido Venda Grid screens for Windows and Web platforms. Code exhibits **3 critical issues** related to exception handling, null safety, and state synchronization. Additionally, **4 warnings** flag code quality and maintainability concerns.

**Critical Issues:**
1. Unhandled `firstWhere()` exceptions in web implementation (crash risk)
2. Missing `mounted` check in async context (potential setState after dispose)
3. Bare exception clauses exposing stack traces to user (security/UX issue)

**Warnings:**
1. State synchronization bug in filter (client-side state drift)
2. Code duplication in action handlers
3. Silent exception swallowing
4. Stack trace exposure in error messages

**Verdict:** **DO NOT APPROVE FOR QA** — Apply all Critical and Warning fixes before merge.

---

## Critical Issues

### CR-01: Unhandled `firstWhere()` Exception in Web Grid Actions

**File:** `lib/web/screens/pedido_venda_grid_screen.dart:346, 349, 353, 357, 365, 369`

**Issue:**  
Calls to `_pedidos.firstWhere((o) => o['id'] == id)` in `_buildActions()` method lack exception handling. If an item is not found in the list, `firstWhere()` throws a `StateError`, crashing the app. This can occur if:
- List was modified between action click and execution
- ID passed doesn't match any item in cache
- Race condition with data refresh

**Affected lines:**
```dart
346: _openForm(_pedidos.firstWhere((o) => o['id'] == id))
349: _openForm(_pedidos.firstWhere((o) => o['id'] == id))
353: _openForm(_pedidos.firstWhere((o) => o['id'] == id))
357: _openForm(_pedidos.firstWhere((o) => o['id'] == id))
365: _openForm(_pedidos.firstWhere((o) => o['id'] == id))
369: _openForm(_pedidos.firstWhere((o) => o['id'] == id))
```

**Fix:**
Replace all `firstWhere()` calls with safe variant using `firstWhereOrNull` (requires `package:collection`) or wrap in try/catch:

```dart
// Option 1: Using firstWhereOrNull (preferred)
import 'package:collection/collection.dart';

Widget _buildActions(int? id, String status, List<PedidoVendaHistorico> historico, Map<String, dynamic> pedido) {
  if (id == null) return const SizedBox.shrink();
  return Row(mainAxisSize: MainAxisSize.min, children: [
    _actionIcon(Icons.visibility, 'Visualizar', GridColors.info, () {
      final pedidoItem = _pedidos.firstWhereOrNull((o) => o['id'] == id);
      if (pedidoItem != null) _openForm(pedidoItem);
    }),
    // ... rest of actions
  ]);
}

// Option 2: Using try/catch (simpler, no extra dependency)
_actionIcon(Icons.visibility, 'Visualizar', GridColors.info, () {
  try {
    final pedidoItem = _pedidos.firstWhere((o) => o['id'] == id);
    _openForm(pedidoItem);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Pedido não encontrado. Recarregando...'),
        backgroundColor: GridColors.warning,
      ),
    );
    _load();
  }
}),
```

---

### CR-02: Missing `mounted` Check Before Async Callback in Success Path

**File:** `lib/web/screens/pedido_venda_grid_screen.dart:156`

**Issue:**  
In `_confirmAction()` method, line 156 calls `_load()` without checking `mounted` flag. While line 151 checks `if (!mounted) return;`, the subsequent `if (success) _load();` on line 156 is outside this guard. If the widget is disposed between the async action completion and this line, `_load()` will call `setState()` on a disposed widget.

```dart
// Current code (UNSAFE)
try {
  final success = await action();
  if (!mounted) return;  // Guard
  ScaffoldMessenger.of(context).showSnackBar(...);
  if (success) _load();  // No mounted check here — potential crash
}
```

**Fix:**
```dart
try {
  final success = await action();
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(...);
  if (mounted && success) _load();  // Add mounted check
}
```

---

### CR-03: Bare Exception Clause with Stack Trace Exposure

**File:** `lib/windows/screens/pedido_venda_grid_screen.dart:125`  
**File:** `lib/web/screens/pedido_venda_grid_screen.dart:128, 161`

**Issue:**  
Exception objects are converted directly to strings in SnackBar messages, exposing full stack traces to users. This is a security and UX concern.

Windows (line 125):
```dart
ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  content: Text(GridTexts.actionFailure('$title: $e')),  // Full exception printed
  backgroundColor: GridColors.error,
));
```

Web (line 128):
```dart
catch (_) {}  // Bare except silently ignores all exceptions
// Later use exception without type checking
```

Web (line 161):
```dart
catch (e) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('Erro ao $title: $e'),  // Exception stack trace exposed
    backgroundColor: GridColors.error,
  ));
}
```

**Fix:**

**Windows and Web — Line 125 & 161:**
```dart
catch (e) {
  if (!mounted) return;
  // Log for debugging (use logger if available)
  // logger.error('Action failed: $title', error: e);
  
  // User-friendly message only
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(GridTexts.actionFailure(title)),  // No stack trace
    backgroundColor: GridColors.error,
  ));
}
```

**Web — Line 128:**
```dart
catch (e) {
  // Handle specific error types or log for debugging
  // logger.error('Failed to fetch orçamentos', error: e);
  
  // Never silently swallow exceptions in network calls
}
```

---

## Warnings

### WR-01: State Synchronization Bug — `_clienteFilter` Updated Without setState

**File:** `lib/web/screens/pedido_venda_grid_screen.dart:251`

**Issue:**  
The `_clienteFilter` local variable is updated directly in the `onChanged` callback without calling `setState()`. This causes the internal state to drift from what the user sees:

```dart
TextField(
  controller: _clienteCtrl,
  decoration: ...,
  onChanged: (v) => _clienteFilter = v,  // Direct assignment, no setState
),
```

After the user types, `_clienteFilter` is updated, but if they click "Filtrar" without this variable being synced to the button click handler, the filter may use stale data. The current implementation gets it right because `_load()` uses `_clienteFilter` directly, but this is fragile and violates Flutter's unidirectional data flow principle.

**Fix:**
```dart
TextField(
  controller: _clienteCtrl,
  decoration: ...,
  onChanged: (v) => setState(() => _clienteFilter = v),  // Call setState
),
```

Or, alternatively, read from the controller directly in `_load()` instead of maintaining a separate variable:
```dart
Future<void> _load() async {
  setState(() => _isLoading = true);
  final data = await PedidoVendaService.fetchAll(
    status: _statusFilter != 'Todos' ? _statusFilter : null,
    cliente: _clienteCtrl.text.isNotEmpty ? _clienteCtrl.text : null,  // Use controller
    dataInicio: _dataInicio?.toIso8601String().substring(0, 10),
    dataFim: _dataFim?.toIso8601String().substring(0, 10),
  );
  if (mounted) setState(() { _pedidos = data; _isLoading = false; });
}
```

---

### WR-02: Code Duplication — "Faturar Total" Action Defined Twice

**File:** `lib/web/screens/pedido_venda_grid_screen.dart:365, 369`

**Issue:**  
The "Faturar Total" action appears twice in `_buildActions()` with identical implementation, differing only in the condition:

```dart
// Line 363-366: For status 'APROVADO'
GatedButton(
  enabled: status == 'APROVADO',
  child: _actionIcon(Icons.done_all, 'Faturar Total', Colors.blue, 
    () => _confirmAction('Faturar Total', 'Deseja faturar totalmente este pedido?', 
      () => PedidoVendaService.faturarTotal(id))),
),

// Line 367-370: For status 'FATURADO_PARCIAL'
GatedButton(
  enabled: status == 'FATURADO_PARCIAL',
  child: _actionIcon(Icons.done_all, 'Faturar Total', Colors.blue, 
    () => _confirmAction('Faturar Total', 'Deseja faturar totalmente este pedido?', 
      () => PedidoVendaService.faturarTotal(id))),
),
```

This violates DRY principle and makes maintenance harder (e.g., if the label or confirmation message needs to change, must be updated in two places).

**Fix:**
```dart
// Consolidate into single button with combined condition
GatedButton(
  enabled: status == 'APROVADO' || status == 'FATURADO_PARCIAL',
  child: _actionIcon(Icons.done_all, 'Faturar Total', Colors.blue, 
    () => _confirmAction('Faturar Total', 'Deseja faturar totalmente este pedido?', 
      () => PedidoVendaService.faturarTotal(id))),
),
```

---

### WR-03: Bare Exception Clause Silently Swallows Errors

**File:** `lib/web/screens/pedido_venda_grid_screen.dart:128`

**Issue:**  
The `_fetchOrcamentosAprovados()` method catches all exceptions silently and returns an empty list:

```dart
Future<List<Map<String, dynamic>>> _fetchOrcamentosAprovados() async {
  try {
    // ... network call
  } catch (_) {}  // Bare except, no logging or error handling
  return [];
}
```

This masks errors and makes debugging difficult. Network failures are silently treated the same as "no orçamentos found," providing no feedback to the user or developer.

**Fix:**
```dart
Future<List<Map<String, dynamic>>> _fetchOrcamentosAprovados() async {
  try {
    final response = await NetworkCaller().getRequest('${ApiLinks.orcamentos}?status=APROVADO');
    if (response.isSuccess && response.body != null) {
      final data = response.body!['data']?['dados'] ?? response.body!['data'] ?? [];
      if (data is List) return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
  } catch (e) {
    // Log error for debugging (use logger if available)
    // logger.error('Failed to fetch orçamentos aprovados', error: e);
    
    // Optionally show error to user via ScaffoldMessenger
    // if (mounted) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: const Text('Erro ao carregar orçamentos'), backgroundColor: GridColors.error),
    //   );
    // }
  }
  return [];
}
```

---

### WR-04: Windows — Exception Stack Trace Exposed in Error Message

**File:** `lib/windows/screens/pedido_venda_grid_screen.dart:125`

**Issue:**  
Same as CR-03 but less critical here because it's in a catch block of `_showConfirm()`. However, the pattern is still problematic.

**Fix:** (Same as CR-03 recommendation)

---

## Info

### IN-01: Import Inconsistency — `GridColors` Location

**File:**  
- `lib/windows/screens/pedido_venda_grid_screen.dart:5` — imports from `utils/grid_colors.dart`
- `lib/web/screens/pedido_venda_grid_screen.dart:6` — imports from `constants/custom_colors.dart`

**Issue:**  
Both files use `GridColors`, but they import from different modules:

- Windows: `import '../../../utils/grid_colors.dart';`
- Web: `import '../../../constants/custom_colors.dart';`

While both modules define `GridColors` class, this inconsistency creates confusion and maintenance burden. The canonical source should be `utils/grid_colors.dart` (which has more complete color definitions). The `constants/custom_colors.dart` appears to be a legacy wrapper with duplicate definitions.

**Fix:**  
Update web file to use canonical import:
```dart
// Old
import '../../../constants/custom_colors.dart';

// New
import '../../../utils/grid_colors.dart';
```

Verify that `constants/custom_colors.dart` is not used elsewhere, and consider removing it as part of a refactor if it's truly redundant.

---

### IN-02: Magic Status Strings — No Constants

**File:**  
- `lib/windows/screens/pedido_venda_grid_screen.dart:25, 36, 47, 53`
- `lib/web/screens/pedido_venda_grid_screen.dart:30, 72, 167-174`

**Issue:**  
Status values ('RASCUNHO', 'APROVADO', 'REJEITADO', 'FATURADO_PARCIAL', 'FATURADO_TOTAL', 'CANCELADO') are hardcoded strings throughout both files. This is a code smell that makes refactoring difficult if status values need to change.

**Fix:**  
Create a constants file or add to existing constants:

```dart
// lib/constants/pedido_venda_status.dart
class PedidoVendaStatus {
  static const String rascunho = 'RASCUNHO';
  static const String aprovado = 'APROVADO';
  static const String rejeitado = 'REJEITADO';
  static const String faturadoParcial = 'FATURADO_PARCIAL';
  static const String faturadoTotal = 'FATURADO_TOTAL';
  static const String cancelado = 'CANCELADO';
}
```

Then use:
```dart
isVisible: (item) => item.id != null && item.status == PedidoVendaStatus.rascunho,
```

---

## Replication Status

**Web screen not yet replicated to `task_manager_flutter_merged_final`.** When replicating, ensure:

1. Apply all fixes from Critical and Warning sections
2. Update imports to use canonical `grid_colors.dart`
3. Test both platforms with same exception handling patterns
4. Verify GridColors constants are consistent across platforms

---

## Checklist Before QA

- [ ] **CR-01**: Add try/catch or use `firstWhereOrNull` for all `firstWhere()` calls in web implementation
- [ ] **CR-02**: Add `mounted` check before `_load()` in line 156
- [ ] **CR-03**: Remove stack traces from user-facing error messages; log exceptions separately
- [ ] **WR-01**: Call `setState()` when updating `_clienteFilter`
- [ ] **WR-02**: Consolidate duplicate "Faturar Total" button
- [ ] **WR-03**: Add proper error handling to `_fetchOrcamentosAprovados()` instead of bare except
- [ ] **WR-04**: Apply same stack trace fix to Windows implementation
- [ ] **IN-01**: Align imports — use canonical `utils/grid_colors.dart` in web
- [ ] **IN-02**: Extract status strings to constants file
- [ ] Run `flutter analyze` — should pass with no warnings
- [ ] Test all action buttons (approve, reject, faturar, cancel, histórico)
- [ ] Verify no setState-after-dispose warnings in console during rapid navigation

---

_Reviewed: 2026-08-06 15:30 UTC_  
_Reviewer: Claude (gsd-code-reviewer)_  
_Depth: standard_
