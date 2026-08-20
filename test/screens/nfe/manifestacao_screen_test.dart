import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/services/manifestacao_caller.dart';
import 'package:task_manager_flutter/utils/api_links.dart';
import 'package:task_manager_flutter/web/screens/manifestacao_destinatario_screen.dart';

void main() {
  Widget wrap(Widget child, {Size size = const Size(1280, 900)}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(home: child),
    );
  }

  group('Manifestacao NFe - contrato atual', () {
    test('usa endpoints reais de manifestacao fiscal no backend', () {
      expect(
        ApiLinks.manifestacaoPendentes,
        contains('/api/fiscal/manifestacao/pendentes'),
      );
      expect(
        ApiLinks.manifestacaoHistorico,
        contains('/api/fiscal/manifestacao/historico'),
      );
      expect(
        ApiLinks.manifestacaoRegistrar,
        contains('/api/fiscal/manifestacao'),
      );
    });

    test('mantem os quatro eventos oficiais aceitos pelo backend', () {
      expect(
        ManifestacaoTipoEvento.valores,
        <String>[
          ManifestacaoTipoEvento.ciencia,
          ManifestacaoTipoEvento.confirmacao,
          ManifestacaoTipoEvento.desconhecimento,
          ManifestacaoTipoEvento.naoRealizada,
        ],
      );
    });

    test('justificativa obrigatoria segue regra do backend', () {
      expect(
        ManifestacaoTipoEvento.exigeJustificativa(
          ManifestacaoTipoEvento.confirmacao,
        ),
        isTrue,
      );
      expect(
        ManifestacaoTipoEvento.exigeJustificativa(
          ManifestacaoTipoEvento.naoRealizada,
        ),
        isTrue,
      );
      expect(
        ManifestacaoTipoEvento.exigeJustificativa(
          ManifestacaoTipoEvento.ciencia,
        ),
        isFalse,
      );
      expect(
        ManifestacaoTipoEvento.exigeJustificativa(
          ManifestacaoTipoEvento.desconhecimento,
        ),
        isFalse,
      );
    });

    test('resultado permite payload de lista, detalhe e erro', () {
      final success = ManifestacaoResult(
        success: true,
        data: {'status': 'ENVIADO'},
        list: const [
          {'nfeChave': '1'}
        ],
        statusCode: 200,
      );
      final error = ManifestacaoResult(
        success: false,
        message: 'Falha validada',
        statusCode: 400,
      );

      expect(success.data?['status'], 'ENVIADO');
      expect(success.list, hasLength(1));
      expect(error.message, 'Falha validada');
      expect(error.statusCode, 400);
    });
  });

  group('Manifestacao NFe - tela integrada', () {
    testWidgets('renderiza tela oficial de Manifestacao do Destinatario',
        (tester) async {
      await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));

      expect(find.text('Manifestacao do Destinatario'), findsNothing);
      expect(find.text('Manifestação do Destinatário'), findsOneWidget);
      expect(find.text('Pendências'), findsOneWidget);
      expect(find.text('Histórico'), findsOneWidget);
    });

    testWidgets('abre formulario de nova manifestacao', (tester) async {
      await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Nova Manifestação'));
      await tester.pumpAndSettle();

      expect(find.text('Chave de acesso da NFe (44 dígitos)'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Confirmar'), findsOneWidget);
    });

    testWidgets('valida tamanho da chave de acesso', (tester) async {
      await tester.pumpWidget(wrap(const ManifestacaoDestinatarioScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Nova Manifestação'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
      await tester.pumpAndSettle();

      expect(find.text('Chave de acesso deve ter 44 dígitos'), findsOneWidget);
    });

    testWidgets('usa acao compacta em largura mobile', (tester) async {
      await tester.pumpWidget(
        wrap(const ManifestacaoDestinatarioScreen(),
            size: const Size(360, 780)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.byIcon(Icons.add_circle), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'Nova Manifestação'),
        findsNothing,
      );
    });
  });
}
