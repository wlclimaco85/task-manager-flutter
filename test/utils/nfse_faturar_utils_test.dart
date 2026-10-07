import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/nfse_faturar_utils.dart';

void main() {
  group('meses de referencia', () {
    test('lista tem 12 meses com nome em portugues', () {
      expect(nfseMesesPt.length, 12);
      expect(nfseNomeMes(1), 'Janeiro');
      expect(nfseNomeMes(3), 'Março');
      expect(nfseNomeMes(12), 'Dezembro');
      expect(nfseNomeMes(0), '');
      expect(nfseNomeMes(13), '');
    });

    test('competencia padrao e o mes anterior, com virada de ano', () {
      expect(nfseCompetenciaPadrao(DateTime(2026, 10, 6)), (mes: 9, ano: 2026));
      expect(nfseCompetenciaPadrao(DateTime(2026, 1, 15)), (mes: 12, ano: 2025));
    });
  });

  group('valor padrao e validacao', () {
    test('valor padrao e o valor mensal do parceiro, nao o da ultima nota', () {
      final resumo = {'valorMensal': 1097.47, 'jaFaturado': 0, 'ultimaNota': 500};
      expect(nfseValorPadrao(resumo), '1097,47');
      expect(nfseValorPadrao({'valorMensal': '1097.47'}), '1097,47');
      expect(nfseValorPadrao(null), '');
    });

    test('parse aceita virgula, ponto e milhar', () {
      expect(nfseParseValorDigitado('1097,47'), 1097.47);
      expect(nfseParseValorDigitado('1.097,47'), 1097.47);
      expect(nfseParseValorDigitado('1097.47'), 1097.47);
      expect(nfseParseValorDigitado(''), isNull);
      expect(nfseParseValorDigitado('abc'), isNull);
    });

    test('valor dentro do saldo e aceito, inclusive exatamente o limite', () {
      expect(
          nfseValidarValorFaturar(
              valor: 1097.47, valorMensal: 1097.47, jaFaturado: 0),
          isNull);
      expect(
          nfseValidarValorFaturar(
              valor: 97.47, valorMensal: 1097.47, jaFaturado: 1000),
          isNull);
    });

    test('soma acima do valor mensal e recusada com mensagem do saldo', () {
      final erro = nfseValidarValorFaturar(
          valor: 100, valorMensal: 1097.47, jaFaturado: 1000);
      expect(erro, contains('acima do saldo'));
      expect(erro, contains('97,47'));
    });

    test('valor zerado, vazio ou tomador sem valor mensal sao recusados', () {
      expect(
          nfseValidarValorFaturar(valor: null, valorMensal: 10, jaFaturado: 0),
          isNotNull);
      expect(
          nfseValidarValorFaturar(valor: 0, valorMensal: 10, jaFaturado: 0),
          isNotNull);
      expect(
          nfseValidarValorFaturar(valor: 5, valorMensal: null, jaFaturado: 0),
          contains('valor mensal'));
    });
  });

  group('mensagem de erro e resultado', () {
    test('extrai a mensagem completa do JSON do backend', () {
      const msg = 'NFS-e nao autorizada pela prefeitura. Nada foi gravado. '
          'Motivo: E160 - Codigo de servico invalido';
      expect(
          nfseMensagemErroHttp(400,
              '{"timestamp":"x","status":400,"message":"$msg"}'),
          msg);
    });

    test('usa corpo cru ou status quando nao ha JSON com mensagem', () {
      expect(nfseMensagemErroHttp(500, 'falha interna'), 'falha interna');
      expect(nfseMensagemErroHttp(502, ''), contains('502'));
    });

    test('resultado mapeia numeros de nota, contas, mensalidade e GED', () {
      final r = NfseFaturarResultado.fromJson({
        'nfseId': 100,
        'numeroNfse': '2026001',
        'mensalidadeId': 5,
        'contaPagarId': 80,
        'contaReceberId': 70,
        'arquivoGedId': 60,
        'gedPreenchido': true,
        'pdfGerado': true,
        'dataVencimento': '2026-02-06',
        'mensagem': 'ok',
      });
      expect(r.numeroNfse, '2026001');
      expect(r.contaPagarId, 80);
      expect(r.contaReceberId, 70);
      expect(r.mensalidadeId, 5);
      expect(r.gedPreenchido, isTrue);
      expect(nfseFormatarDataIso(r.dataVencimento!), '06/02/2026');
    });
  });
}
