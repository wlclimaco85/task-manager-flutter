import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/menu_config.dart';

void main() {
  group('MenuConfig', () {
    test('allItems contém todos os itens dos grupos e os itens soltos', () {
      final allItems = MenuConfig.allItems;
      expect(allItems, isNotEmpty);
      expect(allItems.any((item) => item.id == 'chat'), isTrue);
      expect(allItems.any((item) => item.id == 'dashboard'), isTrue);
      expect(allItems.map((item) => item.id).toSet().length,
          equals(allItems.length),
          reason: 'Todos os IDs de item devem ser únicos');
    });

    test('search retorna resultados case-insensitive e ordenados', () {
      final results = MenuConfig.search('com');
      expect(results, isNotEmpty);
      expect(results.every((item) => item.label.toLowerCase().contains('com')),
          isTrue);
      for (var i = 1; i < results.length; i++) {
        expect(results[i - 1].label.compareTo(results[i].label) <= 0, isTrue);
      }
    });

    test('search retorna lista vazia quando query é somente espaços', () {
      expect(MenuConfig.search('   '), isEmpty);
    });

    test('groupOf retorna o grupo correto para um item existente', () {
      final group = MenuConfig.groupOf('chamados');
      expect(group, isNotNull);
      expect(group?.id, equals('suporte_comunicacao'));
    });

    test('groupOf retorna null para item inexistente', () {
      expect(MenuConfig.groupOf('nao_existe'), isNull);
    });
  });
}
