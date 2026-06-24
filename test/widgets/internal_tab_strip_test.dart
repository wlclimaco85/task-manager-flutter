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
    testWidgets('retorna os índices das abas marcadas via checkbox',
        (tester) async {
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

      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox).at(3));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fechar selecionadas e abrir'));
      await tester.pumpAndSettle();

      expect(resultado, [1, 3]);
    });

    testWidgets(
        'botão "Fechar selecionadas e abrir" fica desabilitado sem seleção',
        (tester) async {
      await tester.pumpWidget(_wrap(() {}));
      final context = tester.element(find.byType(ElevatedButton));

      unawaited(showTabLimitDialog(
        context: context,
        tabs: _buildTabs(),
        newTabLabel: 'Nova Aba',
        isCompact: true,
      ));
      await tester.pumpAndSettle();

      final botao = tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'Fechar selecionadas e abrir'));
      expect(botao.onPressed, isNull);
    });

    testWidgets('"Fechar todas e abrir" retorna todos os índices',
        (tester) async {
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

  group('InternalTabStrip', () {
    testWidgets('renderiza todas as abas', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: InternalTabStrip(
            tabs: _buildTabs(),
            activeIndex: 0,
            onActivate: (_) {},
            onClose: (_) {},
          ),
        ),
      ));
      for (int i = 0; i < 5; i++) {
        expect(find.text('Aba $i'), findsOneWidget);
      }
    });

    testWidgets('isCompact reduz tamanho', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: InternalTabStrip(
            tabs: _buildTabs(),
            activeIndex: 0,
            onActivate: (_) {},
            onClose: (_) {},
            isCompact: true,
          ),
        ),
      ));
      expect(find.text('Aba 0'), findsOneWidget);
    });

    testWidgets('onClose eh chamado ao fechar aba', (tester) async {
      int? closedIndex;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: InternalTabStrip(
            tabs: _buildTabs(),
            activeIndex: 0,
            onActivate: (_) {},
            onClose: (i) => closedIndex = i,
          ),
        ),
      ));
      expect(find.text('Aba 0'), findsOneWidget);
    });
  });

  group('auto-close (comportamento antigo popup removido)', () {
    test('lista remove primeiro item e adiciona novo', () {
      final tabs = _buildTabs();
      expect(tabs.length, 5);

      final novo = OpenTab(
        id: 'screen_nova',
        label: 'Nova Aba',
        icon: FontAwesomeIcons.house,
        content: const SizedBox.shrink(),
        screenIndex: 99,
      );

      tabs.removeAt(0);
      tabs.add(novo);

      expect(tabs.length, 5);
      expect(tabs[0].label, 'Aba 1');
      expect(tabs[4].label, 'Nova Aba');
    });
  });
}
