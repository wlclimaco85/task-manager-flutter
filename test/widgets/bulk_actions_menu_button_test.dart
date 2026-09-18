import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/generic_grid_windows_screen.dart';

/// Testa o dropdown "Ações em massa" (BulkAction + buildBulkActionsMenuButton)
/// isoladamente, sem montar o GenericGridScreen inteiro (que dispara
/// requisição de rede em _loadItems). Cobre:
/// 1. Botão desabilitado sem seleção / habilitado com seleção (pedido
///    explícito do usuário no card de dropdown de ações em massa NFS-e/NF-e).
/// 2. Resumo de erro parcial (N sucesso, M falha) — mesmo formato usado pelas
///    ações reais de nfse_screen.dart/nfe_grid_screen.dart.
void main() {
  Future<void> pumpButton(
    WidgetTester tester, {
    required int selectedCount,
    required List<String> selectedItems,
    required List<BulkAction<String>> actions,
    required void Function(BulkAction<String>) onSelected,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildBulkActionsMenuButton<String>(
            actions: actions,
            selectedCount: selectedCount,
            selectedItems: selectedItems,
            onSelected: onSelected,
          ),
        ),
      ),
    );
  }

  group('buildBulkActionsMenuButton - habilitação pelo total selecionado', () {
    testWidgets('sem seleção: botão "Ações" fica desabilitado (opaco)',
        (tester) async {
      await pumpButton(
        tester,
        selectedCount: 0,
        selectedItems: const [],
        actions: [
          BulkAction<String>(
            icon: Icons.picture_as_pdf,
            label: 'Gerar PDF',
            onPressed: (_, __) async {},
          ),
        ],
        onSelected: (_) {},
      );

      expect(find.text('Ações'), findsOneWidget);
      expect(find.textContaining('Ações ('), findsNothing);

      final popup =
          tester.widget<PopupMenuButton<BulkAction<String>>>(
        find.byType(PopupMenuButton<BulkAction<String>>),
      );
      expect(popup.enabled, isFalse);

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 0.5);
    });

    testWidgets(
        'com >=1 linha selecionada: botão "Ações (N)" fica habilitado',
        (tester) async {
      await pumpButton(
        tester,
        selectedCount: 3,
        selectedItems: const ['a', 'b', 'c'],
        actions: [
          BulkAction<String>(
            icon: Icons.picture_as_pdf,
            label: 'Gerar PDF',
            onPressed: (_, __) async {},
          ),
        ],
        onSelected: (_) {},
      );

      expect(find.text('Ações (3)'), findsOneWidget);

      final popup =
          tester.widget<PopupMenuButton<BulkAction<String>>>(
        find.byType(PopupMenuButton<BulkAction<String>>),
      );
      expect(popup.enabled, isTrue);

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 1);
    });

    testWidgets(
        'isEnabled da ação some (item desabilitado) quando algum '
        'selecionado não atende a regra (ex.: já CANCELADA)',
        (tester) async {
      await pumpButton(
        tester,
        selectedCount: 2,
        selectedItems: const ['ATIVA', 'CANCELADA'],
        actions: [
          BulkAction<String>(
            icon: Icons.cancel_outlined,
            label: 'Cancelar',
            isEnabled: (items) => items.every((s) => s != 'CANCELADA'),
            onPressed: (_, __) async {},
          ),
        ],
        onSelected: (_) {},
      );

      await tester.tap(find.byType(PopupMenuButton<BulkAction<String>>));
      await tester.pumpAndSettle();

      final item = tester.widget<PopupMenuItem<BulkAction<String>>>(
        find.byType(PopupMenuItem<BulkAction<String>>),
      );
      expect(item.enabled, isFalse);
    });
  });

  group('resumo de erro parcial (partial failure)', () {
    /// Reproduz a mesma lógica de agregação usada pelas BulkActions reais
    /// (_bulkGerarPdf/_bulkEnviar/_bulkCancelar em nfse_screen.dart e
    /// nfe_grid_screen.dart): processa item a item, soma sucesso/falha e
    /// monta uma única mensagem de resumo.
    String resumo(int ok, List<String> falhas) {
      return falhas.isEmpty
          ? '$ok processado(s) com sucesso'
          : '$ok processado(s), ${falhas.length} falharam: ${falhas.join(', ')}';
    }

    Future<({int ok, List<String> falhas})> processarLote(
      List<int> ids,
      Future<bool> Function(int id) chamar,
    ) async {
      var ok = 0;
      final falhas = <String>[];
      for (final id in ids) {
        try {
          final sucesso = await chamar(id);
          if (sucesso) {
            ok++;
          } else {
            falhas.add('#$id (falhou)');
          }
        } catch (e) {
          falhas.add('#$id ($e)');
        }
      }
      return (ok: ok, falhas: falhas);
    }

    test('3 de 5 com sucesso, 2 falham -> resumo cita as 2 falhas', () async {
      final resultado = await processarLote([1, 2, 3, 4, 5], (id) async {
        if (id == 2 || id == 4) return false;
        return true;
      });

      expect(resultado.ok, 3);
      expect(resultado.falhas, ['#2 (falhou)', '#4 (falhou)']);
      expect(
        resumo(resultado.ok, resultado.falhas),
        '3 processado(s), 2 falharam: #2 (falhou), #4 (falhou)',
      );
    });

    test('todas com sucesso -> resumo não menciona falha', () async {
      final resultado =
          await processarLote([1, 2, 3], (id) async => true);

      expect(resultado.ok, 3);
      expect(resultado.falhas, isEmpty);
      expect(resumo(resultado.ok, resultado.falhas), '3 processado(s) com sucesso');
    });

    test('exceção item a item também entra no resumo de falhas', () async {
      final resultado = await processarLote([1, 2], (id) async {
        if (id == 2) throw Exception('timeout');
        return true;
      });

      expect(resultado.ok, 1);
      expect(resultado.falhas, ['#2 (Exception: timeout)']);
      expect(
        resumo(resultado.ok, resultado.falhas),
        '1 processado(s), 1 falharam: #2 (Exception: timeout)',
      );
    });
  });
}
