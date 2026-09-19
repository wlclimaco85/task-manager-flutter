// test/windows/screens/details/parceiro_detail_screen_test.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WindowsParceiroDetailScreen - contrato de faturamento', () {
    test('nao expoe Modulo Servicos no cadastro do parceiro', () {
      final source =
          File('lib/windows/screens/details/parceiro_detail_screen.dart')
              .readAsStringSync();

      expect(source, contains("fieldName: 'modulo_servicos'"));
      expect(source, contains("fieldName: 'modulosServico'"));
      expect(source, contains('isInForm: false'));
      expect(source, isNot(contains('parceiro-modulo')));
      expect(source, isNot(contains('_salvarModulos')));
    });
  });

  group('WindowsParceiroDetailScreen - tipoEstabelecimento e matriz', () {
    test('suprime parceiro duplicado e configura matriz condicional a FILIAL', () {
      final source =
          File('lib/windows/screens/details/parceiro_detail_screen.dart')
              .readAsStringSync();

      expect(source, contains("fieldName: 'parceiro'"));
      expect(source, contains("isInForm: false"));
      expect(source, contains("fieldName: 'tipoEstabelecimento'"));
      expect(source, contains("'value': 'MATRIZ'"));
      expect(source, contains("'value': 'FILIAL'"));
      expect(source, contains("fieldName: 'matriz'"));
      expect(source, contains("visibleWhen: 'tipoEstabelecimento==FILIAL'"));
    });
  });
}
