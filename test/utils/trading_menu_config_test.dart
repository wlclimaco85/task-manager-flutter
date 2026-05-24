import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/menu_config.dart';

void main() {
  group('MenuConfig — Trading Corretora', () {
    test('item trading_corretora existe e usa índice dedicado sem colidir com Portal do Colaborador', () {
      final item = MenuConfig.allItems.firstWhere((i) => i.id == 'trading_corretora');

      expect(item.label, equals('Configuração da Corretora'));
      expect(item.screenIndex, equals(129));
      expect(item.screenIndex, isNot(equals(86)), reason: '86 pertence ao Portal do Colaborador');
    });

    test('item trading_corretora pertence ao grupo Bolsa de Valores', () {
      final group = MenuConfig.groupOf('trading_corretora');
      expect(group, isNotNull);
      expect(group!.id, equals('bolsa_valores'));
    });
  });
}
