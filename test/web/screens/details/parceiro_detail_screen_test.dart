// test/web/screens/details/parceiro_detail_screen_test.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebParceiroDetailScreen - contrato de faturamento', () {
    test('nao expoe Modulo Servicos no cadastro do parceiro', () {
      final source = File('lib/web/screens/details/parceiro_detail_screen.dart')
          .readAsStringSync();

      expect(source, isNot(contains('Modulo Servicos')));
      expect(source, isNot(contains('modulo_servicos')));
      expect(source, isNot(contains('parceiro-modulo')));
      expect(source, isNot(contains('_salvarModulos')));
    });
  });
}
