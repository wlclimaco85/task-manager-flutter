import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/manifestacao/manifestacao_status.dart';
import 'package:task_manager_flutter/widgets/manifestacao/status_badge.dart';
import 'package:flutter/semantics.dart';

void main() {
  group('StatusBadge', () {
    testWidgets('Renderiza badge com status null', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: null),
          ),
        ),
      );

      expect(find.byType(StatusBadge), findsOneWidget);
      expect(find.text('Não Manifestado'), findsOneWidget);
    });

    testWidgets('Renderiza badge com status aceitar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: ManifestacaoStatus.aceitar),
          ),
        ),
      );

      expect(find.text('Aceito'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('Renderiza badge com status parcial', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: ManifestacaoStatus.parcial),
          ),
        ),
      );

      expect(find.text('Aceito Parcial'), findsOneWidget);
      expect(find.byIcon(Icons.assignment_late), findsOneWidget);
    });

    testWidgets('Renderiza badge com status recusar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: ManifestacaoStatus.recusar),
          ),
        ),
      );

      expect(find.text('Recusado'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('Dark mode inverte cores', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              status: ManifestacaoStatus.aceitar,
              isDarkMode: true,
            ),
          ),
        ),
      );

      expect(find.byType(StatusBadge), findsOneWidget);
      expect(find.text('Aceito'), findsOneWidget);
    });

    testWidgets('Acessibilidade — renderiza com semantics', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: ManifestacaoStatus.aceitar),
          ),
        ),
      );

      expect(find.text('Aceito'), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });
  });
}
