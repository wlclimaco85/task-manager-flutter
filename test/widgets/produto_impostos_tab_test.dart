import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/produto_impostos_tab.dart';

/// Card https://trello.com/c/YooO4mOb — aba "Impostos" do cadastro de
/// Produto (IMP-14). NetworkCaller usa as funcoes top-level de package:http
/// diretamente (sem client injetavel), entao a chamada de rede em si nao e
/// testavel aqui sem infraestrutura adicional (mesmo padrao documentado em
/// test/utils/dropdown_helpers_busca_test.dart) — por isso a logica de
/// classificacao (regra padrão x exceção por UF), validação de campo
/// numérico e a mensagem de erro de duplicidade foram extraídas em funções
/// puras e são testadas diretamente.
void main() {
  group('separarRegraPadraoEExcecoes', () {
    test('separa regra padrão (sem UF) das exceções por UF', () {
      final configs = [
        {'id': 1, 'estadoId': null, 'aliquotaIcms': 18.0},
        {'id': 2, 'estadoId': 26, 'uf': 'SP', 'aliquotaIcms': 12.0},
        {'id': 3, 'estadoId': 33, 'uf': 'RJ', 'aliquotaIcms': 12.0},
      ];

      final resultado = separarRegraPadraoEExcecoes(configs);

      expect(resultado.regraPadrao?['id'], 1);
      expect(resultado.excecoesPorUf.map((e) => e['uf']), ['RJ', 'SP']);
    });

    test('lista vazia não tem regra padrão nem exceções', () {
      final resultado = separarRegraPadraoEExcecoes([]);
      expect(resultado.regraPadrao, isNull);
      expect(resultado.excecoesPorUf, isEmpty);
    });

    test('só exceções por UF, sem regra padrão cadastrada', () {
      final configs = [
        {'id': 2, 'estadoId': 26, 'uf': 'SP'},
      ];
      final resultado = separarRegraPadraoEExcecoes(configs);
      expect(resultado.regraPadrao, isNull);
      expect(resultado.excecoesPorUf, hasLength(1));
    });

    test('excecoes por UF ficam ordenadas por sigla', () {
      final configs = [
        {'id': 1, 'estadoId': 33, 'uf': 'RJ'},
        {'id': 2, 'estadoId': 26, 'uf': 'SP'},
        {'id': 3, 'estadoId': 15, 'uf': 'MG'},
      ];
      final resultado = separarRegraPadraoEExcecoes(configs);
      expect(resultado.excecoesPorUf.map((e) => e['uf']), ['MG', 'RJ', 'SP']);
    });
  });

  group('validarNumeroFiscal (IMP-14: validação de campos)', () {
    test('campo em branco é válido (opcional)', () {
      expect(validarNumeroFiscal(''), isNull);
      expect(validarNumeroFiscal(null), isNull);
      expect(validarNumeroFiscal('   '), isNull);
    });

    test('número válido com ponto é aceito', () {
      expect(validarNumeroFiscal('18.00'), isNull);
    });

    test('número válido com vírgula é aceito', () {
      expect(validarNumeroFiscal('18,00'), isNull);
    });

    test('texto não numérico é rejeitado', () {
      expect(validarNumeroFiscal('abc'), 'Valor numérico inválido');
    });

    test('número negativo é rejeitado', () {
      expect(validarNumeroFiscal('-5'), 'Não pode ser negativo');
    });

    test('zero é aceito', () {
      expect(validarNumeroFiscal('0'), isNull);
    });
  });

  group('parseNumeroFiscal', () {
    test('converte vírgula para ponto', () {
      expect(parseNumeroFiscal('7,5'), 7.5);
    });

    test('texto em branco vira nulo', () {
      expect(parseNumeroFiscal('  '), isNull);
    });

    test('texto inválido vira nulo (sem lançar exceção)', () {
      expect(parseNumeroFiscal('não é número'), isNull);
    });
  });

  group('mensagemErroSalvar (IMP-07/14: erro de duplicidade)', () {
    test('400 na regra padrão explica que já existe regra padrão', () {
      final msg = mensagemErroSalvar(400, isRegraPadrao: true);
      expect(msg, contains('regra padrão'));
    });

    test('400 em exceção por UF explica que já existe exceção para a UF', () {
      final msg = mensagemErroSalvar(400, isRegraPadrao: false);
      expect(msg, contains('exceção'));
      expect(msg, contains('UF'));
    });

    test('erro diferente de 400 mostra o status code genérico', () {
      final msg = mensagemErroSalvar(500, isRegraPadrao: false);
      expect(msg, contains('500'));
    });
  });

  group('copiar impostos para outro produto', () {
    test('monta URL da rota de copia com origem e destino', () {
      final url = montarUrlCopiarImpostos(
        origemProdutoId: 10,
        destinoProdutoId: 20,
      );

      expect(url, contains('/api/produto-imposto-uf/copiar'));
      expect(url, contains('origemProdutoId=10'));
      expect(url, contains('destinoProdutoId=20'));
    });

    test('remove produto origem da lista de destinos', () {
      final produtos = [
        {'id': 10, 'nome': 'Arroz'},
        {'id': '20', 'nome': 'Milho'},
      ];

      final destinos = filtrarProdutosDestinoImpostos(produtos, 10);

      expect(destinos.map((e) => e['id'].toString()), ['20']);
    });

    test('rotulo do produto usa codigo e nome quando disponiveis', () {
      final label = labelProdutoParaCopiarImpostos({
        'codigo': 'P001',
        'nome': 'Arroz em casca',
      });

      expect(label, 'P001 - Arroz em casca');
    });
  });
}
