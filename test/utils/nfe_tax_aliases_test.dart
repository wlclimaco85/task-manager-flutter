import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/nfe_tax_aliases.dart';

void main() {
  test('mapeia aliquotas diretas do produto para os campos calculados na NF-e',
      () {
    final item = <String, dynamic>{};

    NfeTaxAliases.applyProdutoSelecionado(item, {
      'cstPis': '01',
      'aliquotaPis': '1.65',
      'cstCofins': '01',
      'aliquotaCofins': '7.60',
      'aliquotaCbs': '0.90',
      'aliquotaIbsUf': '0.10',
      'aliquotaIbsMun': '0.00',
    });

    expect(item['cst_pis'], '01');
    expect(item['p_pis'], '1.65');
    expect(item['pPis'], '1.65');
    expect(item['cst_cofins'], '01');
    expect(item['p_cofins'], '7.60');
    expect(item['pCofins'], '7.60');
    expect(item['p_cbs'], '0.90');
    expect(item['p_ibs_uf'], '0.10');
    expect(item['p_ibs_mun'], '0.00');
  });

  test('mapeia aliases da regra produto imposto UF para os campos da tela', () {
    final item = <String, dynamic>{};

    NfeTaxAliases.applyProdutoImpostoUf(item, {
      'cst_pis': '01',
      'p_pis': 1.65,
      'cst_cofins': '01',
      'p_cofins': 7.60,
      'pCbs': 0.90,
      'pIbsUf': 0.10,
      'pIbsMun': 0.00,
    });

    expect(item['p_pis'], '1.65');
    expect(item['p_cofins'], '7.6');
    expect(item['p_cbs'], '0.9');
    expect(item['p_ibs_uf'], '0.1');
    expect(item['p_ibs_mun'], '0.0');
  });
}
