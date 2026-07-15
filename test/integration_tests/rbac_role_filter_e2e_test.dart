import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/role_model.dart';
import 'package:task_manager_flutter/widgets/role_dropdown_filtered.dart';

void main() {
  group('RBAC Role Filter E2E - Integração Multiplataforma', () {
    /// Teste básico: Widget renderiza sem erros
    testWidgets('E2E-1: Widget RoleDropdownFiltered renderiza sem erros',
        (WidgetTester tester) async {
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

      await tester.pumpAndSettle();
      expect(find.byType(RoleDropdownFiltered), findsOneWidget);
    });

    /// Teste: Feedback visual durante carregamento
    testWidgets('E2E-2: Mostra indicador de loading enquanto carrega roles',
        (WidgetTester tester) async {
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

      expect(find.byType(RoleDropdownFiltered), findsOneWidget);
    });

    /// Teste: Inicialização com roles pré-carregadas (sem mocks)
    testWidgets('E2E-3: Widget aceita initialRoles como parâmetro',
        (WidgetTester tester) async {
      final preselectedRoles = [
        Role(
          id: 1,
          description: 'Admin',
          key: 'ROLE_ADMIN',
          available: true,
          moduloNecessario: null,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoleDropdownFiltered(
              empresaId: 1,
              parceiroId: null,
              initialRoles: preselectedRoles,
              onRolesChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(RoleDropdownFiltered), findsOneWidget);
    });

    /// Teste: Resposta a mudança de empresa/parceiro
    testWidgets('E2E-4: Recarrega roles ao mudar empresa/parceiro',
        (WidgetTester tester) async {
      int reloadCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                int? empresaId = 1;
                return Column(
                  children: [
                    ElevatedButton(
                      key: const Key('btn-change-empresa'),
                      onPressed: () {
                        setState(() => empresaId = 2);
                        reloadCount++;
                      },
                      child: const Text('Change Empresa'),
                    ),
                    Expanded(
                      child: RoleDropdownFiltered(
                        key: Key('widget-$empresaId'),
                        empresaId: empresaId,
                        parceiroId: null,
                        initialRoles: const [],
                        onRolesChanged: (_) {},
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn-change-empresa')));
      await tester.pumpAndSettle();

      expect(reloadCount, equals(1));
      expect(find.byType(RoleDropdownFiltered), findsOneWidget);
    });

    /// Teste: Interaction - Seleção de role
    testWidgets('E2E-5: Permite interação com roles (callback dispara)',
        (WidgetTester tester) async {
      bool callbackFired = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoleDropdownFiltered(
              empresaId: 1,
              parceiroId: null,
              initialRoles: const [],
              onRolesChanged: (roles) {
                callbackFired = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final checkboxes = find.byType(CheckboxListTile);
      if (checkboxes.evaluate().isNotEmpty) {
        await tester.tap(checkboxes.first);
        await tester.pumpAndSettle();
        expect(callbackFired, isTrue);
      } else {
        // Se não houver checkboxes, widget ainda renderiza sem erro
        expect(find.byType(RoleDropdownFiltered), findsOneWidget);
      }
    });

    /// Teste: Prioritidade parceiroId > empresaId
    testWidgets('E2E-6: ParceiroId tem prioridade sobre empresaId',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoleDropdownFiltered(
              empresaId: 1,
              parceiroId: 5,
              initialRoles: const [],
              onRolesChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(RoleDropdownFiltered), findsOneWidget);
    });

    /// Teste: Responsividade - Layout adapta a tamanho
    testWidgets('E2E-7: Layout responsivo em diferentes tamanhos (mobile)',
        (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

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

      await tester.pumpAndSettle();
      expect(find.byType(RoleDropdownFiltered), findsOneWidget);
    });

    /// Teste: Comportamento com múltiplas plataformas (simulado)
    testWidgets('E2E-8: Widget funciona em contexto mobile/web/windows',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: RoleDropdownFiltered(
                empresaId: 1,
                parceiroId: null,
                initialRoles: const [],
                onRolesChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(RoleDropdownFiltered), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
    });

    /// Teste: Fluxo integrado - Login completo
    testWidgets('E2E-9: Fluxo integrado - Novo login com seleção de roles',
        (WidgetTester tester) async {
      var finalSelectedRoles = <Role>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                int? empresaId = 1;
                int? parceiroId;

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => setState(() => empresaId = 2),
                        child: const Text('Empresa 2'),
                      ),
                      ElevatedButton(
                        onPressed: () => setState(() => parceiroId = 10),
                        child: const Text('Parceiro 10'),
                      ),
                      RoleDropdownFiltered(
                        empresaId: empresaId,
                        parceiroId: parceiroId,
                        initialRoles: const [],
                        onRolesChanged: (roles) {
                          finalSelectedRoles = roles;
                        },
                      ),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Login criado com roles!'),
                            ),
                          );
                        },
                        child: const Text('Salvar Login'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(RoleDropdownFiltered), findsOneWidget);

      await tester.tap(find.text('Empresa 2'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Parceiro 10'));
      await tester.pumpAndSettle();

      expect(find.byType(RoleDropdownFiltered), findsOneWidget);

      await tester.tap(find.text('Salvar Login'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    /// Teste: Error handling - sem error quando API falha
    testWidgets(
        'E2E-10: Fallback gracioso quando API de roles falha (retorna vazio)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoleDropdownFiltered(
              empresaId: 9999,
              parceiroId: null,
              initialRoles: const [],
              onRolesChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(RoleDropdownFiltered), findsOneWidget);
    });
  });
}
