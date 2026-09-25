import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/generic_grid_windows_screen.dart';

void main() {
  group('GenericGridWindowsScreen - Renderizacao de multiselect/roles na grid', () {
    testWidgets('Usuario com 1 role renderiza apenas o chip daquela role sem badge extra',
        (tester) async {
      final items = [
        {
          'id': 975,
          'email': 'wlclimacooooo@gmail.com',
          'roles': [
            {'id': 96, 'description': 'Cliente', 'key': 'ROLE_CLIENTE'}
          ],
        }
      ];

      final fieldConfigs = [
        const FieldConfigWindows(
          label: 'Id',
          fieldName: 'id',
          icon: Icons.tag,
          isInGrid: true,
          isInForm: false,
        ),
        const FieldConfigWindows(
          label: 'Email',
          fieldName: 'email',
          icon: Icons.email,
          isInGrid: true,
          isInForm: true,
        ),
        const FieldConfigWindows(
          label: 'Roles',
          fieldName: 'roles',
          icon: Icons.security,
          fieldType: FieldType.multiselect,
          isInGrid: true,
          isInForm: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenericGridScreen<Map<String, dynamic>>(
              title: 'Logins',
              fetchEndpoint: 'http://dummy/api/login',
              createEndpoint: 'http://dummy/api/login',
              updateEndpoint: 'http://dummy/api/login',
              deleteEndpoint: 'http://dummy/api/login',
              fromJson: (json) => json,
              toJson: (item) => item,
              hasPermission: (_) => true,
              FieldConfigWindowss: fieldConfigs,
              idFieldName: 'id',
            ),
          ),
        ),
      );

      // Injeta os dados diretamente no estado do GenericGridScreen
      final state = tester.state<GenericGridScreenState<Map<String, dynamic>>>(
        find.byType(GenericGridScreen<Map<String, dynamic>>),
      );
      state.setState(() {
        state.items = items;
        state.filtered = items;
        state.isLoading = false;
      });
      await tester.pumpAndSettle();

      // Verifica que o chip "Cliente" foi renderizado
      expect(find.text('Cliente'), findsOneWidget);

      // Verifica que NÃO há badge de "+N" (ex: +1, +2)
      expect(find.textContaining('+'), findsNothing);

      // Verifica que não foi renderizado nenhuma role que o usuário não possui
      expect(find.text('Gerente - Acesso gerencial'), findsNothing);
      expect(find.text('Fiscal - NFC-e e obrigações fiscais'), findsNothing);
    });

    testWidgets('Usuario com multiplas roles (ex: 25) exibe primeiro chip, badge +24 e ClipRect',
        (tester) async {
      final roles25 = List.generate(
        25,
        (i) => {'id': i + 1, 'description': 'Role $i', 'key': 'ROLE_$i'},
      );

      final items = [
        {
          'id': 814,
          'email': 'admin@appacademia.local',
          'roles': roles25,
        }
      ];

      final fieldConfigs = [
        const FieldConfigWindows(
          label: 'Id',
          fieldName: 'id',
          icon: Icons.tag,
          isInGrid: true,
          isInForm: false,
        ),
        const FieldConfigWindows(
          label: 'Roles',
          fieldName: 'roles',
          icon: Icons.security,
          fieldType: FieldType.multiselect,
          isInGrid: true,
          isInForm: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenericGridScreen<Map<String, dynamic>>(
              title: 'Logins',
              fetchEndpoint: 'http://dummy/api/login',
              createEndpoint: 'http://dummy/api/login',
              updateEndpoint: 'http://dummy/api/login',
              deleteEndpoint: 'http://dummy/api/login',
              fromJson: (json) => json,
              toJson: (item) => item,
              hasPermission: (_) => true,
              FieldConfigWindowss: fieldConfigs,
              idFieldName: 'id',
            ),
          ),
        ),
      );

      final state = tester.state<GenericGridScreenState<Map<String, dynamic>>>(
        find.byType(GenericGridScreen<Map<String, dynamic>>),
      );
      state.setState(() {
        state.items = items;
        state.filtered = items;
        state.isLoading = false;
      });
      await tester.pumpAndSettle();

      // Primeiro chip visível
      expect(find.text('Role 0'), findsOneWidget);

      // Badge +24 visível
      expect(find.text('+24'), findsOneWidget);

      // Verifica que ClipRect está presente protegendo a célula contra overflow vertical
      expect(find.byType(ClipRect), findsWidgets);
    });
  });
}
