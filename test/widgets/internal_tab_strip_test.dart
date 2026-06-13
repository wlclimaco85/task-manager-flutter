// test/widgets/internal_tab_strip_test.dart
//
// Testes de widget para showTabLimitDialog (popup de "limite de abas
// atingido"). Valida seleção múltipla via checkboxes e a opção
// "fechar todas".

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:task_manager_flutter/models/open_tab.dart';
import 'package:task_manager_flutter/widgets/internal_tab_strip.dart';

List<OpenTab> _buildTabs() => List.generate(
      5,
      (i) => OpenTab(
        id: 'screen_$i',
        label: 'Aba $i',
        icon: FontAwesomeIcons.house,
        content: const SizedBox.shrink(),
        screenIndex: i,
      ),
    );

Widget _wrap(VoidCallback onPressed) => MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: onPressed,
            child: const Text('abrir'),
          ),
        ),
      ),
    );

void main() {
  group('showTabLimitDialog — seleção múltipla', () {
    testWidgets('retorna os índices das abas marcadas via checkbox', (tester) async {
      List<int>? resultado;

      await tester.pumpWidget(_wrap(() {}));
      final context = tester.element(find.byType(ElevatedButton));

      unawaited(showTabLimitDialog(
        context: context,
        tabs: _buildTabs(),
        newTabLabel: 'Nova Aba',
        isCompact: true,
      ).then((value) => resultado = value));
      await tester.pumpAndSettle();

      // Marca as abas de índice 1 e 3.
      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox).at(3));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fechar selecionadas e abrir'));
      await tester.pumpAndSettle();

      expect(resultado, [1, 3]);
    });

    testWidgets('botão "Fechar selecionadas e abrir" fica desabilitado sem seleção', (tester) async {
      await tester.pumpWidget(_wrap(() {}));
      final context = tester.element(find.byType(ElevatedButton));

      unawaited(showTabLimitDialog(
        context: context,
        tabs: _buildTabs(),
        newTabLabel: 'Nova Aba',
        isCompact: true,
      ));
      await tester.pumpAndSettle();

      final botao = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Fechar selecionadas e abrir'));
      expect(botao.onPressed, isNull);
    });

    testWidgets('"Fechar todas e abrir" retorna todos os índices', (tester) async {
      List<int>? resultado;
      final tabs = _buildTabs();

      await tester.pumpWidget(_wrap(() {}));
      final context = tester.element(find.byType(ElevatedButton));

      unawaited(showTabLimitDialog(
        context: context,
        tabs: tabs,
        newTabLabel: 'Nova Aba',
        isCompact: true,
      ).then((value) => resultado = value));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fechar todas e abrir'));
      await tester.pumpAndSettle();

      expect(resultado, List.generate(tabs.length, (i) => i));
    });

    testWidgets('"Cancelar" retorna null', (tester) async {
      List<int>? resultado = [99];

      await tester.pumpWidget(_wrap(() {}));
      final context = tester.element(find.byType(ElevatedButton));

      unawaited(showTabLimitDialog(
        context: context,
        tabs: _buildTabs(),
        newTabLabel: 'Nova Aba',
        isCompact: true,
      ).then((value) => resultado = value));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(resultado, isNull);
    });
  });
}
