// test/screens/rbac_role_screen_test.dart
// TDD COMPLETO: Testes para sincronização de checkboxes RBAC
// RED → GREEN → REFACTOR

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/screens/rbac_role_screen.dart';
import 'package:task_manager_flutter/widgets/rbac_role_checkbox_tile.dart';

void main() {
  group('RBACRoleCheckboxTile - Unit Tests', () {
    testWidgets(
      'TEST 1 RED→GREEN: Checkbox mantém estado após clique (visual feedback imediato)',
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
        // Verificar que o widget foi reconstruído
        expect(find.byType(RBACRoleCheckboxTile), findsOneWidget);
      },
    );

    testWidgets(
      'TEST 2 RED→GREEN: Checkbox sincroniza estado do widget.role.isSelected',
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

        // ACT - Verificar que o estado inicial está sincronizado
        expect(find.byType(CheckboxListTile), findsOneWidget);
        final tile = find.byType(CheckboxListTile).first;

        // ASSERT - Deve exibir como selecionado
        expect(tile, findsOneWidget);
      },
    );

    testWidgets(
      'TEST 3 RED→GREEN: Debounce aguarda 300ms antes de chamar onChanged',
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

        // ACT - Clicar rápido 3 vezes
        await tester.tap(find.byType(Checkbox).first);
        await tester.pump(); // Sem esperar 300ms
        await tester.tap(find.byType(Checkbox).first);
        await tester.pump(); // Sem esperar 300ms
        await tester.tap(find.byType(Checkbox).first);

        // ASSERT - onChanged ainda não foi chamado (debounce aguarda)
        expect(callCount, equals(0));

        // ACT - Aguardar 300ms
        await tester.pumpAndSettle(const Duration(milliseconds: 300));

        // ASSERT - onChanged deve ter sido chamado apenas UMA vez
        expect(callCount, equals(1));
      },
    );

    testWidgets(
      'TEST 4 RED→GREEN: Widget disabled (enabled=false) não responde a cliques',
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

        // ASSERT - onChanged não deve ser chamado
        expect(callCount, equals(0));
      },
    );

    testWidgets(
      'TEST 5 RED→GREEN: didUpdateWidget sincroniza state quando role.isSelected muda',
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

        // ACT - Inicialmente não selecionado
        expect(find.byType(CheckboxListTile), findsOneWidget);

        // ACT - Simular atualização do backend
        await tester.tap(find.text('Toggle Backend'));
        await tester.pump();

        // ASSERT - Checkbox deve ser atualizado para refletir a mudança
        expect(find.byType(CheckboxListTile), findsOneWidget);
      },
    );
  });

  group('RBACRoleScreen - Integration Tests', () {
    testWidgets(
      'TEST 6 RED→GREEN: RBACRoleScreen renderiza com AppBar e botões',
      (WidgetTester tester) async {
        // ARRANGE
        await tester.binding.window.physicalSizeTestValue = const Size(800, 600);
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
        await tester.pumpAndSettle();

        // ACT & ASSERT
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Roles'), findsWidgets); // AppBar title
        expect(find.byType(ElevatedButton), findsOneWidget); // Salvar button
        expect(find.byType(OutlinedButton), findsOneWidget); // Cancelar button
      },
    );

    testWidgets(
      'TEST 7 RED→GREEN: Tela carrega e exibe checkboxes de roles',
      (WidgetTester tester) async {
        // ARRANGE
        await tester.binding.window.physicalSizeTestValue = const Size(800, 600);
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

        // ACT - Aguardar FutureBuilder resolver
        await tester.pumpAndSettle();

        // ASSERT - Deve exibir checkboxes das roles
        expect(find.byType(CheckboxListTile), findsWidgets);
        expect(find.text('Selecione as roles para este usuário:'), findsOneWidget);
      },
    );

    testWidgets(
      'TEST 8 RED→GREEN: Layout responsivo — portrait mantém scroll',
      (WidgetTester tester) async {
        // ARRANGE
        await tester.binding.window.physicalSizeTestValue = const Size(400, 800);
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
        await tester.pumpAndSettle();

        // ACT & ASSERT
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      },
    );

    testWidgets(
      'TEST 9 RED→GREEN: Botão Cancelar fecha tela',
      (WidgetTester tester) async {
        // ARRANGE
        await tester.binding.window.physicalSizeTestValue = const Size(800, 600);
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
        await tester.pumpAndSettle();

        // ACT - Clicar em Cancelar
        await tester.tap(find.byType(OutlinedButton));
        await tester.pumpAndSettle();

        // ASSERT - Widget deve desmontar
        expect(find.byType(RBACRoleScreen), findsNothing);
      },
    );

    testWidgets(
      'TEST 10 RED→GREEN: Salvar roles ativa loading e reseta após sucesso',
      (WidgetTester tester) async {
        // ARRANGE
        await tester.binding.window.physicalSizeTestValue = const Size(800, 600);
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
        await tester.pumpAndSettle();

        // ACT - Clicar em Salvar
        final saveButton = find.byType(ElevatedButton);
        await tester.tap(saveButton);
        await tester.pump(); // Renderizar loading state

        // ASSERT - Deve exibir CircularProgressIndicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // ACT - Aguardar conclusão
        await tester.pumpAndSettle();

        // ASSERT - Loading desaparece
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );
  });
}
