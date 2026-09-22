import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/finance/cnab_config_screen.dart';

void main() {
  test('desembrulha lista de contas no envelope paginado do backend', () {
    final contas = CnabConfigScreen.extractContas({
      'data': {
        'dados': [
          {'id': 8, 'banco': 'Banco Teste'},
        ],
      },
    });

    expect(contas, hasLength(1));
    expect(contas.single['id'], 8);
  });

  test('payload da conta nova fica vinculado a empresa e parceiro do cadastro',
      () {
    final payload = CnabConfigScreen.buildContaCadastroPayload(
      banco: ' Banco Teste ',
      agencia: '123',
      numero: '456',
      descricao: 'Conta CNAB',
      tipo: 'CONTA_CORRENTE',
      saldoInicial: '10,50',
      empresaId: 20,
      parceiroId: 30,
    );

    expect(payload['banco'], 'Banco Teste');
    expect(payload['saldoInicial'], 10.5);
    expect(payload['empresaId'], 20);
    expect(payload['parceiroId'], 30);
    expect(payload['ativo'], isTrue);
    expect(payload['dataAbertura'], isA<String>());
  });

  testWidgets('estado vazio abre popup com campos de cadastro da conta',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: CnabConfigScreen(empresaId: 20, parceiroId: 30),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Cadastrar conta bancaria'), findsOneWidget);
    await tester.tap(find.text('Cadastrar conta bancaria'));
    await tester.pumpAndSettle();

    expect(find.text('Banco'), findsOneWidget);
    expect(find.text('Agencia'), findsOneWidget);
    expect(find.text('Numero'), findsOneWidget);
    expect(find.text('Tipo'), findsOneWidget);
    expect(find.text('Saldo inicial'), findsOneWidget);
    expect(find.text('Salvar conta'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });
}
