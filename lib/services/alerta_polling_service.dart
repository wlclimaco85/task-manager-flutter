import 'dart:async';
import 'dart:convert';

import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import '../utils/tenant_context.dart';
import 'alerta_novo_detector.dart';
import 'notificador_plataforma.dart';

/// Poll periodico de `/api/notificacoes` que dispara uma notificacao NATIVA
/// da plataforma (toast do Windows/desktop/mobile, ou popup da Notification
/// API no navegador) para cada alerta GENUINAMENTE NOVO desde o inicio do
/// polling -- mesmo com o app em segundo plano/aba sem foco.
///
/// Pedido explicito do usuario: avisar a empresa que esta sendo solicitado
/// o acesso via "browser notificações windows app windows tmb e no app no
/// push de mensagens do aparelho". O push mobile real ja existia via FCM
/// (PushNotificationService) e o Alert in-app ja existia via
/// NotificacoesDrawer -- este servico cobre o que faltava: toast nativo
/// desktop/mobile e popup nativo do navegador.
class AlertaPollingService {
  AlertaPollingService._();
  static final AlertaPollingService instance = AlertaPollingService._();

  static const _intervalo = Duration(seconds: 60);
  final AlertaNovoDetector _detector = const AlertaNovoDetector();
  NotificadorPlataforma? _notificador;

  Timer? _timer;
  // null = ainda nao fez a leitura de baseline (evita notificar alertas que
  // ja existiam antes do polling comecar).
  Set<int>? _idsConhecidos;
  bool _executando = false;

  Future<void> iniciar() async {
    if (_timer != null) return; // ja iniciado (ex.: hot restart de sessao)
    _notificador = criarNotificadorPlataforma();
    await _notificador!.inicializar();
    _timer = Timer.periodic(_intervalo, (_) => _executarCiclo());
    await _executarCiclo();
  }

  /// Chamado no logout -- sem isso, o timer continuaria rodando e
  /// notificando com o TenantContext de uma sessao ja encerrada.
  void parar() {
    _timer?.cancel();
    _timer = null;
    _idsConhecidos = null;
  }

  Future<void> _executarCiclo() async {
    if (_executando) return; // evita sobreposicao se um ciclo demorar
    _executando = true;
    try {
      final atuais = await _buscarNotificacoes();
      if (atuais == null) return; // falha de rede: mantem baseline anterior

      if (_idsConhecidos == null) {
        _idsConhecidos = _detector.extrairIds(atuais);
        return;
      }

      final novos = _detector.detectarNovos(
        idsConhecidos: _idsConhecidos!,
        alertasAtuais: atuais,
      );
      for (final alerta in novos) {
        final texto = alerta['mensagem']?.toString() ?? 'Nova notificação';
        await _notificador?.notificar(titulo: 'Abraço Contabilidade', corpo: texto);
      }
      _idsConhecidos = _detector.extrairIds(atuais);
    } catch (e) {
      L.w('[AlertaPolling] falha no ciclo de polling: $e');
    } finally {
      _executando = false;
    }
  }

  Future<List<Map<String, dynamic>>?> _buscarNotificacoes() async {
    try {
      final empresaId = TenantContext.empresaId;
      final param = empresaId != null ? '?empresaId=$empresaId' : '';
      final resp =
          await TenantContext.get('${ApiLinks.baseUrl}/api/notificacoes$param');
      if (resp.statusCode != 200) return null;

      final body = jsonDecode(resp.body);
      List raw = [];
      if (body is List) {
        raw = body;
      } else if (body is Map) {
        raw = body['data'] is List
            ? body['data']
            : body['dados'] ?? body['content'] ?? body['items'] ?? [];
      }
      return raw.whereType<Map>().map((n) => Map<String, dynamic>.from(n)).toList();
    } catch (e) {
      L.w('[AlertaPolling] falha ao buscar /api/notificacoes: $e');
      return null;
    }
  }
}
