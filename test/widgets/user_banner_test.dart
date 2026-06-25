import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/user_banners.dart';

void main() {
  group('SimpleAppBar', () {
    testWidgets('renderiza titulo e icone', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: SimpleAppBar(
              title: 'Calendário Financeiro',
              icon: Icons.calendar_month,
            ),
          ),
        ),
      );

      expect(find.text('Calendário Financeiro'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month), findsOneWidget);
    });

    testWidgets('renderiza acoes extras', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: SimpleAppBar(
              title: 'Teste',
              icon: Icons.dashboard_rounded,
              extraActions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('renderiza bottom widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: SimpleAppBar(
              title: 'Teste',
              icon: Icons.dashboard_rounded,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  height: 48,
                  color: Colors.red,
                  child: const Text('Botão'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Botão'), findsOneWidget);
    });
  });

}
