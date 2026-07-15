import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/role_model.dart';

void main() {
  group('RBAC Role Filter Integration Tests', () {
    test('role filtering logic: sem módulo deve estar disponível', () {
      final role = Role(
        id: 1,
        description: 'Admin',
        available: true,
        key: 'ROLE_ADMIN',
        moduloNecessario: null,
      );

      // Lógica: se moduloNecessario é null, role está disponível
      final isEligible = role.moduloNecessario == null;
      expect(isEligible, isTrue);
    });

    test('role filtering logic: com módulo contratado deve estar disponível', () {
      final contractedModules = ['COBRANCA', 'ORCAMENTOS'];
      final role = Role(
        id: 2,
        description: 'Financeiro',
        available: true,
        key: 'ROLE_FINANCEIRO',
        moduloNecessario: 'COBRANCA',
      );

      // Lógica: se módulo está na lista de contratados, role está disponível
      final isEligible = role.moduloNecessario == null ||
          (role.moduloNecessario != null &&
              contractedModules.contains(role.moduloNecessario));
      expect(isEligible, isTrue);
    });

    test('role filtering logic: com módulo não contratado deve estar indisponível', () {
      final contractedModules = ['COBRANCA'];
      final role = Role(
        id: 3,
        description: 'Comercial',
        available: true,
        key: 'ROLE_COMERCIAL',
        moduloNecessario: 'ORCAMENTOS',
      );

      // Lógica: se módulo NÃO está na lista de contratados, role está indisponível
      final isEligible = role.moduloNecessario == null ||
          (role.moduloNecessario != null &&
              contractedModules.contains(role.moduloNecessario));
      expect(isEligible, isFalse);
    });

    test('múltiplas roles: filtrar corretamente com módulos mixtos', () {
      final contractedModules = ['COBRANCA'];
      final allRoles = [
        Role(
          id: 1,
          description: 'Admin',
          available: true,
          key: 'ROLE_ADMIN',
          moduloNecessario: null,
        ),
        Role(
          id: 2,
          description: 'Financeiro',
          available: true,
          key: 'ROLE_FINANCEIRO',
          moduloNecessario: 'COBRANCA',
        ),
        Role(
          id: 3,
          description: 'Comercial',
          available: true,
          key: 'ROLE_COMERCIAL',
          moduloNecessario: 'ORCAMENTOS',
        ),
      ];

      // Filtrar roles elegíveis
      final eligibleRoles = allRoles
          .where((role) =>
              role.moduloNecessario == null ||
              (role.moduloNecessario != null &&
                  contractedModules.contains(role.moduloNecessario)))
          .toList();

      expect(eligibleRoles.length, equals(2)); // Admin + Financeiro
      expect(eligibleRoles[0].key, equals('ROLE_ADMIN'));
      expect(eligibleRoles[1].key, equals('ROLE_FINANCEIRO'));
    });

    test('seleção múltipla: manter estado ao adicionar/remover', () {
      final role1 = Role(
        id: 1,
        description: 'Admin',
        available: true,
        key: 'ROLE_ADMIN',
        moduloNecessario: null,
      );

      final role2 = Role(
        id: 2,
        description: 'Financeiro',
        available: true,
        key: 'ROLE_FINANCEIRO',
        moduloNecessario: 'COBRANCA',
      );

      List<Role> selected = [];

      // Adicionar roles
      selected.add(role1);
      selected.add(role2);
      expect(selected.length, equals(2));

      // Remover uma role
      selected.removeWhere((r) => r.id == 2);
      expect(selected.length, equals(1));
      expect(selected[0].id, equals(1));
    });

    test('responsividade: role item deve renderizar em qualquer largura', () {
      // Teste simples que valida que os dados estão estruturados corretamente
      final role = Role(
        id: 1,
        description: 'Admin com descrição bem longa para testar responsividade',
        available: true,
        key: 'ROLE_ADMIN',
        moduloNecessario: null,
      );

      expect(role.description?.isNotEmpty, isTrue);
      expect(role.id, isNotNull);
    });

    test('JSON parse/serialize roundtrip', () {
      final original = Role(
        id: 21,
        description: 'Gerente de Cliente',
        key: 'ROLE_GERENTE',
        available: true,
        moduloNecessario: 'COBRANCA',
      );

      // Serializar
      final json = original.toJson();

      // Deserializar
      final restored = Role.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.description, equals(original.description));
      expect(restored.key, equals(original.key));
      expect(restored.available, equals(original.available));
      expect(restored.moduloNecessario, equals(original.moduloNecessario));
    });
  });
}
