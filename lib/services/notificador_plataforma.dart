import 'notificador_plataforma_io.dart'
    if (dart.library.html) 'notificador_plataforma_web.dart' as impl;

/// Contrato para disparar uma notificacao nativa da PLATAFORMA (toast do
/// SO no Windows/desktop/mobile, ou a Notification API do navegador na
/// Web) -- diferente do Alert in-app (NotificacoesDrawer) e do push mobile
/// via FCM (PushNotificationService), que ja existiam e continuam intactos.
///
/// A implementacao concreta e escolhida em TEMPO DE COMPILACAO via import
/// condicional (`if (dart.library.html)`): um build Web nunca inclui o
/// plugin nativo flutter_local_notifications, e um build mobile/desktop
/// nunca inclui dart:html.
abstract class NotificadorPlataforma {
  /// Prepara a plataforma (inicializa o plugin nativo ou pede permissao de
  /// notificacao do navegador). Deve ser chamado uma vez, apos login.
  /// Falhas sao engolidas e logadas -- nunca podem derrubar o boot do app.
  Future<void> inicializar();

  /// Exibe uma notificacao. Se [inicializar] falhou ou ainda nao rodou,
  /// e um no-op silencioso.
  Future<void> notificar({required String titulo, required String corpo});
}

NotificadorPlataforma criarNotificadorPlataforma() =>
    impl.criarNotificadorPlataformaImpl();
