// test/web/screens/details/parceiro_detail_screen_test.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebParceiroDetailScreen - contrato de faturamento', () {
    test('nao expoe Modulo Servicos no cadastro do parceiro', () {
      final source = File('lib/web/screens/details/parceiro_detail_screen.dart')
          .readAsStringSync();

      expect(source, contains("fieldName: 'modulo_servicos'"));
      expect(source, contains("fieldName: 'modulosServico'"));
      expect(source, contains('isInForm: false'));
      expect(source, isNot(contains('parceiro-modulo')));
      expect(source, isNot(contains('_salvarModulos')));
    });
  });

  // Fix (2026-09-16): "Novo Login" na aba Logins do Parceiro falhava com
  // 400 "Tipo Login é obrigatório." -- o form nao envia esse campo
  // (isInForm: false, herdado de WebLoginGridScreen.fieldOverrides) e
  // ninguem preenchia um default. Todo login criado por esta aba e' de
  // cliente vinculado ao parceiro -- tipoLogin sempre APP_ABRACO (id 6).
  group('WebParceiroDetailScreen - Logins (fix Tipo Login obrigatorio)', () {
    test('aba Logins envia tipoLogin=6 (APP_ABRACO) por default', () {
      final source = File('lib/web/screens/details/parceiro_detail_screen.dart')
          .readAsStringSync();

      expect(source, contains("'tipoLogin': 6"));
      expect(source, contains('WebLoginGridScreen.additionalFormData'));
    });
  });

  test(
      'aba CNAB envia empresa e parceiro e POP/Mail nao chama tela inexistente',
      () {
    final source = File('lib/web/screens/details/parceiro_detail_screen.dart')
        .readAsStringSync();

    expect(source, contains('empresaId: empresaIdInt'));
    expect(source, contains('parceiroId: parceiroId'));
    expect(source, contains("title: 'POP/Mail'"));
    expect(source, contains('SmtpConfigTab('));
    expect(source, contains('SmtpConfigScope.parceiro'));
    expect(source, isNot(contains("telaNome: 'parceiro_email_pop'")));
  });

  group('WebParceiroDetailScreen - tipo_estabelecimento e matriz', () {
    test('suprime parceiro duplicado e configura matriz condicional a FILIAL', () {
      final source = File('lib/web/screens/details/parceiro_detail_screen.dart')
          .readAsStringSync();

      expect(source, contains("fieldName: 'parceiro'"));
      expect(source, contains("isInForm: false"));
      expect(source, contains("fieldName: 'tipo_estabelecimento'"));
      expect(source, contains("'value': 'MATRIZ'"));
      expect(source, contains("'value': 'FILIAL'"));
      expect(source, contains("fieldName: 'matriz'"));
      expect(source, contains("visibleWhen: 'tipo_estabelecimento==FILIAL'"));
    });
  });
}
