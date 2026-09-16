import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/dropdown_helpers.dart';
import 'package:task_manager_flutter/web/screens/details/nfse_detail_screen.dart';

void main() {
  testWidgets('Web: cria item de servico com campo Produto (Servico)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
        home: NfseDetailScreen(item: const {'id': 501, 'status': 'PENDENTE'})));
    await tester.pump();

    expect(find.text('NFSe #501'), findsOneWidget);
    expect(find.text('Itens (Serviços)'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Novo'));
    await tester.pump();

    expect(find.text('Produto (Serviço)'), findsOneWidget);
    expect(find.text('Descrição'), findsOneWidget);
    expect(find.text('Quantidade'), findsOneWidget);
    expect(find.text('Vl. Unitário'), findsOneWidget);
    expect(find.text('Vl. Total'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });

  test('busca de produtos da NFSe envia isServico=true', () {
    final query = DropdownHelpers.buildProdutosContabeisBuscaQuery(
      busca: 'consultoria',
      pagina: 0,
      empresaId: '1',
      parceiroId: '1751',
      isServico: true,
    );

    expect(query, contains('isServico=true'));
    expect(query, contains('nome=consultoria'));
    expect(query, contains('empId=1'));
    expect(query, contains('parceiroId=1751'));
  });
}
