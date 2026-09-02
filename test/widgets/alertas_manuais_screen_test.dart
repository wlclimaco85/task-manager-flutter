import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/alerta_manual_model.dart';
import 'package:task_manager_flutter/services/alertas_manuais_service.dart';
import 'package:task_manager_flutter/widgets/alertas/alertas_manuais_screen.dart';

class _FakeAlertasRepository implements AlertasManuaisRepository {
  List<int>? ultimoParceiros;
  String? ultimoTexto;

  @override
  Future<ResultadoDisparoAlerta> disparar({
    required String texto,
    required List<int> parceiroIds,
  }) async {
    ultimoTexto = texto;
    ultimoParceiros = List<int>.from(parceiroIds);
    return ResultadoDisparoAlerta(
      destinatarios: parceiroIds.isEmpty ? 2 : parceiroIds.length,
      todosClientes: parceiroIds.isEmpty,
    );
  }

  @override
  Future<List<AlertaManual>> listar() async {
    return const [
      AlertaManual(
        id: 1,
        idUserDestino: 10,
        texto: 'Por favor mande o extrato bancario',
        status: 'NOVO',
        empresaId: 1,
        parceiroId: 101,
        parceiroNome: 'Cliente A',
      ),
    ];
  }

  @override
  Future<List<ParceiroAlertaOpcao>> listarParceiros() async {
    return const [
      ParceiroAlertaOpcao(id: 101, nome: 'Cliente A', documento: '111'),
      ParceiroAlertaOpcao(id: 102, nome: 'Cliente B', documento: '222'),
    ];
  }
}

void main() {
  testWidgets(
      'avisa antes de enviar para todos quando nenhum parceiro foi selecionado',
      (tester) async {
    final repo = _FakeAlertasRepository();
    await tester.pumpWidget(MaterialApp(
      home: AlertasManuaisScreen(
        repository: repo,
        possuiParceiroNoTenant: false,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Enviar extrato');
    await tester.tap(find.text('Enviar alerta'));
    await tester.pumpAndSettle();

    expect(find.text('Enviar para todos os clientes?'), findsOneWidget);

    await tester.tap(find.text('Nao'));
    await tester.pumpAndSettle();
    expect(repo.ultimoTexto, isNull);

    await tester.tap(find.text('Enviar alerta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sim'));
    await tester.pumpAndSettle();

    expect(repo.ultimoTexto, 'Enviar extrato');
    expect(repo.ultimoParceiros, isEmpty);
  });

  testWidgets(
      'permite marcar todos e envia somente para os parceiros selecionados',
      (tester) async {
    final repo = _FakeAlertasRepository();
    await tester.pumpWidget(MaterialApp(
      home: AlertasManuaisScreen(
        repository: repo,
        possuiParceiroNoTenant: false,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Cliente A'), findsWidgets);
    expect(find.text('Cliente B'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Enviar documentos');
    await tester.tap(find.text('Marcar todos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar alerta'));
    await tester.pumpAndSettle();

    expect(repo.ultimoTexto, 'Enviar documentos');
    expect(repo.ultimoParceiros, [101, 102]);
  });

  testWidgets('login com parceiro visualiza alertas sem formulario de envio',
      (tester) async {
    final repo = _FakeAlertasRepository();
    await tester.pumpWidget(MaterialApp(
      home: AlertasManuaisScreen(
        repository: repo,
        possuiParceiroNoTenant: true,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Novo alerta'), findsNothing);
    expect(find.text('Por favor mande o extrato bancario'), findsOneWidget);
  });
}
