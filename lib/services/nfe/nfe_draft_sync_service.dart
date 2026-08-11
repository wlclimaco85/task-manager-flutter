import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/models/nfe/nfe_draft_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_draft_status.dart';
import 'package:task_manager_flutter/repositories/nfe_draft_repository.dart';
import 'package:task_manager_flutter/utils/api_links.dart';
import 'package:task_manager_flutter/utils/network_failure_detector.dart';
import 'package:task_manager_flutter/utils/tenant_context.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';

/// Resultado de uma tentativa de sincronização de rascunho.
enum NfeDraftSyncResult { enviado, conflito, erro, semConexao }

/// Assinaturas injetáveis para permitir teste sem HTTP real (não depende de
/// mocks pesados: por padrão aponta para `TenantContext`, que é o caminho
/// real já usado nas telas de "Emitir" NFe).
typedef _PostFn = Future<http.Response> Function(
    String url, Map<String, dynamic> body);
typedef _GetFn = Future<http.Response> Function(String url);

/// Serviço que tenta sincronizar rascunhos offline de NFe (card W3R3) quando
/// a conexão volta.
///
/// Regra de conflito (obrigatória): nunca sobrescrever uma NFe já
/// transmitida/autorizada no servidor. Antes de reenviar, consulta o status
/// atual da NFe referenciada; se já estiver autorizada/cancelada (ou seja,
/// já processada pelo servidor por outra sessão/dispositivo), marca o
/// rascunho como conflito em vez de reenviar.
class NfeDraftSyncService {
  final NfeDraftRepository _repository;
  final _PostFn _post;
  final _GetFn _get;

  NfeDraftSyncService({
    NfeDraftRepository? repository,
    _PostFn? postFn,
    _GetFn? getFn,
  })  : _repository = repository ?? NfeDraftRepository(),
        _post = postFn ?? TenantContext.post,
        _get = getFn ?? TenantContext.get;

  static const _statusJaProcessados = {'AUTORIZADA', 'CANCELADA'};

  /// Sincroniza um único rascunho. Retorna o resultado para a UI decidir o
  /// que exibir (ex.: abrir diálogo de conflito).
  Future<NfeDraftSyncResult> sincronizar(NfeDraftModel draft) async {
    await _repository.atualizarStatus(draft.id,
        status: NfeDraftStatus.enviando, limparMensagemErro: true);

    try {
      final conflita = await _existeNfeJaProcessadaNoServidor(
          draft.nfeIdReferencia);
      if (conflita) {
        await _repository.atualizarStatus(
          draft.id,
          status: NfeDraftStatus.conflito,
          mensagemErro:
              'Já existe uma NFe transmitida no servidor com este identificador. '
              'O rascunho local não pode substituir uma nota já emitida.',
        );
        L.w('[NfeDraftSyncService] Conflito no rascunho ${draft.id} (nfe=${draft.nfeIdReferencia})');
        return NfeDraftSyncResult.conflito;
      }

      final url = ApiLinks.emitirNfe(draft.nfeIdReferencia);
      final response = await _post(url, draft.dadosFormulario);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _repository.atualizarStatus(draft.id,
            status: NfeDraftStatus.enviado, limparMensagemErro: true);
        // Rascunho enviado com sucesso: remove da fila local (não precisa
        // mais ocupar a box, já virou NFe real no servidor).
        await _repository.excluirRascunho(draft.id);
        L.d('[NfeDraftSyncService] Rascunho ${draft.id} sincronizado com sucesso');
        return NfeDraftSyncResult.enviado;
      }

      String msg = 'Erro ${response.statusCode} ao sincronizar';
      try {
        final body = jsonDecode(response.body);
        msg = body['message']?.toString() ??
            body['mensagem']?.toString() ??
            body['error']?.toString() ??
            msg;
      } catch (_) {}
      await _repository.atualizarStatus(draft.id,
          status: NfeDraftStatus.erro, mensagemErro: msg);
      return NfeDraftSyncResult.erro;
    } catch (e) {
      if (NetworkFailureDetector.isConnectivityError(e)) {
        // Ainda sem conexão: mantém como rascunho (não como erro) para não
        // confundir "erro de negócio" com "continua offline".
        await _repository.atualizarStatus(
          draft.id,
          status: NfeDraftStatus.rascunho,
          mensagemErro: null,
          limparMensagemErro: true,
        );
        return NfeDraftSyncResult.semConexao;
      }
      L.e('[NfeDraftSyncService] Erro inesperado ao sincronizar ${draft.id}: $e');
      await _repository.atualizarStatus(draft.id,
          status: NfeDraftStatus.erro, mensagemErro: 'Erro inesperado: $e');
      return NfeDraftSyncResult.erro;
    }
  }

  /// Sincroniza todos os rascunhos pendentes (status rascunho/erro).
  Future<Map<String, NfeDraftSyncResult>> sincronizarPendentes() async {
    final pendentes = (await _repository.listarRascunhos()).where((d) =>
        d.status == NfeDraftStatus.rascunho || d.status == NfeDraftStatus.erro);

    final resultados = <String, NfeDraftSyncResult>{};
    for (final draft in pendentes) {
      resultados[draft.id] = await sincronizar(draft);
    }
    return resultados;
  }

  /// Verifica se a NFe referenciada já foi processada (autorizada/cancelada)
  /// no servidor por outra via — usado para bloquear sobrescrita.
  Future<bool> _existeNfeJaProcessadaNoServidor(String nfeId) async {
    if (nfeId.isEmpty) return false;
    final response = await _get(ApiLinks.nfeById(nfeId));
    if (response.statusCode != 200) return false;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final status =
          (body['statusNfe'] ?? body['status'])?.toString().toUpperCase();
      return status != null && _statusJaProcessados.contains(status);
    } catch (_) {
      return false;
    }
  }
}
