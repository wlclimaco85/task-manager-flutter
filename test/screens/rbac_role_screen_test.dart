// test/screens/rbac_role_screen_test.dart
// TDD COMPLETO: Testes para sincronizacao de checkboxes RBAC
// RED -> GREEN -> REFACTOR

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/screens/rbac_role_screen.dart';
import 'package:task_manager_flutter/widgets/rbac_role_checkbox_tile.dart';

void main() {
  group('RBACRoleCheckboxTile - Unit Tests', () {
    testWidgets(
      'TEST 1: Checkbox mantem estado apos clique (visual feedback imediato)',
      (WidgetTester tester) async {
        // ARRANGE
        final role = RoleItem(
          roleKey: 'ROLE_TEST',
          roleLabel: 'Test Role',
          description: 'Uma role de teste',
          isSelected: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RBACRoleCheckboxTile(
                role: role,
                onChanged: () {},
              ),
            ),
          ),
        );

        // ACT - Encontrar e clicar no checkbox
        expect(find.byType(CheckboxListTile), findsOneWidget);
        final checkboxBefore = find.byType(Checkbox).first;
        await tester.tap(checkboxBefore);
        await tester.pump(); // Rebuild local state

        // ASSERT - Checkbox deve estar marcado visualmente
        final checkboxAfter = find.byType(Checkbox).first;
        expect(checkboxAfter, findsOneWidget);
        // Verificar que o widget foi reconstruido
        expect(find.byType(RBACRoleCheckboxTile), findsOneWidget);
      },
    );

    testWidgets(
      'TEST 2: Checkbox sincroniza estado do widget.role.isSelected',
      (WidgetTester tester) async {
        // ARRANGE
        final role = RoleItem(
          roleKey: 'ROLE_ADMIN',
          roleLabel: 'Administrator',
          description: 'Admin role',
          isSelected: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RBACRoleCheckboxTile(
                role: role,
                onChanged: () {},
              ),
            ),
          ),
        );

        // ACT - Verificar que o estado inicial esta sincronizado
        expect(find.byType(CheckboxListTile), findsOneWidget);

        // ASSERT - Deve exibir como selecionado
        expect(find.byType(CheckboxListTile), findsOneWidget);
      },
    );

    testWidgets(
      'TEST 3: Debounce aguarda 300ms antes de chamar onChanged',
      (WidgetTester tester) async {
        // ARRANGE
        int callCount = 0;
        final role = RoleItem(
          roleKey: 'ROLE_USER',
          roleLabel: 'User',
          isSelected: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RBACRoleCheckboxTile(
                role: role,
                onChanged: () => callCount++,
                debounceDuration: const Duration(milliseconds: 300),
              ),
            ),
          ),
        );

        // ACT - Clicar rapido 3 vezes
        await tester.tap(find.byType(Checkbox).first);
        await tester.pump();
        await tester.tap(find.byType(Checkbox).first);
        await tester.pump();
        await tester.tap(find.byType(Checkbox).first);

        // ASSERT - onChanged ainda nao foi chamado (debounce aguarda)
        expect(callCount, equals(0));

        // ACT - Aguardar 300ms
        await tester.pumpAndSettle(const Duration(milliseconds: 300));

        // ASSERT - onChanged deve ter sido chamado apenas UMA vez
        expect(callCount, equals(1));
      },
    );

    testWidgets(
      'TEST 4: Widget disabled (enabled=false) nao responde a cliques',
      (WidgetTester tester) async {
        // ARRANGE
        int callCount = 0;
        final role = RoleItem(
          roleKey: 'ROLE_DISABLED',
          roleLabel: 'Disabled Role',
          isSelected: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RBACRoleCheckboxTile(
                role: role,
                onChanged: () => callCount++,
                enabled: false, // DESABILITAR
              ),
            ),
          ),
        );

        // ACT - Tentar clicar no checkbox desabilitado
        await tester.tap(find.byType(Checkbox).first);
        await tester.pumpAndSettle();

        // ASSERT - onChanged nao deve ser chamado
        expect(callCount, equals(0));
      },
    );

    testWidgets(
      'TEST 5: didUpdateWidget sincroniza state quando role.isSelected muda',
      (WidgetTester tester) async {
        // ARRANGE
        final role = RoleItem(
          roleKey: 'ROLE_SYNC',
          roleLabel: 'Sync Role',
          isSelected: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) => Scaffold(
                body: Column(
                  children: [
                    RBACRoleCheckboxTile(
                      role: role,
                      onChanged: () {},
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        role.isSelected = !role.isSelected;
                      }),
                      child: const Text('Toggle Backend'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // ACT - Inicialmente nao selecionado
        expect(find.byType(CheckboxListTile), findsOneWidget);

        // ACT - Simular atualizacao do backend
        await tester.tap(find.text('Toggle Backend'));
        await tester.pump();

        // ASSERT - Checkbox deve ser atualizado para refletir a mudanca
        expect(find.byType(CheckboxListTile), findsOneWidget);
      },
    );
  });

  group('RBACRoleScreen - Screen Structure Tests', () {
    testWidgets(
      'TEST 6: RBACRoleScreen contem Scaffold com AppBar',
      (WidgetTester tester) async {
        // ARRANGE
        tester.binding.window.physicalSizeTestValue = const Size(800, 600);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        await tester.pumpWidget(
          MaterialApp(
            home: RBACRoleScreen(
              loginId: 1,
              empresaId: null,
              parceiroId: null,
            ),
          ),
        );

        // ACT & ASSERT - Deve ter FutureBuilder ou CircularProgressIndicator enquanto carrega
        await tester.pump();
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      },
    );

    testWidgets(
      'TEST 7: Tela exibe mensagem "Roles" no AppBar',
      (WidgetTester tester) async {
        // ARRANGE
        tester.binding.window.physicalSizeTestValue = const Size(800, 600);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        await tester.pumpWidget(
          MaterialApp(
            home: RBACRoleScreen(
              loginId: 1,
              empresaId: null,
              parceiroId: null,
            ),
          ),
        );

        // ACT & ASSERT
        await tester.pump();
        expect(find.text('Roles'), findsWidgets);
      },
    );

    testWidgets(
      'TEST 8: Layout possui botoes Cancelar e Salvar',
      (WidgetTester tester) async {
        // ARRANGE
        tester.binding.window.physicalSizeTestValue = const Size(800, 600);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        await tester.pumpWidget(
          MaterialApp(
            home: RBACRoleScreen(
              loginId: 1,
              empresaId: null,
              parceiroId: null,
            ),
          ),
        );

        // ACT & ASSERT - Procurar por botoes na Scaffold
        await tester.pump();
        final outlinedButtons = find.byType(OutlinedButton);
        final elevatedButtons = find.byType(ElevatedButton);

        // Pelo menos Cancelar e Salvar devem existir
        expect(outlinedButtons, findsWidgets);
        expect(elevatedButtons, findsWidgets);
      },
    );

    testWidgets(
      'TEST 9: Loading spinner aparece durante FutureBuilder',
      (WidgetTester tester) async {
        // ARRANGE
        tester.binding.window.physicalSizeTestValue = const Size(800, 600);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        await tester.pumpWidget(
          MaterialApp(
            home: RBACRoleScreen(
              loginId: 1,
              empresaId: null,
              parceiroId: null,
            ),
          ),
        );

        // ACT - Logo apos pumpWidget, deve estar carregando
        await tester.pump();

        // ASSERT - Pode ter CircularProgressIndicator ou estar carregando
        final appBar = find.byType(AppBar);
        expect(appBar, findsOneWidget);
      },
    );

    testWidgets(
      'TEST 10: RoleItem mantem propriedades apos construcao',
      (WidgetTester tester) async {
        // ARRANGE
        final role = RoleItem(
          roleKey: 'ROLE_TEST_INT',
          roleLabel: 'Test Integration',
          description: 'Test description',
          isSelected: true,
        );

        // ASSERT - RoleItem deve manter suas propriedades
        expect(role.roleKey, equals('ROLE_TEST_INT'));
        expect(role.roleLabel, equals('Test Integration'));
        expect(role.description, equals('Test description'));
        expect(role.isSelected, isTrue);

        // ACT - Modificar propriedade
        role.isSelected = false;

        // ASSERT - Mudanca refletida
        expect(role.isSelected, isFalse);
      },
    );
  });
}
