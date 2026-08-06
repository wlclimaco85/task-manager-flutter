import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/searchable_dropdown.dart';
import 'package:task_manager_flutter/windows/screens/details/nfse_detail_screen.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('NFSe detail usa secoes sequenciais no web/desktop',
      (tester) async {
    await tester.pumpWidget(_wrap(const NfseDetailScreen(item: {})));
    await tester.pump();

    expect(find.text('Dados da NFSe'), findsOneWidget);
    expect(find.text('Servicos da nota'), findsOneWidget);
    expect(find.text('Resumo e impostos'), findsOneWidget);
    expect(find.text('Tomador / Parceiro'), findsOneWidget);
    expect(find.text('Numero'), findsOneWidget);
  });

  test('NFSe resolve codigo municipal pelo IBGE retornado em cidade', () {
    expect(
      resolveCodigoServicoMunicipalNfse(
        {'id': 9999, 'nome': 'Uberaba', 'codigoServicoMunicipal': '101'},
      ),
      '101',
    );
    expect(
      resolveCodigoServicoMunicipalNfse(
        {'id': 9999, 'nome': 'Uberaba', 'codigo_servico_municipal': '202'},
      ),
      '202',
    );
    expect(
      resolveCodigoServicoMunicipalNfse(
        {'id': 9999, 'nome': 'Uberaba', 'codigoServico': '303'},
      ),
      '303',
    );
    expect(
      resolveCodigoServicoMunicipalNfse(
        {'id': 9999, 'nome': 'Uberaba', 'codigo_servico': '404'},
      ),
      '404',
    );
    expect(
      resolveCodigoServicoMunicipalNfse(
        {'id': 9999, 'nome': 'Uberaba', 'ibge': 3170107},
      ),
      '3170107',
    );
  });

  testWidgets('NFSe detail alterna cabecalho para formulario de servicos',
      (tester) async {
    await tester.pumpWidget(_wrap(const NfseDetailScreen(item: {})));
    await tester.pump();

    final novoButton = find.widgetWithText(ElevatedButton, 'Novo').first;
    await tester.scrollUntilVisible(novoButton, 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pump();
    await tester.tap(novoButton);
    await tester.pump();

    expect(find.textContaining('Produto'), findsWidgets);
    expect(find.text('Salvar Item'), findsOneWidget);
  });

  testWidgets(
      'NFSe detail abre busca inline sem navegar para modal de tela cheia',
      (tester) async {
    await tester.pumpWidget(_wrap(const NfseDetailScreen(item: {})));
    await tester.pump();

    await tester.tap(find.byType(SearchableDropdownField).first);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets(
      'NFSe detail preenche codigo municipal a partir do IBGE da cidade',
      (tester) async {
    await tester.pumpWidget(_wrap(const NfseDetailScreen(item: {
      'municipioPrestacao': 'Uberaba',
      'cidade': {'id': 1, 'nome': 'Uberaba', 'ibge': 3170107},
    })));
    await tester.pump();

    final codigoField =
        find.widgetWithText(TextFormField, 'Codigo de Servico Municipal');

    expect(codigoField, findsOneWidget);
    expect((tester.widget(codigoField) as TextFormField).controller?.text,
        '3170107');
  });

  testWidgets('NFSe detail nao estoura em largura estreita', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_wrap(const NfseDetailScreen(item: {})));
    await tester.pump();

    expect(tester.takeException(), isNull);

    final novoButton = find.widgetWithText(ElevatedButton, 'Novo').first;
    await tester.drag(
        find.byType(SingleChildScrollView).first, const Offset(0, -300));
    await tester.pump();
    await tester.tap(novoButton);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Servicos da nota'), findsOneWidget);
  });
}
