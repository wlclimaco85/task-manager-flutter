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
}
