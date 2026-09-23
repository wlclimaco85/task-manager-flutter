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
        'detalhe ${detalhe.key} usa grid de setores vinculados sem CRUD novo',
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

  testWidgets('grid de setores exibe vinculados, sem botao novo e com botao vincular',
      (tester) async {
    final todosSetores = [
      Setor(id: 1, nome: 'Departamento Fiscal', responsavel: 'Carlos', ramal: '101'),
      Setor(id: 105, nome: 'Fiscal', responsavel: 'Ana', ramal: '102'),
    ];
    final vinculadosIniciais = [
      Setor(id: 1, nome: 'Departamento Fiscal', responsavel: 'Carlos', ramal: '101'),
    ];

    List<int>? idsSalvos;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LoginSetoresDetail(
          loginId: 814,
          carregarSetores: () async => todosSetores,
          carregarSetoresDoLogin: (_) async => vinculadosIniciais,
          salvarSetores: (_, ids) async {
            idsSalvos = ids;
            return true;
          },
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // 1. Grid exibe setor vinculado
    expect(find.text('Setores vinculados'), findsOneWidget);
    expect(find.text('Departamento Fiscal'), findsOneWidget);
    expect(find.text('Carlos'), findsOneWidget);
    expect(find.text('101'), findsOneWidget);

    // 2. Não possui botão "Novo"
    expect(find.widgetWithText(FilledButton, 'Novo'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Novo'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Novo'), findsNothing);

    // 3. Possui botão "Vincular"
    expect(find.widgetWithText(FilledButton, 'Vincular'), findsOneWidget);

    // 4. Ao clicar em Vincular, abre o modal
    await tester.tap(find.widgetWithText(FilledButton, 'Vincular'));
    await tester.pumpAndSettle();

    expect(find.text('Vincular Setores ao Login'), findsOneWidget);
    expect(find.text('Selecionar todos'), findsOneWidget);
    expect(find.text('Desmarcar todos'), findsOneWidget);
    expect(find.text('Salvar vínculos'), findsOneWidget);

    // Ambos os setores devem estar listados no diálogo
    expect(find.text('Fiscal'), findsOneWidget);

    // Clica em 'Selecionar todos'
    await tester.tap(find.text('Selecionar todos'));
    await tester.pump();

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
      isTrue,
    );

    // Clica em 'Desmarcar todos'
    await tester.tap(find.text('Desmarcar todos'));
    await tester.pump();

    expect(
      tester.widget<CheckboxListTile>(
        find.byKey(const Key('login-setor-1')),
      ).value,
      isFalse,
    );
    expect(
      tester.widget<CheckboxListTile>(
        find.byKey(const Key('login-setor-105')),
      ).value,
      isFalse,
    );

    // Marca o setor 105 manualmente
    await tester.tap(find.byKey(const Key('login-setor-105')));
    await tester.pump();

    // Salva vínculos
    await tester.tap(find.text('Salvar vínculos'));
    await tester.pumpAndSettle();

    expect(idsSalvos, isNotNull);
    expect(idsSalvos, contains(105));
    expect(idsSalvos, isNot(contains(1)));
  });

  testWidgets('desvincular setor diretamente da grid com confirmacao',
      (tester) async {
    final vinculados = [
      Setor(id: 1, nome: 'Departamento Fiscal', responsavel: 'Carlos', ramal: '101'),
    ];
    int? desvinculadoId;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LoginSetoresDetail(
          loginId: 814,
          carregarSetores: () async => vinculados,
          carregarSetoresDoLogin: (_) async => vinculados,
          desvincularSetor: (_, setorId) async {
            desvinculadoId = setorId;
            return true;
          },
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Clica no botão de desvincular da linha
    final iconButton = find.byTooltip('Desvincular setor');
    expect(iconButton, findsOneWidget);
    await tester.tap(iconButton);
    await tester.pumpAndSettle();

    // Abre diálogo de confirmação
    expect(find.text('Desvincular Setor'), findsOneWidget);
    expect(find.text('Desvincular'), findsOneWidget);

    // Confirma desvinculação
    await tester.tap(find.widgetWithText(FilledButton, 'Desvincular'));
    await tester.pumpAndSettle();

    expect(desvinculadoId, equals(1));
  });
}
