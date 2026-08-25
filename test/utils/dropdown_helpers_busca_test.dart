import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/dropdown_helpers.dart';

/// Bug de producao: dropdown de busca "Parceiro" (Contas a Pagar/Receber) so
/// filtrava client-side sobre o 1o lote de 25 registros ja carregados
/// (DropdownHelpers.parceiros() sem paginacao/busca). Fix: DropdownHelpers.
/// parceirosBusca() reconsulta o backend a cada termo digitado com paginacao
/// real (GET /api/parceiro?busca=...&pagina=...&tamanho=...).
///
/// NetworkCaller usa a funcao top-level http.get() diretamente (sem client
/// injetavel), entao nao da para mockar a chamada de rede em si sem
/// infraestrutura de teste adicional que este projeto ainda nao tem para
/// DropdownHelpers (nenhum outro loader de DropdownHelpers tem teste de rede
/// hoje). Por isso a logica de montagem de query e parsing da resposta foi
/// extraida em funcoes puras (buildParceirosBuscaQuery / parsePaginaDropdown
/// / parseParceiroLabel) para poder ser testada sem rede — cobrindo o
/// comportamento que efetivamente corrige o bug: o termo digitado vira
/// parametro de busca na URL (nao fica so em memoria/filtro local) e a
/// paginacao real (pagina/tamanho/totalElements) e respeitada.
void main() {
  group('DropdownHelpers.buildParceirosBuscaQuery', () {
    test('inclui pagina e tamanho sempre, sem busca quando termo vazio', () {
      final query =
          DropdownHelpers.buildParceirosBuscaQuery(busca: null, pagina: 0);
      expect(query, '?pagina=0&tamanho=25');
    });

    test('inclui busca quando ha termo digitado — nao fica so em memoria', () {
      final query =
          DropdownHelpers.buildParceirosBuscaQuery(busca: 'ed', pagina: 0);
      expect(query, contains('busca=ed'));
    });

    test('ignora termo so com espacos (trim)', () {
      final query =
          DropdownHelpers.buildParceirosBuscaQuery(busca: '   ', pagina: 0);
      expect(query, isNot(contains('busca=')));
    });

    test('escapa caracteres especiais do termo de busca na URL', () {
      final query = DropdownHelpers.buildParceirosBuscaQuery(
          busca: 'a&b c', pagina: 0);
      expect(query, isNot(contains('busca=a&b c')));
      expect(query, contains('busca=a%26b+c'));
    });

    test('inclui empresaId quando fornecido (tela GED filtra por empresa)',
        () {
      final query = DropdownHelpers.buildParceirosBuscaQuery(
          busca: null, pagina: 0, empresaId: '20001');
      expect(query, contains('empresaId=20001'));
    });

    test('nao inclui empresaId quando nulo ou vazio', () {
      final semEmpresa =
          DropdownHelpers.buildParceirosBuscaQuery(busca: null, pagina: 0);
      final empresaVazia = DropdownHelpers.buildParceirosBuscaQuery(
          busca: null, pagina: 0, empresaId: '');
      expect(semEmpresa, isNot(contains('empresaId')));
      expect(empresaVazia, isNot(contains('empresaId')));
    });

    test('avanca a pagina ao rolar a lista (scroll pagination)', () {
      final pagina0 =
          DropdownHelpers.buildParceirosBuscaQuery(busca: null, pagina: 0);
      final pagina1 =
          DropdownHelpers.buildParceirosBuscaQuery(busca: null, pagina: 1);
      expect(pagina0, '?pagina=0&tamanho=25');
      expect(pagina1, '?pagina=1&tamanho=25');
    });
  });

  group('DropdownHelpers.parsePaginaDropdown', () {
    test('extrai items e total do corpo {data: {dados, totalElements}}', () {
      final body = {
        'data': {
          'dados': [
            {'id': 1, 'nome': 'Editora Alfa'},
            {'id': 2, 'nome': 'Fornecedor CNPJ com termo no CPF'},
          ],
          'totalElements': 35,
        },
      };

      final pagina = DropdownHelpers.parsePaginaDropdown(body);

      expect(pagina.total, 35);
      expect(pagina.items.length, 2);
      expect(pagina.items[0]['nome'], 'Editora Alfa');
    });

    test('preenche nome com razaoSocial quando nome vem vazio', () {
      final body = {
        'data': {
          'dados': [
            {'id': 1, 'nome': '', 'razaoSocial': 'Distribuidora Zebra Ltda'},
          ],
          'totalElements': 1,
        },
      };

      final pagina = DropdownHelpers.parsePaginaDropdown(body);

      expect(pagina.items[0]['nome'], 'Distribuidora Zebra Ltda');
    });

    test('corpo malformado retorna pagina vazia sem lancar excecao', () {
      expect(DropdownHelpers.parsePaginaDropdown(null).items, isEmpty);
      expect(DropdownHelpers.parsePaginaDropdown('texto').items, isEmpty);
      expect(DropdownHelpers.parsePaginaDropdown({'data': 'x'}).items, isEmpty);
      expect(DropdownHelpers.parsePaginaDropdown({}).total, 0);
    });

    test('busca vazia (sem termo) ainda retorna paginado normal', () {
      final body = {
        'data': {
          'dados': List.generate(25, (i) => {'id': i, 'nome': 'Parceiro $i'}),
          'totalElements': 40,
        },
      };

      final pagina = DropdownHelpers.parsePaginaDropdown(body);

      expect(pagina.items.length, 25);
      expect(pagina.total, 40);
    });
  });

  group('DropdownHelpers.parseParceiroLabel', () {
    test('usa nome quando presente', () {
      final label = DropdownHelpers.parseParceiroLabel({
        'data': {'nome': 'ANAP SERVICOS MEDICOS LTDA'},
      });
      expect(label, 'ANAP SERVICOS MEDICOS LTDA');
    });

    test('cai para razaoSocial quando nome vazio', () {
      final label = DropdownHelpers.parseParceiroLabel({
        'data': {'nome': '', 'razaoSocial': 'Razao Social Ltda'},
      });
      expect(label, 'Razao Social Ltda');
    });

    test('cai para email quando nome e razaoSocial vazios', () {
      final label = DropdownHelpers.parseParceiroLabel({
        'data': {'nome': '', 'razaoSocial': '', 'email': 'contato@teste.com'},
      });
      expect(label, 'contato@teste.com');
    });

    test('corpo malformado retorna null sem lancar excecao', () {
      expect(DropdownHelpers.parseParceiroLabel(null), isNull);
      expect(DropdownHelpers.parseParceiroLabel({'data': null}), isNull);
    });
  });
}
