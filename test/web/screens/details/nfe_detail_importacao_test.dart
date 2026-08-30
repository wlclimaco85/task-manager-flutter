import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/web/screens/details/nfe_detail_screen.dart';

void main() {
  group('NfeSankhyaDetailScreen importacao XML', () {
    test('rascunho de importacao usa Confirmar Entrada como acao principal',
        () {
      expect(isNfeRascunhoImportacao('RASCUNHO_IMPORTACAO'), isTrue);
      expect(nfeEntradaPrimaryActionLabel('RASCUNHO_IMPORTACAO'),
          'Confirmar Entrada');
      expect(nfeEntradaPrimaryActionLabel('AUTORIZADA'), 'Aceitar');
    });

    test('entrada nao exibe financeiro duplicado no detalhe', () {
      expect(exibeSecaoFinanceiraNoDetalheNfe('ENTRADA'), isFalse);
      expect(exibeSecaoFinanceiraNoDetalheNfe('SAIDA'), isTrue);
    });

    test('campo tipo de pagamento tem altura segura para label e valor', () {
      expect(nfeDetailPagamentoTipoCampoAltura, greaterThanOrEqualTo(56));
    });

    testWidgets('campo tipo de pagamento renderiza sem overflow',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 160,
              height: nfeDetailPagamentoTipoCampoAltura,
              child: DropdownButtonFormField<String>(
                initialValue: '01',
                isExpanded: true,
                isDense: true,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: '01',
                    child:
                        Text('01 - Dinheiro', style: TextStyle(fontSize: 11)),
                  ),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    test('totais exibem impostos existentes nos itens da nota', () {
      final totais = nfeDetailTotaisParaExibicao(
        valorNota: 2634.50,
        itens: [
          {
            'vProd': 2000.00,
            'vBcIcms': 2000.00,
            'vIcms': 240.00,
            'vPis': 33.00,
            'vCofins': 152.00,
            'vIpi': 12.50,
          },
          {
            'v_prod': '634,50',
            'v_bc_icms': '634,50',
            'v_icms': '76,14',
            'v_pis': '10,47',
            'v_cofins': '48,22',
          },
        ],
      );

      final porNome = Map.fromEntries(totais);
      expect(porNome['Vlr. Nota'], closeTo(2634.50, 0.001));
      expect(porNome['Total Produtos'], closeTo(2634.50, 0.001));
      expect(porNome['Base ICMS'], closeTo(2634.50, 0.001));
      expect(porNome['ICMS'], closeTo(316.14, 0.001));
      expect(porNome['PIS'], closeTo(43.47, 0.001));
      expect(porNome['COFINS'], closeTo(200.22, 0.001));
      expect(porNome['IPI'], closeTo(12.50, 0.001));
    });

    test(
        'totais usam o grupo fiscal do cabecalho quando os itens nao tem imposto',
        () {
      final totais = nfeDetailTotaisParaExibicao(
        valorNota: 8999.83,
        itens: [
          {'vProd': 8999.83},
        ],
        cabecalho: {
          'vBcIcms': 0,
          'vIcms': 0,
          'vPis': 0,
          'vCofins': 0,
          'vTotTrib': 2830.45,
        },
      );

      final porNome = Map.fromEntries(totais);
      expect(porNome['Vlr. Nota'], closeTo(8999.83, 0.001));
      expect(porNome['Total Tributos'], closeTo(2830.45, 0.001));
    });
  });
}
