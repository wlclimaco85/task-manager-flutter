import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/mobile/screens/baixa_dialog_mensalidade.dart';
import 'package:task_manager_flutter/models/mensalidade_model.dart';

void main() {
  group('BaixaDialogMensalidade', () {
    testWidgets('Dialog exibe dados da mensalidade corretamente',
        (WidgetTester tester) async {
      // Arrange
      final mensalidade = Mensalidade(
        id: 123,
        valor: 150.50,
        alunoId: 456,
        planoId: 789,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          BaixaDialogMensalidade(mensalidade: mensalidade),
                    );
                  },
                  child: const Text('Abrir Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Abrir Dialog'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Confirmar Baixa'), findsOneWidget);
      expect(find.text('Mensalidade #123'), findsOneWidget);
      expect(find.text('Valor: R\$150.50'), findsOneWidget);
      expect(find.text('Aluno ID: 456'), findsOneWidget);
    });

    testWidgets('Dialog exibe erro quando mensalidade é null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          BaixaDialogMensalidade(mensalidade: null),
                    );
                  },
                  child: const Text('Abrir Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Dados da mensalidade não disponíveis.'), findsOneWidget);
    });

    testWidgets('TextField de Data está presente e editável',
        (WidgetTester tester) async {
      // Arrange
      final mensalidade = Mensalidade(
        id: 1,
        valor: 100.0,
        alunoId: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          BaixaDialogMensalidade(mensalidade: mensalidade),
                    );
                  },
                  child: const Text('Abrir Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Dialog'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Data da Baixa'), findsOneWidget);
    });

    testWidgets('Botões Cancelar e Confirmar Baixa estão presentes',
        (WidgetTester tester) async {
      // Arrange
      final mensalidade = Mensalidade(
        id: 1,
        valor: 100.0,
        alunoId: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          BaixaDialogMensalidade(mensalidade: mensalidade),
                    );
                  },
                  child: const Text('Abrir Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Dialog'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Confirmar Baixa'), findsOneWidget);
    });
  });
}
