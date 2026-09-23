import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/models/setor_model.dart';
import 'package:task_manager_flutter/mobile/screens/details/login_detail_screen.dart';
import 'package:task_manager_flutter/web/screens/details/login_detail_screen.dart';
import 'package:task_manager_flutter/widgets/generic_detail_form_screen.dart';
import 'package:task_manager_flutter/widgets/login_setores_detail.dart';
import 'package:task_manager_flutter/windows/screens/details/login_detail_screen.dart';

void main() {
  final detalhes = <String, Widget Function(Login)>{
    'web': (login) => WebLoginDetailScreen(
          item: login,
          hasPermission: (_) => true,
        ),
    'windows': (login) => WindowsLoginDetailScreen(
          item: login,
          hasPermission: (_) => true,
        ),
    'mobile': (login) => MobileLoginDetailScreen(
          item: login,
          hasPermission: (_) => true,
        ),
  };

  for (final detalhe in detalhes.entries) {
    testWidgets(
        'detalhe ${detalhe.key} usa seletor de vinculos em vez do CRUD de setor',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: detalhe.value(Login(id: 814, nome: 'Cliente')),
      ));

      final form = tester.widget<GenericDetailFormScreen>(
        find.byType(GenericDetailFormScreen),
      );
      final setores = form.relatedTabs!.singleWhere(
        (tab) => tab.title == 'Setores',
      );
      expect(setores.telaNome, isNull);
      expect(setores.customWidget, isA<LoginSetoresDetail>());

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    });
  }

  testWidgets('setores do login apenas vincula registros existentes',
      (tester) async {
    final vinculados = <int>[];
    final removidos = <int>[];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LoginSetoresDetail(
          loginId: 814,
          carregarSetores: () async => [
            Setor(id: 1, nome: 'Departamento Fiscal'),
            Setor(id: 105, nome: 'Fiscal'),
          ],
          carregarSetoresDoLogin: (_) async => [
            Setor(id: 1, nome: 'Departamento Fiscal'),
          ],
          vincularSetor: (_, setorId) async {
            vinculados.add(setorId);
            return true;
          },
          desvincularSetor: (_, setorId) async {
            removidos.add(setorId);
            return true;
          },
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Departamento Fiscal'), findsOneWidget);
    expect(find.text('Fiscal'), findsOneWidget);
    expect(find.text('Novo'), findsNothing);
    expect(find.text('Salvar vínculos'), findsOneWidget);
    expect(
      tester.widget<CheckboxListTile>(
        find.byKey(const Key('login-setor-1')),
      ).value,
      isTrue,
    );
    expect(
      tester.widget<CheckboxListTile>(
        find.byKey(const Key('login-setor-105')),
      ).value,
      isFalse,
    );

    await tester.tap(find.byKey(const Key('login-setor-1')));
    await tester.tap(find.byKey(const Key('login-setor-105')));
    await tester.pump();
    await tester.tap(find.text('Salvar vínculos'));
    await tester.pumpAndSettle();

    expect(vinculados, [105]);
    expect(removidos, [1]);
  });
}
