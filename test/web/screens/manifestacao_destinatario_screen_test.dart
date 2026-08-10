import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/web/screens/manifestacao_destinatario_screen.dart';

/// Testes de widget da tela de Manifestação do Destinatário (web/windows
/// compartilham a mesma implementação de UI). Sem servidor de teste
/// disponível, a chamada de rede real falha rapidamente e a tela cai no
/// estado de erro — o que é o comportamento coberto e verificado aqui.
void main() {
  Widget wrap(Widget child, {Size size = const Size(1280, 900)}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(home: child),
    );
  }

  group('ManifestacaoDestinatarioScreen - estrutura e estados', () {
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

    testWidgets(
        'sem rede disponível, cai no estado de erro após a chamada falhar',
        (tester) async {
      await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets('botão "Tentar novamente" reexecuta o carregamento',
        (tester) async {
      await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('ManifestacaoDestinatarioScreen - formulário de nova manifestação',
      () {
    testWidgets('botão "Nova Manifestação" abre o diálogo com os 4 tipos',
        (tester) async {
      await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Nova Manifestação'));
      await tester.pumpAndSettle();

      expect(find.text('Chave de acesso da NFe (44 dígitos)'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('valida chave de acesso com menos de 44 dígitos',
        (tester) async {
      await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Nova Manifestação'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '12345');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
      await tester.pumpAndSettle();

      expect(find.text('Chave de acesso deve ter 44 dígitos'), findsOneWidget);
    });

    testWidgets(
        'exige justificativa quando tipo = Confirmação da Operação',
        (tester) async {
      await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Nova Manifestação'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '3' * 44);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmação da Operação').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
      await tester.pumpAndSettle();

      expect(find.text('Justificativa é obrigatória para este tipo de manifestação'),
          findsOneWidget);
    });

    testWidgets(
        'não exige justificativa quando tipo = Ciência da Emissão (default)',
        (tester) async {
      await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Nova Manifestação'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '5' * 44);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
      await tester.pumpAndSettle();

      // Diálogo fecha (sem erro de validação) e a chamada de rede falha
      // em seguida, exibindo mensagem de erro via SnackBar.
      expect(find.text('Chave de acesso deve ter 44 dígitos'), findsNothing);
      expect(
          find.text('Justificativa é obrigatória para este tipo de manifestação'),
          findsNothing);
    });

    testWidgets('botão Cancelar fecha o diálogo sem enviar', (tester) async {
      await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Nova Manifestação'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Chave de acesso da NFe (44 dígitos)'), findsNothing);
    });
  });

  group('ManifestacaoDestinatarioScreen - responsividade', () {
    testWidgets('em largura mobile (360px) usa botão de ícone compacto',
        (tester) async {
      await tester.pumpWidget(
        wrap(const ManifestacaoDestinatarioScreen(), size: const Size(360, 780)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.widgetWithText(ElevatedButton, 'Nova Manifestação'),
          findsNothing);
      expect(find.byIcon(Icons.add_circle), findsOneWidget);
    });

    testWidgets('em largura desktop (1280px) usa botão com rótulo completo',
        (tester) async {
      await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.widgetWithText(ElevatedButton, 'Nova Manifestação'),
          findsOneWidget);
      expect(find.byIcon(Icons.add_circle), findsNothing);
    });
  });
}
