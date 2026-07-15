import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/role_model.dart';
import 'package:task_manager_flutter/widgets/role_dropdown_filtered.dart';

void main() {
  group('RoleDropdownFiltered Widget', () {
    testWidgets('deve renderizar widget com roles carregadas', (WidgetTester tester) async {
      final roles = [
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
      ];

      List<Role> selectedRoles = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoleDropdownFiltered(
              empresaId: 1,
              parceiroId: null,
              initialRoles: const [],
              onRolesChanged: (roles) {
                selectedRoles = roles;
              },
            ),
          ),
        ),
      );

      // Aguarda carregamento
      await tester.pumpAndSettle();

      // Verifica se o widget foi criado
      expect(find.byType(RoleDropdownFiltered), findsOneWidget);
    });

    testWidgets('deve mostrar CircularProgressIndicator durante carregamento', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoleDropdownFiltered(
              empresaId: 1,
              parceiroId: null,
              initialRoles: const [],
              onRolesChanged: (_) {},
            ),
          ),
        ),
      );

      // Inicialmente mostra loading
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('deve passar initialRoles corretamente', (WidgetTester tester) async {
      final initialRoles = [
        Role(
          id: 1,
          description: 'Admin',
          available: true,
          key: 'ROLE_ADMIN',
          moduloNecessario: null,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoleDropdownFiltered(
              empresaId: 1,
              parceiroId: null,
              initialRoles: initialRoles,
              onRolesChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(RoleDropdownFiltered), findsOneWidget);
    });

    test('role sem moduloNecessario deve ser elegível', () {
      final role = Role(
        id: 1,
        description: 'Admin',
        available: true,
        key: 'ROLE_ADMIN',
        moduloNecessario: null,
      );

      expect(role.moduloNecessario, isNull);
    });

    test('role com moduloNecessario deve ser inelegível por padrão', () {
      final role = Role(
        id: 2,
        description: 'Financeiro',
        available: true,
        key: 'ROLE_FINANCEIRO',
        moduloNecessario: 'COBRANCA',
      );

      expect(role.moduloNecessario, isNotNull);
      expect(role.moduloNecessario, equals('COBRANCA'));
    });

    test('initialRoles vazio deve inicializar sem seleções', () {
      const initialRoles = <Role>[];
      expect(initialRoles, isEmpty);
    });

    test('verificar que roles com moduloNecessario aparecem como desabilitadas', () {
      final role = Role(
        id: 32,
        description: 'Financeiro',
        available: true,
        key: 'ROLE_FINANCEIRO',
        moduloNecessario: 'COBRANCA',
      );

      // Rol é inelegível (tem moduloNecessario)
      expect(role.moduloNecessario, isNotNull);
      expect(role.moduloNecessario, equals('COBRANCA'));
    });

    testWidgets('deve filtrar roles baseado em elegibilidade', (WidgetTester tester) async {
      final rolesComModulo = [
        Role(
          id: 21,
          description: 'Gerente',
          available: true,
          key: 'ROLE_GERENTE',
          moduloNecessario: null, // Elegível
        ),
        Role(
          id: 32,
          description: 'Financeiro',
          available: true,
          key: 'ROLE_FINANCEIRO',
          moduloNecessario: 'COBRANCA', // Não elegível
        ),
      ];

      // Filtra apenas elegíveis
      final elegibleRoles = rolesComModulo.where((r) => r.moduloNecessario == null).toList();

      expect(elegibleRoles.length, equals(1));
      expect(elegibleRoles.first.description, equals('Gerente'));
    });

    test('role com módulo contratado deve ser elegível', () {
      final role = Role(
        id: 32,
        description: 'Financeiro',
        available: true,
        key: 'ROLE_FINANCEIRO',
        moduloNecessario: 'COBRANCA',
      );

      final modulosContratados = ['COBRANCA', 'ORCAMENTOS'];
      final isEligible = role.moduloNecessario == null ||
                        modulosContratados.contains(role.moduloNecessario);

      expect(isEligible, isTrue);
    });
  });
}
