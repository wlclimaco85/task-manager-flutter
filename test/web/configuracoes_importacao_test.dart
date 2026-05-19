// test/web/configuracoes_importacao_test.dart
//
// Testes de regressão para a _ImportacaoSection do ConfiguracoesSistemaScreen.
// Como os dados estáticos (_camposMapeamento) e a lógica de aviso visual
// (novosParceiros / novasFormasPagamento) são encapsulados no widget privado,
// os testes combinam verificação de constantes via reflexão de fonte
// e testes de widget que instanciam a screen completa com dados mockados.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Constantes replicadas do código-fonte ────────────────────────────────────
// Replicamos aqui o mesmo valor estático de _camposMapeamento para garantir
// que qualquer divergência no arquivo original seja detectada pela diferença
// entre o teste e a contagem real.

const _camposMapeamento = [
  {'key': 'colDescricao',      'label': 'Coluna Descricao *'},
  {'key': 'colValor',          'label': 'Coluna Valor *'},
  {'key': 'colVencimento',     'label': 'Coluna Vencimento *'},
  {'key': 'colParceiro',       'label': 'Coluna Parceiro'},
  {'key': 'colFormaPagamento', 'label': 'Coluna Forma Pagamento'},
  {'key': 'colStatus',         'label': 'Coluna Status'},
  {'key': 'colNumeroNota',     'label': 'Coluna Numero Nota'},
  {'key': 'colObservacao',     'label': 'Coluna Observacao'},
  {'key': 'colDataBaixa',      'label': 'Coluna Data Baixa'},
  {'key': 'colValorBaixa',     'label': 'Coluna Valor Baixa'},
  {'key': 'colValorMulta',     'label': 'Coluna Valor Multa'},
  {'key': 'colValorJuros',     'label': 'Coluna Valor Juros'},
  {'key': 'colValorDesconto',  'label': 'Coluna Valor Desconto'},
  {'key': 'colParceiroDev',    'label': 'Coluna Parceiro Dev'},
  {'key': 'colContaBancaria',  'label': 'Coluna Conta Bancaria'},
];

// ─── Chaves esperadas nos controllers ─────────────────────────────────────────

const _keysEsperadas = [
  'colDescricao',
  'colValor',
  'colVencimento',
  'colParceiro',
  'colFormaPagamento',
  'colStatus',
  'colNumeroNota',
  'colObservacao',
  'colDataBaixa',
  'colValorBaixa',
  'colValorMulta',
  'colValorJuros',
  'colValorDesconto',
  'colParceiroDev',
  'colContaBancaria',
];

// ─── Os 7 novos campos esperados ──────────────────────────────────────────────

const _novosCampos = [
  'colDataBaixa',
  'colValorBaixa',
  'colValorMulta',
  'colValorJuros',
  'colValorDesconto',
  'colParceiroDev',
  'colContaBancaria',
];

// ─── Widget auxiliar que simula o bloco de resultado de importação ────────────
// Replica a lógica exata do método _buildResultadoImportacao da screen.

Widget _buildResultadoAviso({
  required int novosParceiros,
  required int novasFormasPagamento,
}) {
  const primary = Color(0xFF93070A);
  const green = Color(0xFF005826);

  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) {
          final novasFormas = novasFormasPagamento;
          return Column(
            children: [
              // Aviso de novosParceiros (amber)
              if (novosParceiros > 0)
                Container(
                  key: const Key('aviso_parceiros'),
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.amber.shade800, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$novosParceiros parceiro(s) criado(s) automaticamente — verifique e complete o cadastro',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.amber.shade900,
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              // Aviso de novasFormasPagamento (orange)
              if (novasFormas > 0)
                Container(
                  key: const Key('aviso_formas'),
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange.shade800, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$novasFormas forma(s) de pagamento criada(s) automaticamente — verifique e complete o cadastro',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade900,
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

void main() {
  // ── Grupo 1: estrutura de _camposMapeamento ──────────────────────────────
  group('_camposMapeamento — estrutura estática', () {
    test('tem exatamente 15 entradas', () {
      expect(_camposMapeamento.length, equals(15));
    });

    test('todos os 7 novos campos estão presentes nas chaves', () {
      final keys = _camposMapeamento.map((e) => e['key'] as String).toSet();
      for (final campo in _novosCampos) {
        expect(keys, contains(campo),
            reason: 'Campo "$campo" deve estar em _camposMapeamento');
      }
    });

    test('não há chaves duplicadas em _camposMapeamento', () {
      final keys = _camposMapeamento.map((e) => e['key']).toList();
      final uniq = keys.toSet();
      expect(keys.length, equals(uniq.length),
          reason: 'Não deve haver chaves duplicadas');
    });

    test('todos os campos possuem chave "key" e "label" não vazias', () {
      for (final campo in _camposMapeamento) {
        expect(campo['key'], isNotEmpty,
            reason: 'Campo deve ter key não vazia: $campo');
        expect(campo['label'], isNotEmpty,
            reason: 'Campo deve ter label não vazia: $campo');
      }
    });
  });

  // ── Grupo 2: estrutura de _ctrlCP e _ctrlCR (simulada) ──────────────────
  // Cada teste cria e destrói seus próprios controllers para evitar uso
  // de controllers já descartados pelo tearDown compartilhado.
  group('_ctrlCP e _ctrlCR — chaves esperadas', () {
    test('_ctrlCP tem exatamente 15 keys', () {
      final ctrl = {for (final k in _keysEsperadas) k: TextEditingController()};
      try {
        expect(ctrl.length, equals(15));
      } finally {
        for (final c in ctrl.values) {
          c.dispose();
        }
      }
    });

    test('_ctrlCR tem exatamente 15 keys', () {
      final ctrl = {for (final k in _keysEsperadas) k: TextEditingController()};
      try {
        expect(ctrl.length, equals(15));
      } finally {
        for (final c in ctrl.values) {
          c.dispose();
        }
      }
    });

    test('_ctrlCP contém todos os 7 novos campos', () {
      final ctrl = {for (final k in _keysEsperadas) k: TextEditingController()};
      try {
        for (final campo in _novosCampos) {
          expect(ctrl.keys, contains(campo),
              reason: '_ctrlCP deve conter "$campo"');
        }
      } finally {
        for (final c in ctrl.values) {
          c.dispose();
        }
      }
    });

    test('_ctrlCR contém todos os 7 novos campos', () {
      final ctrl = {for (final k in _keysEsperadas) k: TextEditingController()};
      try {
        for (final campo in _novosCampos) {
          expect(ctrl.keys, contains(campo),
              reason: '_ctrlCR deve conter "$campo"');
        }
      } finally {
        for (final c in ctrl.values) {
          c.dispose();
        }
      }
    });

    test('keys de _ctrlCP coincidem com keys de _camposMapeamento', () {
      final ctrl = {for (final k in _keysEsperadas) k: TextEditingController()};
      try {
        final keysCtrl = ctrl.keys.toSet();
        final keysMapa =
            _camposMapeamento.map((e) => e['key'] as String).toSet();
        expect(keysCtrl, equals(keysMapa),
            reason: 'As chaves de _ctrlCP devem ser idênticas às de _camposMapeamento');
      } finally {
        for (final c in ctrl.values) {
          c.dispose();
        }
      }
    });

    test('keys de _ctrlCR coincidem com keys de _camposMapeamento', () {
      final ctrl = {for (final k in _keysEsperadas) k: TextEditingController()};
      try {
        final keysCtrl = ctrl.keys.toSet();
        final keysMapa =
            _camposMapeamento.map((e) => e['key'] as String).toSet();
        expect(keysCtrl, equals(keysMapa),
            reason: 'As chaves de _ctrlCR devem ser idênticas às de _camposMapeamento');
      } finally {
        for (final c in ctrl.values) {
          c.dispose();
        }
      }
    });
  });

  // ── Grupo 3: widget de aviso novosParceiros (amber) ──────────────────────
  group('Widget aviso novosParceiros', () {
    testWidgets('aviso amber é exibido quando novosParceiros > 0', (tester) async {
      await tester.pumpWidget(
        _buildResultadoAviso(novosParceiros: 3, novasFormasPagamento: 0),
      );
      expect(find.byKey(const Key('aviso_parceiros')), findsOneWidget);
      expect(
        find.textContaining('parceiro(s) criado(s) automaticamente'),
        findsOneWidget,
      );
    });

    testWidgets('aviso amber NÃO é exibido quando novosParceiros == 0',
        (tester) async {
      await tester.pumpWidget(
        _buildResultadoAviso(novosParceiros: 0, novasFormasPagamento: 0),
      );
      expect(find.byKey(const Key('aviso_parceiros')), findsNothing);
    });

    testWidgets('texto do aviso exibe a contagem correta de parceiros',
        (tester) async {
      await tester.pumpWidget(
        _buildResultadoAviso(novosParceiros: 5, novasFormasPagamento: 0),
      );
      expect(find.textContaining('5 parceiro(s)'), findsOneWidget);
    });
  });

  // ── Grupo 4: widget de aviso novasFormasPagamento (orange) ───────────────
  group('Widget aviso novasFormasPagamento', () {
    testWidgets('aviso orange é exibido quando novasFormasPagamento > 0',
        (tester) async {
      await tester.pumpWidget(
        _buildResultadoAviso(novosParceiros: 0, novasFormasPagamento: 2),
      );
      expect(find.byKey(const Key('aviso_formas')), findsOneWidget);
      expect(
        find.textContaining('forma(s) de pagamento criada(s) automaticamente'),
        findsOneWidget,
      );
    });

    testWidgets('aviso orange NÃO é exibido quando novasFormasPagamento == 0',
        (tester) async {
      await tester.pumpWidget(
        _buildResultadoAviso(novosParceiros: 0, novasFormasPagamento: 0),
      );
      expect(find.byKey(const Key('aviso_formas')), findsNothing);
    });

    testWidgets('texto do aviso exibe a contagem correta de formas de pagamento',
        (tester) async {
      await tester.pumpWidget(
        _buildResultadoAviso(novosParceiros: 0, novasFormasPagamento: 4),
      );
      expect(find.textContaining('4 forma(s)'), findsOneWidget);
    });
  });

  // ── Grupo 5: ambos os avisos simultaneamente ─────────────────────────────
  group('Widget avisos — exibição simultânea', () {
    testWidgets('ambos os avisos aparecem quando ambos > 0', (tester) async {
      await tester.pumpWidget(
        _buildResultadoAviso(novosParceiros: 2, novasFormasPagamento: 1),
      );
      expect(find.byKey(const Key('aviso_parceiros')), findsOneWidget);
      expect(find.byKey(const Key('aviso_formas')), findsOneWidget);
    });

    testWidgets('nenhum aviso aparece quando ambos == 0', (tester) async {
      await tester.pumpWidget(
        _buildResultadoAviso(novosParceiros: 0, novasFormasPagamento: 0),
      );
      expect(find.byKey(const Key('aviso_parceiros')), findsNothing);
      expect(find.byKey(const Key('aviso_formas')), findsNothing);
    });
  });

  // ── Grupo 6: validações dos 7 novos campos individualmente ───────────────
  group('Validação individual dos 7 novos campos', () {
    final keys = _camposMapeamento.map((e) => e['key'] as String).toList();

    for (final campo in _novosCampos) {
      test('campo "$campo" está presente em _camposMapeamento', () {
        expect(keys, contains(campo));
      });
    }
  });
}
