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
  });
}
