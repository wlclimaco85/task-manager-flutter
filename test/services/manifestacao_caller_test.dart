import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/services/manifestacao_caller.dart';
import 'package:task_manager_flutter/utils/api_links.dart';

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
    // FIX (achado real do code review - WR-02): estes 4 testes faziam uma
    // chamada de REDE REAL (sem mock) contra a URL default de dev
    // (http://127.0.0.1:9001, ver lib/utils/api_links.dart) — medido ~2s
    // de wall-clock por teste. Se um backend local estivesse rodando
    // nessa porta durante `flutter test`, o teste passaria a depender de
    // estado externo (instável) e ainda por cima poderia gravar dado
    // sintético num banco real. Corrigido com http.runWithClient/
    // MockClient simulando falha de rede (SocketException), mesmo padrão
    // já usado no restante deste arquivo — determinístico e sem I/O real.
    test('aceita nfeChave/tipoEvento/justificativa (contrato real do backend)',
        () async {
      final mockClient = MockClient((request) async {
        throw const SocketException('sem rede (simulado)');
      });

      final result = await http.runWithClient(
        () => ManifestacaoCaller.registrarManifestacao(
          nfeChave: '3' * 44,
          tipoEvento: ManifestacaoTipoEvento.confirmacao,
          justificativa: 'Mercadoria recebida conforme nota fiscal emitida',
        ),
        () => mockClient,
      );

      // O caller nunca deve lançar exceção — sempre retorna um
      // ManifestacaoResult, mesmo quando a chamada HTTP falha.
      expect(result, isA<ManifestacaoResult>());
      expect(result.success, isFalse);
      expect(result.message, isNotNull);
    });

    test('funciona sem justificativa quando tipo não exige (CIENCIA)',
        () async {
      final mockClient = MockClient((request) async {
        throw const SocketException('sem rede (simulado)');
      });

      final result = await http.runWithClient(
        () => ManifestacaoCaller.registrarManifestacao(
          nfeChave: '4' * 44,
          tipoEvento: ManifestacaoTipoEvento.ciencia,
        ),
        () => mockClient,
      );

      expect(result, isA<ManifestacaoResult>());
      expect(result.success, isFalse);
    });
  });

  group('ManifestacaoCaller.listarPendentes/listarHistorico - resiliência',
      () {
    test('listarPendentes nunca lança exceção mesmo sem rede', () async {
      final mockClient = MockClient((request) async {
        throw const SocketException('sem rede (simulado)');
      });

      final result = await http.runWithClient(
        () => ManifestacaoCaller.listarPendentes(),
        () => mockClient,
      );
      expect(result, isA<ManifestacaoResult>());
      expect(result.success, isFalse);
    });

    test('listarHistorico nunca lança exceção mesmo sem rede', () async {
      final mockClient = MockClient((request) async {
        throw const SocketException('sem rede (simulado)');
      });

      final result = await http.runWithClient(
        () => ManifestacaoCaller.listarHistorico(),
        () => mockClient,
      );
      expect(result, isA<ManifestacaoResult>());
      expect(result.success, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // P2-502 (coverage/E2E/a11y, 3ª reprovação de QA): os testes acima só
  // exercitam o caminho de EXCEÇÃO (try/catch) porque não há mock de rede —
  // o caminho de SUCESSO real (parsing de response.statusCode == 200,
  // extração de list/data/conteudo/resultado, extração de mensagem de erro
  // do JSON em respostas != 200) nunca era exercitado, explicando a
  // cobertura baixa medida pelo QA (~49%). http.runWithClient (pacote
  // http/testing.dart, já é dependência transitiva de package:http, sem
  // dependência nova) intercepta as chamadas http.get/post de nível
  // superior usadas por TenantContext via Zone — não exige nenhuma mudança
  // no código de produção (TenantContext/ManifestacaoCaller continuam
  // exatamente como estão).
  // ─────────────────────────────────────────────────────────────────────
  group('ManifestacaoCaller.listarPendentes - caminho de sucesso real (mock HTTP)',
      () {
    test('resposta 200 com Map{"data": [...]} extrai a lista de dentro de "data"',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('/manifestacao/pendentes'));
        return http.Response(
          jsonEncode({
            'data': [
              {'nfeChave': '1' * 44, 'tipoEvento': 'CIENCIA', 'status': 'PENDENTE'},
              {'nfeChave': '2' * 44, 'tipoEvento': 'CONFIRMACAO', 'status': 'PENDENTE'},
            ]
          }),
          200,
        );
      });

      final result = await http.runWithClient(
        () => ManifestacaoCaller.listarPendentes(),
        () => mockClient,
      );

      expect(result.success, isTrue);
      expect(result.statusCode, 200);
      expect(result.list, hasLength(2));
      expect(result.list!.first['nfeChave'], '1' * 44);
    });

    test('resposta 200 com List direta (sem envelope) extrai a lista',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {'nfeChave': '3' * 44, 'tipoEvento': 'DESCONHECIMENTO', 'status': 'PENDENTE'},
          ]),
          200,
        );
      });

      final result = await http.runWithClient(
        () => ManifestacaoCaller.listarPendentes(),
        () => mockClient,
      );

      expect(result.success, isTrue);
      expect(result.list, hasLength(1));
      expect(result.list!.first['tipoEvento'], 'DESCONHECIMENTO');
    });

    test('resposta 200 com corpo vazio não quebra (lista vazia)', () async {
      final mockClient = MockClient((request) async {
        return http.Response('', 200);
      });

      final result = await http.runWithClient(
        () => ManifestacaoCaller.listarPendentes(),
        () => mockClient,
      );

      expect(result.success, isTrue);
      expect(result.list, isEmpty);
    });

    test('resposta 500 com corpo JSON extrai "mensagem" do backend',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'mensagem': 'Tenant não autorizado para esta operação'}),
          500,
        );
      });

      final result = await http.runWithClient(
        () => ManifestacaoCaller.listarPendentes(),
        () => mockClient,
      );

      expect(result.success, isFalse);
      expect(result.statusCode, 500);
      expect(result.message, 'Tenant não autorizado para esta operação');
    });

    test('resposta 403 com corpo NÃO-JSON cai no fallback genérico sem lançar exceção',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response('<html>Forbidden</html>', 403);
      });

      final result = await http.runWithClient(
        () => ManifestacaoCaller.listarPendentes(),
        () => mockClient,
      );

      expect(result.success, isFalse);
      expect(result.statusCode, 403);
      expect(result.message, contains('403'));
    });
  });

  group('ManifestacaoCaller.listarHistorico - caminho de sucesso real (mock HTTP)',
      () {
    test('resposta 200 com Map{"conteudo": [...]} extrai a lista de dentro de "conteudo"',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('/manifestacao/historico'));
        return http.Response(
          jsonEncode({
            'conteudo': [
              {
                'nfeChave': '5' * 44,
                'tipoEvento': 'CIENCIA',
                'status': 'ENVIADO',
                'protocolo': '123456789012345',
              },
              {
                'nfeChave': '6' * 44,
                'tipoEvento': 'NAO_REALIZADA',
                'status': 'ERRO',
                'erro': 'Prazo de manifestação expirado',
              },
            ]
          }),
          200,
        );
      });

      final result = await http.runWithClient(
        () => ManifestacaoCaller.listarHistorico(),
        () => mockClient,
      );

      expect(result.success, isTrue);
      expect(result.list, hasLength(2));
      expect(result.list!.last['erro'], 'Prazo de manifestação expirado');
    });

    test('resposta 404 com corpo JSON extrai "message" (chave alternativa)',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Histórico não encontrado'}), 404);
      });

      final result = await http.runWithClient(
        () => ManifestacaoCaller.listarHistorico(),
        () => mockClient,
      );

      expect(result.success, isFalse);
      expect(result.message, 'Histórico não encontrado');
    });
  });

  group(
      'ManifestacaoCaller.registrarManifestacao - caminho de sucesso real (mock HTTP)',
      () {
    test('POST com nfeChave/tipoEvento/justificativa no body e resposta 200 = sucesso',
        () async {
      Map<String, dynamic>? bodyEnviado;
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('/api/fiscal/manifestacao'));
        expect(request.method, 'POST');
        bodyEnviado = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({'protocolo': '999888777666555', 'status': 'ENVIADO'}),
          200,
        );
      });

      final result = await http.runWithClient(
        () => ManifestacaoCaller.registrarManifestacao(
          nfeChave: '7' * 44,
          tipoEvento: ManifestacaoTipoEvento.confirmacao,
          justificativa: 'Mercadoria recebida conforme nota fiscal',
        ),
        () => mockClient,
      );

      expect(result.success, isTrue);
      expect(result.data?['protocolo'], '999888777666555');
      // Prova o contrato real do backend (nfeChave/tipoEvento/justificativa,
      // não chave/tipo do vocabulário original do card).
      expect(bodyEnviado?['nfeChave'], '7' * 44);
      expect(bodyEnviado?['tipoEvento'], 'CONFIRMACAO');
      expect(bodyEnviado?['justificativa'],
          'Mercadoria recebida conforme nota fiscal');
    });

    test('POST sem justificativa (tipo CIENCIA) omite a chave "justificativa" do body',
        () async {
      Map<String, dynamic>? bodyEnviado;
      final mockClient = MockClient((request) async {
        bodyEnviado = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'status': 'ENVIADO'}), 201);
      });

      final result = await http.runWithClient(
        () => ManifestacaoCaller.registrarManifestacao(
          nfeChave: '8' * 44,
          tipoEvento: ManifestacaoTipoEvento.ciencia,
        ),
        () => mockClient,
      );

      expect(result.success, isTrue);
      expect(result.statusCode, 201);
      expect(bodyEnviado?.containsKey('justificativa'), isFalse);
    });

    test('resposta 400 extrai "error" do corpo JSON (rejeição de negócio do backend)',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'NFe já manifestada anteriormente'}),
          400,
        );
      });

      final result = await http.runWithClient(
        () => ManifestacaoCaller.registrarManifestacao(
          nfeChave: '9' * 44,
          tipoEvento: ManifestacaoTipoEvento.ciencia,
        ),
        () => mockClient,
      );

      expect(result.success, isFalse);
      expect(result.statusCode, 400);
      expect(result.message, 'NFe já manifestada anteriormente');
    });

    test('URL de registro bate com ApiLinks.manifestacaoRegistrar (contrato real)',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({}), 200);
      });

      await http.runWithClient(
        () => ManifestacaoCaller.registrarManifestacao(
          nfeChave: '1' * 44,
          tipoEvento: ManifestacaoTipoEvento.ciencia,
        ),
        () => mockClient,
      );

      // Confirma que o endpoint usado é exatamente o do contrato documentado
      // (POST /api/fiscal/manifestacao), não um endpoint inventado.
      expect(ApiLinks.manifestacaoRegistrar, endsWith('/api/fiscal/manifestacao'));
    });
  });
}
