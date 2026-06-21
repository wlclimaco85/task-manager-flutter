import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/regua_cobranca_model.dart';
import 'package:task_manager_flutter/services/regua_cobranca_service.dart';
import 'package:task_manager_flutter/web/screens/cobranca_automatica_screen.dart';

void main() {
  testWidgets('mostra painel, fila e variaveis da regua de cobranca',
      (tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = _FakeReguaCobrancaService();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 1200,
          height: 800,
          child: CobrancaAutomaticaScreen(service: service),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Valor vencido'), findsOneWidget);
    expect(find.text('R\$ 450,00'), findsOneWidget);
    expect(find.text('2 dia(s) antes do vencimento'), findsOneWidget);

    await tester.tap(find.byTooltip('Editar etapa'));
    await tester.pumpAndSettle();
    expect(find.textContaining('{{pix_copia_cola}}'), findsOneWidget);
    expect(find.text('Dias relativos ao vencimento'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(TabBar), const Offset(-180, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fila (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Reprocessar'), findsOneWidget);

    await tester.tap(find.text('Reprocessar'));
    await tester.pumpAndSettle();
    expect(service.reprocessados, contains(99));
  });
}

class _FakeReguaCobrancaService extends ReguaCobrancaService {
  final List<int> reprocessados = [];

  @override
  Future<List<ReguaCobranca>> listarReguas() async => const [
        ReguaCobranca(
          id: 1,
          nome: 'Pre vencimento',
          diasAposVencimento: -2,
          canal: CanalCobranca.email,
          mensagem: 'Ola {{cliente}}, pague em {{link_pagamento}}',
          somenteDiaUtil: true,
          ordem: 1,
        ),
      ];

  @override
  Future<List<CobrancaRegua>> listarPendencias() async => const [
        CobrancaRegua(
          id: 10,
          clienteNome: 'Cliente Teste',
          valor: 450,
          vencimento: null,
          status: 'VENCIDO',
        ),
      ];

  @override
  Future<List<CobrancaRegua>> listarFila() async => const [
        CobrancaRegua(
          id: 99,
          clienteNome: 'Cliente Fila',
          valor: 450,
          vencimento: null,
          status: 'FALHA_RETRY',
          canal: CanalCobranca.whatsapp,
          resultado: 'ERRO_ENVIO',
        ),
      ];

  @override
  Future<List<CobrancaRegua>> listarHistorico() async => const [];

  @override
  Future<PainelReguaCobranca> carregarPainel() async =>
      const PainelReguaCobranca(
        titulosEmAberto: 1,
        enviosPendentes: 1,
        enviosEnviados: 2,
        enviosFalha: 1,
        valorVencido: 450,
        valorAVencer: 120,
        valorRecuperado: 0,
        aging: [],
      );

  @override
  Future<void> reprocessar(int acaoId) async {
    reprocessados.add(acaoId);
  }
}
