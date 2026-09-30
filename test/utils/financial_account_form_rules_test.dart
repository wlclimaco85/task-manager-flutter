import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/financial_account_form_rules.dart';

void main() {
  test('oculta somente ids internos dos formularios financeiros', () {
    expect(isFinancialInternalFormField('conta_pagar', 'modulo_id'), isTrue);
    expect(isFinancialInternalFormField('conta_receber', 'moduloId'), isTrue);
    expect(isFinancialInternalFormField('conta_pagar', 'contrato_id'), isTrue);
    expect(isFinancialInternalFormField('conta_receber', 'contratoId'), isTrue);
    expect(isFinancialInternalFormField('conta_pagar', 'descricao'), isFalse);
  });

  test('ordena obrigatorios, recorrencia e dados de baixa nessa sequencia', () {
    final obrigatorio = financialAccountFormOrder(
      screenName: 'conta_pagar',
      fieldName: 'descricao',
      backendOrder: 8,
      isRequired: true,
    );
    final geral = financialAccountFormOrder(
      screenName: 'conta_pagar',
      fieldName: 'observacao',
      backendOrder: 9,
      isRequired: false,
    );
    final recorrencia = financialAccountFormOrder(
      screenName: 'conta_pagar',
      fieldName: 'recorrencia_ativa',
      backendOrder: 20,
      isRequired: false,
    );
    final baixa = financialAccountFormOrder(
      screenName: 'conta_pagar',
      fieldName: 'data_baixa',
      backendOrder: 4,
      isRequired: false,
    );

    expect(obrigatorio, lessThan(geral));
    expect(geral, lessThan(recorrencia));
    expect(recorrencia, lessThan(baixa));
  });

  test('nao altera a ordem de outras telas', () {
    expect(
      financialAccountFormOrder(
        screenName: 'produto',
        fieldName: 'descricao',
        backendOrder: 7,
        isRequired: true,
      ),
      7,
    );
  });
}
