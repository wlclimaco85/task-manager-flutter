import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/windows/screens/manifestacao_destinatario_screen.dart';

/// Testes de widget da tela de Manifestação do Destinatário (Windows).
/// Sem servidor de teste disponível, a chamada de rede real falha
/// rapidamente e a tela cai no estado de erro — comportamento coberto aqui.
void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  group('ManifestacaoDestinatarioScreen (Windows) - estrutura e estados', () {
    testWidgets('mostra indicador de carregamento inicialmente',
        (tester) async {
      await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('mostra título e as duas abas (Pendências/Histórico)',
        (tester) async {
      await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
      expect(find.text('Manifestação do Destinatário'), findsOneWidget);
      expect(find.text('Pendências'), findsOneWidget);
      expect(find.text('Histórico'), findsOneWidget);
    });

    testWidgets('sem rede, cai no estado de erro após a chamada falhar',
        (tester) async {
      await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets('troca de aba Pendências -> Histórico recarrega dados',
        (tester) async {
      await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.text('Histórico'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('ManifestacaoDestinatarioScreen (Windows) - formulário', () {
    testWidgets('desktop sempre mostra botão com rótulo completo',
        (tester) async {
      await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.widgetWithText(ElevatedButton, 'Nova Manifestação'),
          findsOneWidget);
    });

    testWidgets('exige justificativa para Operação não Realizada',
        (tester) async {
      await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Nova Manifestação'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '9' * 44);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Operação não Realizada').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
      await tester.pumpAndSettle();

      expect(find.text('Justificativa é obrigatória para este tipo de manifestação'),
          findsOneWidget);
    });

    testWidgets('Desconhecimento da Operação não exige justificativa',
        (tester) async {
      await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Nova Manifestação'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '7' * 44);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Desconhecimento da Operação').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
      await tester.pumpAndSettle();

      expect(
          find.text('Justificativa é obrigatória para este tipo de manifestação'),
          findsNothing);
    });
  });
}
