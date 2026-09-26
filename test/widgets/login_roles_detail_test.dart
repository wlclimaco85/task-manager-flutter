import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/aplicativo_model.dart';
import 'package:task_manager_flutter/models/role_model.dart';
import 'package:task_manager_flutter/widgets/login_roles_detail.dart';

void main() {
  testWidgets('exibe dados reais da role e abre a lista para vincular',
      (tester) async {
    final vinculada = Role(
      id: 7,
      description: 'Cliente',
      key: 'ROLE_CLIENTE',
      aplicativo: Aplicativo(id: 3, nome: 'APP_ACADEMIA'),
    );
    final disponivel = Role(
      id: 8,
      description: 'Administrador',
      key: 'ROLE_ADMIN',
      aplicativo: Aplicativo(id: 3, nome: 'APP_ACADEMIA'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1100,
            height: 700,
            child: LoginRoleesDetail(
              loginId: 42,
              carregarRolees: () async => [vinculada, disponivel],
              carregarRoleesDoLogin: (_) async => [vinculada],
              vincularRole: (_, __) async => true,
              desvincularRole: (_, __) async => true,
              salvarRolees: (_, __) async => true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cliente'), findsOneWidget);
    expect(find.text('APP_ACADEMIA'), findsOneWidget);
    expect(find.text('ROLE_CLIENTE'), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn-vincular-rolees')));
    await tester.pumpAndSettle();

    expect(find.text('Administrador'), findsOneWidget);
    expect(find.text('APP_ACADEMIA | ROLE_ADMIN'), findsOneWidget);
    expect(find.text('APP_ACADEMIA'), findsWidgets);
  });
}
