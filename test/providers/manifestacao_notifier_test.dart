import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/manifestacao/manifestacao_status.dart';
import 'package:task_manager_flutter/providers/manifestacao_notifier.dart';
import 'package:task_manager_flutter/services/manifestacao_caller.dart';

ManifestacaoResult _resultSucesso() => ManifestacaoResult(
      success: true,
      list: [
        {
          'nfeId': 'nfe-001',
          'numero': 'NFe 123456789',
          'fornecedor': 'Fornecedor Teste Ltda',
          'valor': 'R\$ 1.000,00',
          'dataEmissao': '2026-07-27T10:00:00',
        }
      ],
    );

ManifestacaoResult _resultVazio() =>
    ManifestacaoResult(success: true, list: []);

ManifestacaoResult _resultErro() =>
    ManifestacaoResult(success: false, message: 'Erro de conexão');

ManifestacaoResult _resultRegistroOk() =>
    ManifestacaoResult(success: true, data: {'protocolo': '123'});

ManifestacaoResult _resultRegistroErro() =>
    ManifestacaoResult(success: false, message: 'NFe não encontrada');

void main() {
  group('ManifestacaoNotifier - loadManifestacao', () {
    test('carrega dados da API com sucesso', () async {
      final notifier = ManifestacaoNotifier(
        listarPendentes: () async => _resultSucesso(),
      );

      await notifier.loadManifestacao('nfe-001');

      expect(notifier.manifestacao, isNotNull);
      expect(notifier.manifestacao!.nfeId, 'nfe-001');
      expect(notifier.manifestacao!.fornecedor, 'Fornecedor Teste Ltda');
      expect(notifier.isLoading, false);
      expect(notifier.errorMessage, isNull);

      notifier.dispose();
    });

    test('exibe erro quando lista vazia', () async {
      final notifier = ManifestacaoNotifier(
        listarPendentes: () async => _resultVazio(),
      );

      await notifier.loadManifestacao('nfe-001');

      expect(notifier.manifestacao, isNull);
      expect(notifier.errorMessage, contains('Nenhuma'));
      expect(notifier.isLoading, false);

      notifier.dispose();
    });

    test('exibe erro quando API falha', () async {
      final notifier = ManifestacaoNotifier(
        listarPendentes: () async => _resultErro(),
      );

      await notifier.loadManifestacao('nfe-001');

      expect(notifier.manifestacao, isNull);
      expect(notifier.errorMessage, 'Erro de conexão');
      expect(notifier.isLoading, false);

      notifier.dispose();
    });

    test('trata exceção inesperada', () async {
      final notifier = ManifestacaoNotifier(
        listarPendentes: () async => throw Exception('timeout'),
      );

      await notifier.loadManifestacao('nfe-001');

      expect(notifier.manifestacao, isNull);
      expect(notifier.errorMessage, contains('timeout'));
      expect(notifier.isLoading, false);

      notifier.dispose();
    });

    test('isLoading true durante carregamento', () async {
      bool capturedLoading = false;
      final notifier = ManifestacaoNotifier(
        listarPendentes: () async {
          return _resultSucesso();
        },
      );

      notifier.addListener(() {
        if (notifier.isLoading) capturedLoading = true;
      });

      await notifier.loadManifestacao('nfe-001');

      expect(capturedLoading, true);
      expect(notifier.isLoading, false);

      notifier.dispose();
    });
  });

  group('ManifestacaoNotifier - submitManifestacao', () {
    test('submete com sucesso quando formulário válido', () async {
      final notifier = ManifestacaoNotifier(
        listarPendentes: () async => _resultSucesso(),
        registrarManifestacao: ({
          required String chave,
          required String tipo,
          String? justificativa,
        }) async =>
            _resultRegistroOk(),
      );

      await notifier.loadManifestacao('nfe-001');
      notifier.setStatus(ManifestacaoStatus.aceitar);

      final ok = await notifier.submitManifestacao();

      expect(ok, true);
      expect(notifier.manifestacao, isNull);
      expect(notifier.errorMessage, isNull);
      expect(notifier.isSubmitting, false);

      notifier.dispose();
    });

    test('retorna false quando formulário inválido', () async {
      final notifier = ManifestacaoNotifier();

      final ok = await notifier.submitManifestacao();

      expect(ok, false);
      expect(notifier.errorMessage, 'Formulário inválido');

      notifier.dispose();
    });

    test('exibe erro quando API rejeita', () async {
      final notifier = ManifestacaoNotifier(
        listarPendentes: () async => _resultSucesso(),
        registrarManifestacao: ({
          required String chave,
          required String tipo,
          String? justificativa,
        }) async =>
            _resultRegistroErro(),
      );

      await notifier.loadManifestacao('nfe-001');
      notifier.setStatus(ManifestacaoStatus.aceitar);

      final ok = await notifier.submitManifestacao();

      expect(ok, false);
      expect(notifier.errorMessage, 'NFe não encontrada');
      expect(notifier.manifestacao, isNotNull);

      notifier.dispose();
    });

    test('envia justificativa na recusa', () async {
      String? capturedJustificativa;
      final notifier = ManifestacaoNotifier(
        listarPendentes: () async => _resultSucesso(),
        registrarManifestacao: ({
          required String chave,
          required String tipo,
          String? justificativa,
        }) async {
          capturedJustificativa = justificativa;
          return _resultRegistroOk();
        },
      );

      await notifier.loadManifestacao('nfe-001');
      notifier.setStatus(ManifestacaoStatus.recusar);
      notifier.setObservacao('Produto danificado');

      await notifier.submitManifestacao();

      expect(capturedJustificativa, 'Produto danificado');

      notifier.dispose();
    });
  });

  group('ManifestacaoNotifier - setters', () {
    test('setStatus atualiza manifestação', () async {
      final notifier = ManifestacaoNotifier(
        listarPendentes: () async => _resultSucesso(),
      );

      await notifier.loadManifestacao('nfe-001');
      notifier.setStatus(ManifestacaoStatus.aceitar);

      expect(notifier.manifestacao!.status, ManifestacaoStatus.aceitar);

      notifier.dispose();
    });

    test('setObservacao atualiza manifestação', () async {
      final notifier = ManifestacaoNotifier(
        listarPendentes: () async => _resultSucesso(),
      );

      await notifier.loadManifestacao('nfe-001');
      notifier.setObservacao('Teste obs');

      expect(notifier.manifestacao!.observacao, 'Teste obs');

      notifier.dispose();
    });

    test('setQuantidadeRecebida atualiza manifestação', () async {
      final notifier = ManifestacaoNotifier(
        listarPendentes: () async => _resultSucesso(),
      );

      await notifier.loadManifestacao('nfe-001');
      notifier.setQuantidadeRecebida(50);

      expect(notifier.manifestacao!.quantidadeRecebida, 50);

      notifier.dispose();
    });

    test('setters ignoram quando manifestação é null', () {
      final notifier = ManifestacaoNotifier();

      notifier.setStatus(ManifestacaoStatus.aceitar);
      notifier.setObservacao('teste');
      notifier.setQuantidadeRecebida(10);
      notifier.setMotivoRecusa('motivo');

      expect(notifier.manifestacao, isNull);

      notifier.dispose();
    });
  });

  group('ManifestacaoNotifier - utilitários', () {
    test('clearError limpa mensagem de erro', () async {
      final notifier = ManifestacaoNotifier(
        listarPendentes: () async => _resultErro(),
      );

      await notifier.loadManifestacao('nfe-001');
      expect(notifier.errorMessage, isNotNull);

      notifier.clearError();
      expect(notifier.errorMessage, isNull);

      notifier.dispose();
    });

    test('reset limpa todo o estado', () async {
      final notifier = ManifestacaoNotifier(
        listarPendentes: () async => _resultSucesso(),
      );

      await notifier.loadManifestacao('nfe-001');
      expect(notifier.manifestacao, isNotNull);

      notifier.reset();

      expect(notifier.manifestacao, isNull);
      expect(notifier.errorMessage, isNull);
      expect(notifier.isLoading, false);
      expect(notifier.isSubmitting, false);

      notifier.dispose();
    });

    test('isFormValid false sem status', () async {
      final notifier = ManifestacaoNotifier(
        listarPendentes: () async => _resultSucesso(),
      );

      await notifier.loadManifestacao('nfe-001');
      expect(notifier.isFormValid, false);

      notifier.setStatus(ManifestacaoStatus.aceitar);
      expect(notifier.isFormValid, true);

      notifier.dispose();
    });
  });
}
