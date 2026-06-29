import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/web/screens/anamnese_screen.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';

void main() {
  group('AnamneseScreen Widget Tests', () {
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      // Mock auth initialization
      AuthUtility.userInfo = null;
    });

    testWidgets('Deve exibir formulário vazio ao carregar tela',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: AnamneseScreen(
            alunoId: 1,
            nomeAluno: 'João Silva',
          ),
        ),
      );

      // Act & Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Form), findsNothing);

      // Aguardar carregamento
      await tester.pumpAndSettle();

      // Verificar que o formulário foi renderizado
      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.byType(SwitchListTile), findsNWidgets(3));
    });

    testWidgets('Deve salvar anamnese ao clicar em Salvar',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: AnamneseScreen(
            alunoId: 1,
            nomeAluno: 'João Silva',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act — Preencher formulário
      await tester.enterText(
        find.byType(TextFormField).first,
        'Ganho de massa',
      );

      // Clicar em Salvar
      final botaoSalvar = find.byIcon(Icons.save);
      expect(botaoSalvar, findsOneWidget);

      await tester.tap(botaoSalvar);
      await tester.pumpAndSettle();

      // Assert — Verificar que salvamento ocorreu
      // (SnackBar ou estado de sucesso)
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}

class MockClient extends Mock implements http.Client {}
