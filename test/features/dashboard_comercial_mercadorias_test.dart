import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/dashboard_comercial_mercadorias_model.dart';

void main() {
  test('parseia dashboard comercial de mercadorias', () {
    final model = DashboardComercialMercadoriasModel.fromJson({
      'quantidadeEntrada': 10,
      'valorEntrada': 1000,
      'notasEntrada': 2,
      'quantidadeSaida': 4,
      'valorSaida': 760,
      'notasSaida': 1,
      'saldoEstoque': 20,
      'valorEstoque': 1500,
      'produtosEstoqueBaixo': 3,
      'produtosParados': 2,
      'variacaoCustoPercentual': 25,
      'giroEstoquePercentual': 20,
      'margemEstimadaPercentual': 47.37,
      'serieMercadorias': [
        {
          'periodo': '2026-08',
          'quantidadeEntrada': 10,
          'valorEntrada': 1000,
          'quantidadeSaida': 4,
          'valorSaida': 760,
        }
      ],
      'produtosVariacaoCusto': [
        {
          'produtoId': 1,
          'nome': 'Produto A',
          'ncm': '0101',
          'estoque': 8,
          'custoAtual': 100,
          'custoAnterior': 80,
          'variacaoPercentual': 25,
        }
      ],
      'indicesMercado': [
        {
          'nome': 'IPA-M / FGV',
          'descricao': 'Atacado agropecuario e industrial',
          'mensalPercentual': -0.34,
          'acumulado12mPercentual': 0,
          'referencia': 'Ago/2026',
          'leitura': 'Referencia principal para custo de mercadorias',
        }
      ],
    });

    expect(model.quantidadeEntrada, 10);
    expect(model.valorSaida, 760);
    expect(model.produtosVariacaoCusto.single.variacaoPercentual, 25);
    expect(model.indicesMercado.single.nome, 'IPA-M / FGV');
  });

  test('menu comercial aponta para tela real no web windows e mobile', () {
    final web =
        File('lib/web/screens/bottom_navbar_screen.dart').readAsStringSync();
    final windows = File('lib/windows/screens/bottom_navbar_screen.dart')
        .readAsStringSync();
    final mobile =
        File('lib/mobile/screens/bottom_navbar_screen.dart').readAsStringSync();

    expect(web, contains('DashboardComercialMercadoriasScreen'));
    expect(windows, contains('DashboardComercialMercadoriasScreen'));
    expect(mobile, contains('case "Dashboard Comercial"'));
    expect(mobile, contains('DashboardComercialMercadoriasScreen'));
  });
}
