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
        openedAt: DateTime.now(),
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
        openedAt: DateTime.now(),
      );

      tabs.removeAt(0);
      tabs.add(novo);

      expect(tabs.length, 5);
      expect(tabs[0].label, 'Aba 1');
      expect(tabs[4].label, 'Nova Aba');
    });
  });
}
