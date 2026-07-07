import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/customization/generic_grid/grid_helpers.dart';

void main() {
  group('extractAnyList parsing de respostas do backend', () {
    test('aceita List direto (array raiz)', () {
      final input = [
        {'id': 1, 'nome': 'Doc A'},
        {'id': 2, 'nome': 'Doc B'},
      ];
      final result = extractAnyList(input);
      expect(result, hasLength(2));
      expect(result[0]['nome'], 'Doc A');
      expect(result[1]['nome'], 'Doc B');
    });

    test('aceita Map com chave data contendo List', () {
      final input = {
        'data': [
          {'id': 10, 'tipo': 'GED'},
        ],
        'totalElements': 1,
      };
      final list = input is List
          ? extractAnyList(input)
          : extractAnyList(input['data'] ?? input['dados'] ?? input);
      expect(list, hasLength(1));
      expect(list[0]['tipo'], 'GED');
    });

    test('aceita Map com chave dados contendo List', () {
      final input = {
        'dados': [
          {'id': 5, 'categoria': 'Fiscal'},
        ],
        'total': 1,
      };
      final list = input is List
          ? extractAnyList(input)
          : extractAnyList(input['data'] ?? input['dados'] ?? input);
      expect(list, hasLength(1));
      expect(list[0]['categoria'], 'Fiscal');
    });

    test('retorna lista vazia para null', () {
      expect(extractAnyList(null), isEmpty);
    });

    test('retorna lista vazia para List vazia', () {
      expect(extractAnyList(<dynamic>[]), isEmpty);
    });

    test('ignora itens nao-Map dentro da List', () {
      final input = [
        {'id': 1},
        'string_ignorada',
        42,
        {'id': 2},
      ];
      final result = extractAnyList(input);
      expect(result, hasLength(2));
    });

    test('aceita String JSON que contem array', () {
      const json = '[{"id":99,"status":"ok"}]';
      final result = extractAnyList(json);
      expect(result, hasLength(1));
      expect(result[0]['id'], 99);
    });

    test('retorna lista vazia para String JSON invalida', () {
      expect(extractAnyList('nao e json'), isEmpty);
    });
  });

  group('rawBody parser logic usada por grid_page/grid_list', () {
    List<Map<String, dynamic>> parseResponse(dynamic rawBody) {
      final body = rawBody is Map
          ? Map<String, dynamic>.from(rawBody)
          : <String, dynamic>{};
      return rawBody is List
          ? extractAnyList(rawBody)
          : extractAnyList(body['data'] ?? body['dados'] ?? body);
    }

    Map<String, dynamic> extractMeta(dynamic rawBody) {
      return rawBody is Map
          ? Map<String, dynamic>.from(rawBody)
          : <String, dynamic>{};
    }

    test('rawBody List retorna itens corretos e meta vazia', () {
      final rawBody = [
        {'id': 1, 'doc': 'A'},
        {'id': 2, 'doc': 'B'},
      ];
      final list = parseResponse(rawBody);
      final meta = extractMeta(rawBody);
      expect(list, hasLength(2));
      expect(meta, isEmpty);
    });

    test('rawBody Map com data retorna itens corretos e meta acessivel', () {
      final rawBody = <String, dynamic>{
        'data': [
          {'id': 3, 'doc': 'C'},
        ],
        'totalElements': 1,
      };
      final list = parseResponse(rawBody);
      final meta = extractMeta(rawBody);
      expect(list, hasLength(1));
      expect(list[0]['doc'], 'C');
      expect(meta['totalElements'], 1);
    });

    test('rawBody Map com dados retorna itens corretos', () {
      final rawBody = <String, dynamic>{
        'dados': [
          {'id': 4, 'doc': 'D'},
        ],
        'total': 1,
      };
      final list = parseResponse(rawBody);
      expect(list, hasLength(1));
      expect(list[0]['doc'], 'D');
    });

    test('rawBody List nao lanca excecao', () {
      final rawBody = [
        {'id': 100},
      ];
      expect(() => parseResponse(rawBody), returnsNormally);
    });

    test('totalElements inferido do tamanho da lista quando rawBody e List',
        () {
      final rawBody = [
        {'id': 1},
        {'id': 2},
        {'id': 3},
      ];
      final list = parseResponse(rawBody);
      final meta = extractMeta(rawBody);
      final total = (meta['totalElements'] ?? list.length) as int;
      expect(list, hasLength(3));
      expect(total, 3);
    });

    test('rawBody Map<dynamic, dynamic> preserva data e meta', () {
      final rawBody = <dynamic, dynamic>{
        'data': [
          {'id': 9, 'doc': 'I'},
        ],
        'totalElements': 1,
      };
      final list = parseResponse(rawBody);
      final meta = extractMeta(rawBody);
      expect(list, hasLength(1));
      expect(list[0]['doc'], 'I');
      expect(meta['totalElements'], 1);
    });
  });
}
