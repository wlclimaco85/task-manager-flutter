import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/telas_model.dart';
import 'package:task_manager_flutter/widgets/generic_detail_form_screen.dart';

void main() {
  TelaConfig buildMockTela() {
    return TelaConfig(
      id: 1,
      nome: 'parceiro',
      titulo: 'Parceiro',
      fetchEndpoint: '/api/parceiro',
      createEndpoint: '/api/parceiro/insert',
      updateEndpoint: '/api/parceiro/update',
      deleteEndpoint: '/api/parceiro/:id',
      fields: [
        TelaField(
          label: 'Cep',
          fieldName: 'cep',
          fieldType: TelaFieldType.cep,
          isInForm: true,
        ),
        TelaField(
          label: 'Estado',
          fieldName: 'estado',
          fieldType: TelaFieldType.text,
          isInForm: true,
        ),
        TelaField(
          label: 'Cidade',
          fieldName: 'cidade',
          fieldType: TelaFieldType.text,
          isInForm: true,
        ),
        TelaField(
          label: 'Bairro',
          fieldName: 'bairro',
          fieldType: TelaFieldType.text,
          isInForm: true,
        ),
        TelaField(
          label: 'Rua',
          fieldName: 'rua',
          fieldType: TelaFieldType.text,
          isInForm: true,
        ),
        TelaField(
          label: 'Complemento',
          fieldName: 'complemento',
          fieldType: TelaFieldType.text,
          isInForm: true,
        ),
      ],
    );
  }

  group('GenericDetailFormScreen - Busca de CEP no Detail de Parceiro/Cadastro', () {
    testWidgets('exibe botao Buscar ao lado do CEP e popula campos de endereco',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      var buscouCep = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenericDetailFormScreen(
              item: const {
                'id': 1805,
                'cep': '',
                'estado': '',
                'cidade': '',
                'bairro': '',
                'rua': '',
                'complemento': '',
              },
              telaNome: 'parceiro',
              hasPermission: (_) => true,
              telaConfig: buildMockTela(),
              onBuscarCep: (cep) async {
                buscouCep = true;
                if (cep == '38061260') {
                  return {
                    'logradouro': 'ORIENTE',
                    'bairro': 'Estados Unidos',
                    'localidade': 'Uberaba',
                    'uf': 'MG',
                    'complemento': 'Sala 10',
                  };
                }
                return {'erro': true};
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verifica que o botão Buscar está presente
      final buscarButton = find.widgetWithText(ElevatedButton, 'Buscar');
      expect(buscarButton, findsOneWidget);

      // O campo CEP é o TextFormField que está na mesma Row do botão Buscar
      final cepField = find.descendant(
        of: find.ancestor(of: buscarButton, matching: find.byType(Row)),
        matching: find.byType(TextFormField),
      );
      expect(cepField, findsOneWidget);

      // Digita o CEP 38061260
      await tester.enterText(cepField, '38061260');
      await tester.pumpAndSettle();

      // Clica no botão Buscar
      await tester.tap(buscarButton);
      await tester.pumpAndSettle();

      expect(buscouCep, isTrue);

      // Verifica se os campos de endereço foram populados automaticamente
      expect(find.text('ORIENTE'), findsOneWidget);
      expect(find.text('Estados Unidos'), findsOneWidget);
      expect(find.text('Uberaba'), findsOneWidget);
      expect(find.text('MG'), findsOneWidget);
      expect(find.text('Sala 10'), findsOneWidget);

      // Verifica se a SnackBar de sucesso apareceu
      expect(find.textContaining('CEP encontrado: ORIENTE, Uberaba'), findsOneWidget);
    });

    testWidgets('exibe erro caso o CEP tenha menos de 8 digitos ao clicar em Buscar',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenericDetailFormScreen(
              item: const {'id': 1805, 'cep': ''},
              telaNome: 'parceiro',
              hasPermission: (_) => true,
              telaConfig: buildMockTela(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final buscarButton = find.widgetWithText(ElevatedButton, 'Buscar');
      expect(buscarButton, findsOneWidget);

      final cepField = find.descendant(
        of: find.ancestor(of: buscarButton, matching: find.byType(Row)),
        matching: find.byType(TextFormField),
      );

      await tester.enterText(cepField, '1234');
      await tester.pumpAndSettle();

      await tester.tap(buscarButton);
      await tester.pumpAndSettle();

      expect(find.text('CEP deve ter 8 dígitos'), findsOneWidget);
    });
  });
}
