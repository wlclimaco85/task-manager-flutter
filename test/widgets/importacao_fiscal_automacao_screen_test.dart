import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/importacao_fiscal_automacao_screen.dart';

/// Tela dedicada Sistema > Importação Fiscal / Automação Fiscal
/// (2026-09-10) -- extraída de "Config. Sistema" (admin-only) para o app
/// cliente, com `telaNome` próprio na matriz de Permissões, porque o
/// escritório precisa liberar esse recurso pontualmente por empresa.
void main() {
  Widget wrap() => const MaterialApp(
        home: ImportacaoFiscalAutomacaoScreen(),
      );

  testWidgets('renderiza as 2 abas (Importação Fiscal / Automação Fiscal)',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(
      find.byKey(const Key('importacao_fiscal_automacao_tab_bar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('importacao_fiscal_automacao_tab_manual')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('importacao_fiscal_automacao_tab_automatica')),
      findsOneWidget,
    );
  });

  testWidgets('so existe 1 AppBar (sem duplicar chrome dentro da aba)',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.byType(AppBar), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('importacao_fiscal_automacao_tab_automatica')),
    );
    await tester.pump();

    expect(find.byType(AppBar), findsOneWidget);
  });
}
