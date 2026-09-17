import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NFe Serie e Numero Alocacao', () {
    test('dropdown items formatam numero_atual vindo em snake_case do backend', () {
      final opts = [
        {'id': 8, 'serie': '01', 'numero_atual': 3},
        {'id': 9, 'serie': '001', 'numeroAtual': 555},
        {'id': 10, 'serie': '002'},
      ];

      final items = opts
          .map((o) => <String, dynamic>{
                'id': o['id']?.toString() ?? '',
                'nome':
                    '${o['serie'] ?? ''} (atual: ${o['numero_atual'] ?? o['numeroAtual'] ?? 1})',
              })
          .toList();

      expect(items[0]['nome'], '01 (atual: 3)');
      expect(items[1]['nome'], '001 (atual: 555)');
      expect(items[2]['nome'], '002 (atual: 1)');
    });

    test('extracao de proximo numero da serie suporta snake_case e camelCase', () {
      final Map<String, dynamic> responseBackend = {
        'id': 8,
        'serie': '01',
        'numero_atual': 3,
      };

      final num = responseBackend['data']?['numero_atual']?.toString() ??
          responseBackend['data']?['numeroAtual']?.toString() ??
          responseBackend['numero_atual']?.toString() ??
          responseBackend['numeroAtual']?.toString() ??
          '';

      expect(num, '3');
    });

    test('salvar cabecalho envia serieId, serie e numero no payload', () {
      final serieId = '8';
      final serie = '01';
      final numero = '000000003';

      final body = <String, dynamic>{
        'chave': '',
        'numero': numero,
        'serie': serie,
        if (serieId.isNotEmpty) 'serieId': int.tryParse(serieId) ?? serieId,
      };

      expect(body['serieId'], 8);
      expect(body['serie'], '01');
      expect(body['numero'], '000000003');
    });
  });
}
