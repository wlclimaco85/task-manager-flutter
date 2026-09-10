import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/conta_bancaria_model.dart';
import 'package:task_manager_flutter/models/empresa_model.dart';
import 'package:task_manager_flutter/widgets/finance/ajuste_saldo_conta_dialog.dart';

void main() {
  testWidgets('bloqueia saldo final ao preencher saldo inicial',
      (WidgetTester tester) async {
    await tester.pumpWidget(_app());

    await tester.enterText(
      find.byKey(const Key('ajuste_saldo_inicial_field')),
      '150,25',
    );
    await tester.pump();

    final saldoFinal = tester.widget<TextField>(
      find.byKey(const Key('ajuste_saldo_final_field')),
    );
    expect(saldoFinal.enabled, isFalse);
  });

  testWidgets('bloqueia saldo inicial ao preencher saldo final',
      (WidgetTester tester) async {
    await tester.pumpWidget(_app());

    await tester.enterText(
      find.byKey(const Key('ajuste_saldo_final_field')),
      '300,00',
    );
    await tester.pump();

    final saldoInicial = tester.widget<TextField>(
      find.byKey(const Key('ajuste_saldo_inicial_field')),
    );
    expect(saldoInicial.enabled, isFalse);
  });

  testWidgets('salva somente o saldo informado', (WidgetTester tester) async {
    double? saldoInicialEnviado;
    double? saldoFinalEnviado;

    await tester.pumpWidget(_app(
      onSalvar: ({saldoInicial, saldoFinal}) async {
        saldoInicialEnviado = saldoInicial;
        saldoFinalEnviado = saldoFinal;
        return true;
      },
    ));

    await tester.enterText(
      find.byKey(const Key('ajuste_saldo_inicial_field')),
      '150,25',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('ajuste_saldo_salvar_button')));
    await tester.pumpAndSettle();

    expect(saldoInicialEnviado, 150.25);
    expect(saldoFinalEnviado, isNull);
  });
}

Widget _app({AjusteSaldoContaSubmit? onSalvar}) {
  return MaterialApp(
    home: Scaffold(
      body: AjusteSaldoContaDialog(
        conta: ContaBancaria(
          id: 1,
          banco: 'Caixa',
          agencia: '0001',
          numero: '00000-0',
          descricao: 'Conta Padrao',
          empresa: Empresa(id: 1, nome: 'Empresa Smoke Test'),
        ),
        onSalvar: onSalvar ??
            ({saldoInicial, saldoFinal}) async {
              return true;
            },
      ),
    ),
  );
}
