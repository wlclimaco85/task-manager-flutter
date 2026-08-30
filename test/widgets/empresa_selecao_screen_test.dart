import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/empresa_acesso_model.dart';
import 'package:task_manager_flutter/widgets/empresa_selecao_screen.dart';

void main() {
  testWidgets('EmpresaSelecaoScreen lista empresas aprovadas e troca empresa',
      (tester) async {
    int? empresaTrocada;

    await tester.pumpWidget(MaterialApp(
      home: EmpresaSelecaoScreen(
        loadAcessos: () async => const [
          EmpresaAcesso(
            empresaId: 1,
            empresaNome: 'Empresa Atual',
            status: 'APROVADO',
            ativa: true,
          ),
          EmpresaAcesso(
            empresaId: 2,
            empresaNome: 'Empresa Nova',
            status: 'APROVADO',
            ativa: false,
          ),
          EmpresaAcesso(
            empresaId: 3,
            empresaNome: 'Empresa Pendente',
            status: 'PENDENTE',
            ativa: false,
          ),
        ],
        trocarEmpresa: (empresaId) async {
          empresaTrocada = empresaId;
          return true;
        },
      ),
    ));

    await tester.pumpAndSettle();

    expect(find.text('Empresa Atual'), findsOneWidget);
    expect(find.text('Empresa Nova'), findsOneWidget);
    expect(find.text('Empresa Pendente'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Usar'));
    await tester.pumpAndSettle();

    expect(empresaTrocada, equals(2));
  });

  testWidgets('EmpresaSelecaoScreen mostra erro quando troca falha',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: EmpresaSelecaoScreen(
        loadAcessos: () async => const [
          EmpresaAcesso(
            empresaId: 2,
            empresaNome: 'Empresa Nova',
            status: 'APROVADO',
            ativa: false,
          ),
        ],
        trocarEmpresa: (_) async => false,
      ),
    ));

    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Usar'));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível trocar a empresa ativa.'), findsOneWidget);
  });
}
