import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_chave_qr_card.dart';

const _chaveValida = '35240114200166000187550010000000015123456789';

Future<void> _pump(WidgetTester tester, String chave, {Size? size}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: NfeChaveQrCard(chave: chave)),
      ),
    ),
  );
}

void main() {
  group('NfeChaveQrCard — carregamento', () {
    testWidgets('renderiza o QR code quando a chave tem 44 dígitos válidos',
        (tester) async {
      await _pump(tester, _chaveValida);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Consulta pública SEFAZ'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_2_outlined), findsNothing);
    });

    testWidgets('mostra placeholder quando a chave está vazia (NF-e pendente)',
        (tester) async {
      await _pump(tester, '');
      expect(find.byType(QrImageView), findsNothing);
      expect(find.byIcon(Icons.qr_code_2_outlined), findsOneWidget);
      expect(find.text('QR disponível após emissão'), findsOneWidget);
    });

    testWidgets('mostra placeholder quando a chave é inválida (menos de 44 dígitos)',
        (tester) async {
      await _pump(tester, '12345');
      expect(find.byType(QrImageView), findsNothing);
      expect(find.byIcon(Icons.qr_code_2_outlined), findsOneWidget);
    });
  });

  group('NfeChaveQrCard — copiar chave', () {
    testWidgets('botão de copiar chave só aparece quando a chave é válida',
        (tester) async {
      await _pump(tester, '');
      expect(find.byIcon(Icons.copy_outlined), findsNothing);

      await _pump(tester, _chaveValida);
      expect(find.byIcon(Icons.copy_outlined), findsOneWidget);
    });

    testWidgets('copia a chave para a área de transferência e mostra feedback',
        (tester) async {
      final List<MethodCall> calls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add(call);
        return null;
      });

      await _pump(tester, _chaveValida);
      await tester.tap(find.byIcon(Icons.copy_outlined));
      await tester.pump();

      final setDataCall = calls.firstWhere(
          (c) => c.method == 'Clipboard.setData',
          orElse: () => throw StateError('Clipboard.setData não foi chamado'));
      expect(setDataCall.arguments['text'], _chaveValida);

      expect(find.text('Chave copiada'), findsOneWidget);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
  });

  group('NfeChaveQrCard — responsividade (375/768/1920px)', () {
    testWidgets('QR usa 120px em largura mobile (375px)', (tester) async {
      await _pump(tester, _chaveValida, size: const Size(375, 800));
      final qr = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qr.size, 120);
    });

    testWidgets('QR usa 140px em largura tablet (768px)', (tester) async {
      await _pump(tester, _chaveValida, size: const Size(768, 1024));
      final qr = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qr.size, 140);
    });

    testWidgets('QR usa 160px em largura desktop (1920px)', (tester) async {
      await _pump(tester, _chaveValida, size: const Size(1920, 1080));
      final qr = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qr.size, 160);
    });
  });
}
