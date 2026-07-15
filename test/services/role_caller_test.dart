import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/role_model.dart';

void main() {
  group('RoleCaller - Role Model Integration', () {
    test('deve parsear role com moduloNecessario null', () {
      final json = {
        'id': 21,
        'description': 'Gerente de Cliente',
        'key': 'ROLE_GERENTE',
        'available': true,
        'moduloNecessario': null,
        'aplicativo': {'id': 3, 'nome': 'APP_ACADEMIA'},
      };

      final role = Role.fromJson(json);

      expect(role.id, equals(21));
      expect(role.description, equals('Gerente de Cliente'));
      expect(role.moduloNecessario, isNull);
      expect(role.available, isTrue);
    });

    test('deve parsear role com moduloNecessario definido', () {
      final json = {
        'id': 32,
        'description': 'Financeiro',
        'key': 'ROLE_FINANCEIRO',
        'available': true,
        'moduloNecessario': 'COBRANCA',
        'aplicativo': {'id': 3, 'nome': 'APP_ACADEMIA'},
      };

      final role = Role.fromJson(json);

      expect(role.id, equals(32));
      expect(role.description, equals('Financeiro'));
      expect(role.moduloNecessario, equals('COBRANCA'));
      expect(role.available, isTrue);
    });

    test('deve parsear múltiplas roles com módulos diferentes', () {
      final jsonList = [
        {
          'id': 21,
          'description': 'Gerente',
          'key': 'ROLE_GERENTE',
          'available': true,
          'moduloNecessario': null,
          'aplicativo': {'id': 3, 'nome': 'APP_ACADEMIA'},
        },
        {
          'id': 32,
          'description': 'Financeiro',
          'key': 'ROLE_FINANCEIRO',
          'available': true,
          'moduloNecessario': 'COBRANCA',
          'aplicativo': {'id': 3, 'nome': 'APP_ACADEMIA'},
        },
        {
          'id': 33,
          'description': 'Comercial',
          'key': 'ROLE_COMERCIAL',
          'available': false,
          'moduloNecessario': 'ORCAMENTOS',
          'aplicativo': {'id': 3, 'nome': 'APP_ACADEMIA'},
        },
      ];

      final roles =
          jsonList.map((j) => Role.fromJson(j as Map<String, dynamic>)).toList();

      expect(roles.length, equals(3));
      expect(roles[0].moduloNecessario, isNull);
      expect(roles[1].moduloNecessario, equals('COBRANCA'));
      expect(roles[2].moduloNecessario, equals('ORCAMENTOS'));
    });

    test('role toJson deve incluir moduloNecessario', () {
      final role = Role(
        id: 32,
        description: 'Financeiro',
        available: true,
        key: 'ROLE_FINANCEIRO',
        moduloNecessario: 'COBRANCA',
      );

      final json = role.toJson();

      expect(json['moduloNecessario'], equals('COBRANCA'));
    });

    test('filtrar roles elegíveis (moduloNecessario == null)', () {
      final allRoles = [
        Role(
          id: 21,
          description: 'Gerente',
          key: 'ROLE_GERENTE',
          available: true,
          moduloNecessario: null, // Sempre elegível
        ),
        Role(
          id: 32,
          description: 'Financeiro',
          key: 'ROLE_FINANCEIRO',
          available: true,
          moduloNecessario: 'COBRANCA', // Requer módulo
        ),
      ];

      // Filtro: apenas roles sem moduloNecessario
      final elegibleRoles = allRoles.where((r) => r.moduloNecessario == null).toList();

      expect(elegibleRoles.length, equals(1));
      expect(elegibleRoles.first.id, equals(21));
    });

    test('verificar disponibilidade de role com módulo contratado', () {
      final role = Role(
        id: 32,
        description: 'Financeiro',
        key: 'ROLE_FINANCEIRO',
        available: true,
        moduloNecessario: 'COBRANCA',
      );

      final modulosContratados = ['COBRANCA', 'ORCAMENTOS'];
      final isAvailable = role.moduloNecessario == null ||
                         modulosContratados.contains(role.moduloNecessario);

      expect(isAvailable, isTrue);
    });

    test('verificar indisponibilidade de role sem módulo contratado', () {
      final role = Role(
        id: 33,
        description: 'Comercial',
        key: 'ROLE_COMERCIAL',
        available: true,
        moduloNecessario: 'ORCAMENTOS',
      );

      final modulosContratados = ['COBRANCA']; // Não inclui ORCAMENTOS
      final isAvailable = role.moduloNecessario == null ||
                         modulosContratados.contains(role.moduloNecessario);

      expect(isAvailable, isFalse);
    });
  });
}
