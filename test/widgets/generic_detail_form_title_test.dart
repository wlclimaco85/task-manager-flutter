import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/telas_model.dart';
import 'package:task_manager_flutter/widgets/generic_detail_form_screen.dart';
import 'package:task_manager_flutter/widgets/generic_grid_windows_screen.dart';

void main() {
  testWidgets('usa titulo especifico quando o detalhe reutiliza outra tela',
      (tester) async {
    final tela = TelaConfig(
      id: 1,
      nome: 'parceiro',
      titulo: 'Parceiro',
      fetchEndpoint: '/api/parceiro',
      createEndpoint: '/api/parceiro',
      updateEndpoint: '/api/parceiro/:id',
      deleteEndpoint: '/api/parceiro/:id',
      fields: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GenericDetailFormScreen(
          item: const {'id': 1},
          telaNome: 'parceiro',
          titleOverride: 'Fornecedor',
          hasPermission: (_) => true,
          telaConfig: tela,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fornecedor'), findsOneWidget);
    expect(find.text('Parceiro'), findsNothing);
  });

  testWidgets('exibe empresa e tipo recebidos no item do fornecedor',
      (tester) async {
    final tela = TelaConfig(
      id: 1,
      nome: 'parceiro',
      titulo: 'Parceiro',
      fetchEndpoint: '/api/parceiro',
      createEndpoint: '/api/parceiro',
      updateEndpoint: '/api/parceiro/:id',
      deleteEndpoint: '/api/parceiro/:id',
      fields: [
        TelaField(
          label: 'Empresa',
          fieldName: 'empresa',
          fieldType: TelaFieldType.dropdown,
          isInForm: true,
        ),
        TelaField(
          label: 'Tipo Parceiros',
          fieldName: 'tipo_parceiros',
          fieldType: TelaFieldType.multiselect,
          isInForm: true,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GenericDetailFormScreen(
          item: const {
            'id': 1,
            'empresa': {'id': 9, 'nome': 'Empresa Teste'},
            'tiposParceiro': [
              {'id': 2, 'nome': 'Fornecedor'},
            ],
          },
          telaNome: 'parceiro',
          titleOverride: 'Fornecedor',
          hasPermission: (_) => true,
          telaConfig: tela,
          fieldOverrides: const [
            FieldConfigWindows(
              label: 'Empresa',
              fieldName: 'empresa',
              fieldType: FieldType.dropdown,
              dropdownOptions: [
                {'id': 9, 'nome': 'Empresa Teste'},
              ],
              dropdownValueField: 'id',
              dropdownDisplayField: 'nome',
            ),
            FieldConfigWindows(
              label: 'Tipo Parceiros',
              fieldName: 'tipo_parceiros',
              fieldType: FieldType.multiselect,
              dropdownOptions: [
                {'id': 2, 'nome': 'Fornecedor'},
              ],
              dropdownValueField: 'id',
              dropdownDisplayField: 'nome',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Empresa Teste'), findsOneWidget);
    expect(find.text('Fornecedor'), findsNWidgets(2));
  });
}
