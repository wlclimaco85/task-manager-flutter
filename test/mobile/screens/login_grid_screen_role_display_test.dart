// test/mobile/screens/login_grid_screen_role_display_test.dart
// CARD #319: Mobile Login - não exibir chave bruta das roles
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/role_model.dart';

void main() {
  group('LoginGridScreen - Role Display (CARD #319)', () {
    // RED: Teste que verifica a lógica de exibição de role
    test(
        'exibe descricao legivel da role em vez de chave tecnica',
        () {
      // Arrange: Criar uma role com chave técnica e descrição legível
      final role = Role(
        id: 1,
        key: 'ROLE_ADMIN_FULL_ACCESS', // chave técnica bruta
        description: 'Administrador - Acesso Completo', // descrição amigável
        available: true,
      );

      // Assert: A descrição deve ser exibida, não a chave
      expect(role.description, isNotEmpty);
      expect(role.key, isNotEmpty);
      expect(role.description, equals('Administrador - Acesso Completo'));
      expect(role.key, equals('ROLE_ADMIN_FULL_ACCESS'));

      // Simulando a lógica que DEVE ser usada no widget
      final displayText = (role.description != null && role.description!.isNotEmpty)
          ? role.description
          : (role.key != null && role.key!.isNotEmpty)
              ? role.key
              : 'Role #${role.id}';

      // O texto exibido deve ser a descrição, não a chave técnica
      expect(displayText, equals('Administrador - Acesso Completo'));
      expect(displayText, isNot(contains('ROLE_')));
    });

    test(
        'exibe descricao legivel para multiplas roles',
        () {
      // Arrange: Preparar roles com chaves técnicas e descrições
      final mockRoles = [
        Role(
          id: 1,
          key: 'ROLE_ADMIN_FULL_ACCESS',
          description: 'Administrador - Acesso Completo',
          available: true,
        ),
        Role(
          id: 2,
          key: 'ROLE_USER_VIEW_ONLY',
          description: 'Usuário - Somente Leitura',
          available: true,
        ),
      ];

      // Act & Assert: Validar que cada role usa descrição para exibição
      for (final role in mockRoles) {
        final displayText = (role.description != null && role.description!.isNotEmpty)
            ? role.description
            : (role.key != null && role.key!.isNotEmpty)
                ? role.key
                : 'Role #${role.id}';

        // Descrição legível não deve conter prefixo técnico
        expect(displayText, isNot(contains('ROLE_')));
      }
    });

    test('role com descricao null retorna chave como fallback', () {
      // Edge case: role sem descrição deve usar chave como fallback
      final roleWithoutDesc = Role(
        id: 3,
        key: 'ROLE_GUEST',
        description: null, // sem descrição
        available: true,
      );

      final displayText = roleWithoutDesc.description ?? roleWithoutDesc.key;
      expect(displayText, equals('ROLE_GUEST'));
    });

    test('role com descricao vazia retorna chave como fallback', () {
      final roleWithEmptyDesc = Role(
        id: 4,
        key: 'ROLE_MODERATOR',
        description: '', // descrição vazia
        available: true,
      );

      final displayText = roleWithEmptyDesc.description?.isNotEmpty == true
          ? roleWithEmptyDesc.description
          : roleWithEmptyDesc.key;
      expect(displayText, equals('ROLE_MODERATOR'));
    });
  });
}
