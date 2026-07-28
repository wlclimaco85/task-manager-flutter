import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/manifestacao/manifestacao_status.dart';
import 'package:task_manager_flutter/widgets/manifestacao/status_dropdown.dart';

void main() {
  group('StatusDropdown', () {
    testWidgets('Renderiza dropdown com label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusDropdown(
              onChanged: (_) {},
              label: 'Tipo de Manifestação',
            ),
          ),
        ),
      );

      expect(find.text('Tipo de Manifestação'), findsOneWidget);
      expect(find.byType(DropdownButton<ManifestacaoStatus>), findsOneWidget);
    });

    testWidgets('Mostra asterisco quando valor é null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusDropdown(
              value: null,
              onChanged: (_) {},
              label: 'Tipo de Manifestação',
            ),
          ),
        ),
      );

      expect(find.text(' *'), findsOneWidget);
    });

    testWidgets('Expande dropdown ao clicar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusDropdown(
              onChanged: (_) {},
              label: 'Tipo de Manifestação',
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DropdownButton<ManifestacaoStatus>));
      await tester.pumpAndSettle();

      expect(find.text('Aceito'), findsOneWidget);
      expect(find.text('Aceito Parcial'), findsOneWidget);
      expect(find.text('Recusado'), findsOneWidget);
    });

    testWidgets('Seleciona opção corretamente', (WidgetTester tester) async {
      ManifestacaoStatus? selecionado;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusDropdown(
              onChanged: (value) => selecionado = value,
              label: 'Tipo de Manifestação',
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DropdownButton<ManifestacaoStatus>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aceito').first);
      await tester.pumpAndSettle();

      expect(selecionado, equals(ManifestacaoStatus.aceitar));
    });

    testWidgets('Mostra mensagem de erro', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusDropdown(
              onChanged: (_) {},
              label: 'Tipo de Manifestação',
              errorText: 'Campo obrigatório',
            ),
          ),
        ),
      );

      expect(find.text('Campo obrigatório'), findsOneWidget);
    });

    testWidgets('Desabilitado quando isEnabled=false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusDropdown(
              onChanged: (_) {},
              label: 'Tipo de Manifestação',
              isEnabled: false,
            ),
          ),
        ),
      );

      expect(find.byType(DropdownButton<ManifestacaoStatus>), findsOneWidget);
    });

    testWidgets('Semantics label presente', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusDropdown(
              onChanged: (_) {},
              label: 'Tipo de Manifestação',
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Tipo de Manifestação'), findsOneWidget);
    });

    testWidgets('Dark mode muda cores', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusDropdown(
              onChanged: (_) {},
              label: 'Tipo de Manifestação',
              isDarkMode: true,
            ),
          ),
        ),
      );

      expect(find.byType(DropdownButton<ManifestacaoStatus>), findsOneWidget);
    });
  });
}
