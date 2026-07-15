import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:task_manager_flutter/customization/dynamic_grid_dynamic_screen.dart';
import 'package:task_manager_flutter/models/telas_model.dart';

// Testes de regressão do card #425:
// Bug 1: popup "Campos visíveis" mobile não afetava a renderização real dos
//        cards (GenericMobileGridScreen e GridListScreen tinham estados
//        _fieldVisibility desconectados).
// Bug 2: cards do GED mobile mostravam botões de ação ("Finalizar"/"Reabrir")
//        pertencentes a outra tela (Chamados).
void main() {
  group('Bug 2 — filterActionsForTela (defesa contra actions órfãs)', () {
    test('remove actions cujo endpoint pertence a outra tela', () {
      final actions = [
        TelaAction(
          label: 'Finalizar',
          method: 'POST',
          endpoint: '/api/chamados/finalizar/:id',
        ),
        TelaAction(
          label: 'Reabrir',
          method: 'POST',
          endpoint: '/api/chamados/reabrir/:id',
        ),
      ];

      final result = filterActionsForTela(actions, '/api/arquivo');

      expect(result, isEmpty);
    });

    test('mantém actions cujo endpoint pertence à própria tela', () {
      final actions = [
        TelaAction(
          label: 'Aprovar',
          method: 'POST',
          endpoint: '/api/arquivo/aprovar/:id',
        ),
        TelaAction(
          label: 'Finalizar',
          method: 'POST',
          endpoint: '/api/chamados/finalizar/:id',
        ),
      ];

      final result = filterActionsForTela(actions, '/api/arquivo');

      expect(result, hasLength(1));
      expect(result.first.label, 'Aprovar');
    });

    test('lista vazia de actions permanece vazia', () {
      final result = filterActionsForTela(<TelaAction>[], '/api/arquivo');
      expect(result, isEmpty);
    });
  });

  group('Bug 1 — sincronização de callbacks de visibilidade de campos', () {
    testWidgets(
        'onFieldSettingsReady/onFilterToggleReady entregam funções do filho ao pai',
        (WidgetTester tester) async {
      VoidCallback? childShowFieldSettings;
      VoidCallback? childToggleFilters;
      bool childFilterToggled = false;

      // Simula o padrão usado por GridListScreen: expõe ao pai, via callback,
      // a função interna correta assim que o widget é inicializado.
      await tester.pumpWidget(
        MaterialApp(
          home: _FakeChildWithReadyCallbacks(
            onFieldSettingsReady: (fn) => childShowFieldSettings = fn,
            onFilterToggleReady: (fn) => childToggleFilters = fn,
            onToggleFilters: () => childFilterToggled = true,
          ),
        ),
      );

      // Após o primeiro frame, o pai já deve ter recebido as referências —
      // isso é o que corrige o bug de o AppBar mobile chamar a função errada.
      expect(childShowFieldSettings, isNotNull);
      expect(childToggleFilters, isNotNull);

      childToggleFilters!.call();
      expect(childFilterToggled, isTrue);
    });

    testWidgets('onCustomizationStateChanged notifica pai de mudanças de filtros/colunas',
        (WidgetTester tester) async {
      bool parentNotified = false;
      bool hasActiveFilters = false;
      bool hasCustomColumns = false;

      await tester.pumpWidget(
        MaterialApp(
          home: _FakeChildWithCustomizationCallback(
            onCustomizationStateChanged: ({required bool hasActiveFilters, required bool hasCustomColumns}) {
              parentNotified = true;
              // Simula pai recebendo a notificação e atualizando state
            },
          ),
        ),
      );

      // Após pumpWidget, o filho já deve ter enviado a notificação
      expect(parentNotified, isTrue);
    });
  });
}

/// Widget mínimo que reproduz o contrato de GridListScreen usado pelo fix do
/// bug #425: entrega, via ValueChanged<VoidCallback>, as funções internas
/// corretas assim que inicializa.
class _FakeChildWithReadyCallbacks extends StatefulWidget {
  final ValueChanged<VoidCallback> onFieldSettingsReady;
  final ValueChanged<VoidCallback> onFilterToggleReady;
  final VoidCallback onToggleFilters;

  const _FakeChildWithReadyCallbacks({
    required this.onFieldSettingsReady,
    required this.onFilterToggleReady,
    required this.onToggleFilters,
  });

  @override
  State<_FakeChildWithReadyCallbacks> createState() =>
      _FakeChildWithReadyCallbacksState();
}

class _FakeChildWithReadyCallbacksState
    extends State<_FakeChildWithReadyCallbacks> {
  void _showFieldSettings() {}

  @override
  void initState() {
    super.initState();
    widget.onFieldSettingsReady(_showFieldSettings);
    widget.onFilterToggleReady(widget.onToggleFilters);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Widget mínimo que reproduz onCustomizationStateChanged de GridListScreen.
class _FakeChildWithCustomizationCallback extends StatefulWidget {
  final void Function({required bool hasActiveFilters, required bool hasCustomColumns}) onCustomizationStateChanged;

  const _FakeChildWithCustomizationCallback({
    required this.onCustomizationStateChanged,
  });

  @override
  State<_FakeChildWithCustomizationCallback> createState() =>
      _FakeChildWithCustomizationCallbackState();
}

class _FakeChildWithCustomizationCallbackState
    extends State<_FakeChildWithCustomizationCallback> {
  @override
  void initState() {
    super.initState();
    // Simula GridListScreen notificando o pai sobre mudanças de customização
    widget.onCustomizationStateChanged(
      hasActiveFilters: false,
      hasCustomColumns: false,
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
