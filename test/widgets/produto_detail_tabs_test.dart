import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/produto_detail_tabs.dart';
import 'package:task_manager_flutter/widgets/produto_impostos_tab.dart';

void main() {
  test('detalhe de produto sempre monta a aba Tributos', () {
    final tabs = buildProdutoRelatedTabs(123);

    expect(tabs.map((tab) => tab.title), [
      'Tributos',
      'Estoque',
      'Notas de Compras',
      'Notas de Saidas',
    ]);
    expect(tabs.first.customWidget, isA<ProdutoImpostosTab>());
  });
}
