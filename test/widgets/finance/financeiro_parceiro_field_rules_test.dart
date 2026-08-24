import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/finance/financeiro_parceiro_field_rules.dart';

void main() {
  group('FinanceiroParceiroFieldRules', () {
    test(
        'habilita parceiro e bloqueia fornecedor quando nao existe parceiro no contexto',
        () {
      expect(FinanceiroParceiroFieldRules.parceiroHabilitado(parceiroId: null),
          isTrue);
      expect(
          FinanceiroParceiroFieldRules.fornecedorHabilitado(parceiroId: null),
          isFalse);
    });

    test(
        'bloqueia parceiro e habilita fornecedor quando existe parceiro no contexto',
        () {
      expect(FinanceiroParceiroFieldRules.parceiroHabilitado(parceiroId: 1751),
          isFalse);
      expect(
          FinanceiroParceiroFieldRules.fornecedorHabilitado(parceiroId: 1751),
          isTrue);
    });

    test('trata zero como ausencia de parceiro', () {
      expect(FinanceiroParceiroFieldRules.normalizarParceiroId(0), isNull);
      expect(FinanceiroParceiroFieldRules.parceiroHabilitado(parceiroId: 0),
          isTrue);
      expect(FinanceiroParceiroFieldRules.fornecedorHabilitado(parceiroId: 0),
          isFalse);
    });

    test('aceita parcId como indicador de parceiro no localStorage', () {
      expect(FinanceiroParceiroFieldRules.normalizarParceiroId('42'), 42);
      expect(FinanceiroParceiroFieldRules.parceiroHabilitado(parcId: '42'),
          isFalse);
      expect(FinanceiroParceiroFieldRules.fornecedorHabilitado(parcId: '42'),
          isTrue);
    });
  });
}
