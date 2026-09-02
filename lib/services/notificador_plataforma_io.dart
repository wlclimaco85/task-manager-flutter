// Implementacao para mobile/desktop (Android, iOS, macOS, Linux, Windows).
// NUNCA importado num build Web (selecionado via import condicional em
// notificador_plataforma.dart) -- por isso pode depender livremente do
// plugin nativo flutter_local_notifications.
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notificador_plataforma.dart';
import '../utils/app_logger.dart';

NotificadorPlataforma criarNotificadorPlataformaImpl() => _NotificadorLocalNativo();

class _NotificadorLocalNativo implements NotificadorPlataforma {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _pronto = false;
  int _proximoId = 0;

  static const _canalId = 'solicitacao_acesso';
  static const _canalNome = 'Solicitacoes de acesso';
  static const _canalDescricao =
      'Avisos de novas solicitacoes de acesso aguardando aprovacao';

  @override
  Future<void> inicializar() async {
    if (_pronto) return;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        macOS: DarwinInitializationSettings(),
        linux: LinuxInitializationSettings(defaultActionName: 'Abrir'),
        windows: WindowsInitializationSettings(
          appName: 'Abraço Contabilidade',
          appUserModelId: 'com.appacademia.taskmanagerflutter',
          // GUID fixo do app -- exigido pela API do Windows para
          // identificar o callback de ativacao da notificacao; nao precisa
          // corresponder a nada externo, so ser estavel entre execucoes.
          guid: '2f6e7c2a-9b8a-4a7e-8c5d-6a1b4e7d9f10',
        ),
      );
      await _plugin.initialize(settings);
      _pronto = true;
      // Bug de producao: inicializar() sozinho NUNCA pede a permissao de
      // notificacao em runtime do Android 13+ (API 33+, POST_NOTIFICATIONS)
      // nem do iOS -- sem essa chamada explicita, TODA notificacao nativa
      // fica muda e sem erro nenhum visivel (plugin.show() nao lanca
      // excecao, so nao aparece nada na tela). E' a causa mais provavel de
      // "nao tem notificacao no celular mesmo": o app roda em Android
      // 13/14/15 (maioria dos aparelhos hoje) sem nunca ter pedido a
      // permissao runtime.
      await _pedirPermissaoRuntime();
    } catch (e) {
      L.w('[NotificadorLocal] falha ao inicializar plugin nativo: $e');
    }
  }

  Future<void> _pedirPermissaoRuntime() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (e) {
      L.w('[NotificadorLocal] falha ao pedir permissao runtime de notificacao: $e');
    }
  }

  @override
  Future<void> notificar({required String titulo, required String corpo}) async {
    if (!_pronto) return;
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _canalId,
          _canalNome,
          channelDescription: _canalDescricao,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
        linux: LinuxNotificationDetails(),
      );
      await _plugin.show(_proximoId++, titulo, corpo, details);
    } catch (e) {
      L.w('[NotificadorLocal] falha ao exibir notificacao nativa: $e');
    }
  }

  @override
  Future<String> statusPermissao() async {
    if (!_pronto) return 'default';
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final habilitado = await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled();
        return habilitado == true ? 'granted' : 'denied';
      }
    } catch (e) {
      L.w('[NotificadorLocal] falha ao consultar status de permissao: $e');
    }
    // iOS/macOS/Windows/Linux: plugin nao expoe consulta de status
    // confiavel -- se inicializou sem erro, trata como concedido.
    return 'granted';
  }

  @override
  Future<String> solicitarPermissao() async {
    await inicializar();
    return statusPermissao();
  }
}
