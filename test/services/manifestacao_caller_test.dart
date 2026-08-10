import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/services/manifestacao_caller.dart';

/// Testes da lógica de negócio de Manifestação do Destinatário de NFe
/// (card P2-502). Cobrem o contrato REAL do backend
/// (ManifestacaoDestinatarioServiceImpl.TIPOS_VALIDOS /
/// EXIGE_JUSTIFICATIVA), não o vocabulário do card original
/// (aceitar/recusar/parcial, que não existe na API).
void main() {
  group('ManifestacaoTipoEvento - valores aceitos pelo backend', () {
    test('expõe exatamente os 4 tipos de evento oficiais SEFAZ', () {
      expect(ManifestacaoTipoEvento.valores, hasLength(4));
      expect(
        ManifestacaoTipoEvento.valores,
        containsAll(<String>[
          'CIENCIA',
          'CONFIRMACAO',
          'DESCONHECIMENTO',
          'NAO_REALIZADA',
        ]),
      );
    });

    test('constantes têm os literais exatos usados pelo backend', () {
      expect(ManifestacaoTipoEvento.ciencia, 'CIENCIA');
      expect(ManifestacaoTipoEvento.confirmacao, 'CONFIRMACAO');
      expect(ManifestacaoTipoEvento.desconhecimento, 'DESCONHECIMENTO');
      expect(ManifestacaoTipoEvento.naoRealizada, 'NAO_REALIZADA');
    });
  });

  group('ManifestacaoTipoEvento.exigeJustificativa', () {
    test('CONFIRMACAO exige justificativa', () {
      expect(
        ManifestacaoTipoEvento.exigeJustificativa(
            ManifestacaoTipoEvento.confirmacao),
        isTrue,
      );
    });

    test('NAO_REALIZADA exige justificativa', () {
      expect(
        ManifestacaoTipoEvento.exigeJustificativa(
            ManifestacaoTipoEvento.naoRealizada),
        isTrue,
      );
    });

    test('CIENCIA não exige justificativa', () {
      expect(
        ManifestacaoTipoEvento.exigeJustificativa(
            ManifestacaoTipoEvento.ciencia),
        isFalse,
      );
    });

    test('DESCONHECIMENTO não exige justificativa', () {
      expect(
        ManifestacaoTipoEvento.exigeJustificativa(
            ManifestacaoTipoEvento.desconhecimento),
        isFalse,
      );
    });

    test('valor desconhecido não exige justificativa (fail-safe)', () {
      expect(ManifestacaoTipoEvento.exigeJustificativa('QUALQUER_COISA'),
          isFalse);
    });
  });

  group('ManifestacaoResult', () {
    test('resultado de sucesso carrega data/list/statusCode', () {
      final result = ManifestacaoResult(
        success: true,
        data: {'nfeChave': '1' * 44, 'status': 'ENVIADO'},
        statusCode: 200,
      );

      expect(result.success, isTrue);
      expect(result.data?['status'], 'ENVIADO');
      expect(result.statusCode, 200);
      expect(result.message, isNull);
    });

    test('resultado de erro carrega mensagem sem quebrar em campos nulos',
        () {
      final result = ManifestacaoResult(
        success: false,
        message: 'Erro ao conectar: SocketException',
      );

      expect(result.success, isFalse);
      expect(result.data, isNull);
      expect(result.list, isNull);
      expect(result.message, contains('Erro ao conectar'));
    });
  });

  group('ManifestacaoCaller.registrarManifestacao - contrato de requisição',
      () {
    // Estes testes documentam o contrato esperado (nomes de parâmetros e
    // chaves de body) sem depender de rede — a chamada real de rede em
    // ambiente de teste falha (sem servidor), o que é esperado e tratado
    // pelo try/catch do caller retornando success=false.
    test('aceita nfeChave/tipoEvento/justificativa (contrato real do backend)',
        () async {
      final result = await ManifestacaoCaller.registrarManifestacao(
        nfeChave: '3' * 44,
        tipoEvento: ManifestacaoTipoEvento.confirmacao,
        justificativa: 'Mercadoria recebida conforme nota fiscal emitida',
      );

      // Sem servidor de teste, a chamada real falha rápido; o caller nunca
      // deve lançar exceção — sempre retorna um ManifestacaoResult.
      expect(result, isA<ManifestacaoResult>());
      expect(result.success, isFalse);
      expect(result.message, isNotNull);
    });

    test('funciona sem justificativa quando tipo não exige (CIENCIA)',
        () async {
      final result = await ManifestacaoCaller.registrarManifestacao(
        nfeChave: '4' * 44,
        tipoEvento: ManifestacaoTipoEvento.ciencia,
      );

      expect(result, isA<ManifestacaoResult>());
      expect(result.success, isFalse); // sem rede no ambiente de teste
    });
  });

  group('ManifestacaoCaller.listarPendentes/listarHistorico - resiliência',
      () {
    test('listarPendentes nunca lança exceção mesmo sem rede', () async {
      final result = await ManifestacaoCaller.listarPendentes();
      expect(result, isA<ManifestacaoResult>());
      expect(result.success, isFalse);
    });

    test('listarHistorico nunca lança exceção mesmo sem rede', () async {
      final result = await ManifestacaoCaller.listarHistorico();
      expect(result, isA<ManifestacaoResult>());
      expect(result.success, isFalse);
    });
  });
}
