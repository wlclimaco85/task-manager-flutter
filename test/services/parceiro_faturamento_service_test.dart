import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/parceiro_faturamento_utils.dart';

void main() {
  group('ParceiroFaturamentoService', () {
    test('preenche observacao com servico e competencia do mes anterior', () {
      expect(
        ParceiroFaturamentoUtils.observacaoPadrao(
          'Honorarios Contabeis',
          DateTime(2026, 10, 1),
        ),
        'Honorarios Contabeis - Setembro/2026',
      );
    });

    test('trata virada do ano na competencia da observacao', () {
      expect(
        ParceiroFaturamentoUtils.observacaoPadrao(
          'Honorarios',
          DateTime(2026, 1, 10),
        ),
        'Honorarios - Dezembro/2025',
      );
    });

    test('monta payload de faturamento em lote com ids e observacao limpa', () {
      expect(
        ParceiroFaturamentoUtils.buildPayload(
          parceiroIds: [10, 20],
          todos: false,
          produtoId: 30,
          serieId: 40,
          observacao: '  Honorarios - Setembro/2026  ',
        ),
        {
          'parceiroIds': [10, 20],
          'todos': false,
          'produtoId': 30,
          'serieId': 40,
          'observacao': 'Honorarios - Setembro/2026',
        },
      );
    });
  });
}
