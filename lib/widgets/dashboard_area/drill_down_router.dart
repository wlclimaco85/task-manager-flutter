import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';

import '../../utils/security_matrix.dart';
import '../../web/screens/conta_pagar_grid_screen.dart' as web_screens;
import '../../windows/screens/conta_pagar_grid_screen.dart' as windows_screens;
import '../../mobile/screens/conta_pagar_grid_screen.dart' as mobile_screens;
import '../../web/screens/chamado_grid_screen.dart' as web_chamados;
import '../../windows/screens/chamado_grid_screen.dart' as windows_chamados;
import '../../mobile/screens/chamado_grid_screen_dynamic.dart' as mobile_chamados;
import '../../web/screens/kanban_chamados_screen.dart' as web_kanban;
import '../../windows/screens/kanban_chamados_screen.dart' as windows_kanban;
import '../../web/screens/chatMessageListScreen.dart' as web_chat;
import '../../windows/screens/chatMessageListScreen.dart' as windows_chat;
import '../../mobile/screens/chatMessageListScreen.dart' as mobile_chat;

/// Resolve drillDownRota (String vindo do backend) para a tela operacional
/// Flutter real correspondente — Tarefa F1b (Onda 0, contrato de drill-down).
///
/// Se a rota não estiver registrada (string desconhecida ou null), nenhuma
/// ação é tomada — o KpiCard já garante (via onTap condicional) que só chama
/// navigate quando a rota é conhecida, mas o no-op aqui é uma segunda guarda
/// contra crash silencioso.
class DrillDownRouter {
  DrillDownRouter._();

  static final Map<String, WidgetBuilder> _rotas = {
    // Primeira entrada real — prova de conceito (Onda 0/F1b). Reaproveita a
    // tela operacional já existente de contas a pagar, resolvendo a Screen
    // correta por form factor (mesmo padrão condicional usado em main.dart).
    'contaPagarGrid': (context) {
      if (kIsWeb) {
        return web_screens.WebContaPagarGridScreen(hasPermission: (p) => true);
      }
      if (defaultTargetPlatform == TargetPlatform.windows) {
        return windows_screens.WindowsContaPagarGridScreen(hasPermission: (p) => true);
      }
      return mobile_screens.ContaPagarGridScreen(hasPermission: (p) => true);
    },
    'chamadoGrid': (context) {
      final sec = SecurityMatrix.current();
      if (kIsWeb) {
        return web_chamados.WebChamadoGridScreen(
            hasPermission: (action) => _hasPermission(sec, AppScreen.chamados, action));
      }
      if (defaultTargetPlatform == TargetPlatform.windows) {
        return windows_chamados.WindowsChamadoGridScreen(
            hasPermission: (action) => _hasPermission(sec, AppScreen.chamados, action));
      }
      return const mobile_chamados.ChamadosScreenDinamic();
    },
    'kanbanChamados': (context) {
      if (kIsWeb) {
        return const web_kanban.KanbanChamadosScreen();
      }
      if (defaultTargetPlatform == TargetPlatform.windows) {
        return const windows_kanban.KanbanChamadosScreen();
      }
      return const mobile_chamados.ChamadosScreenDinamic();
    },
    'chatList': (context) {
      if (kIsWeb) {
        return const web_chat.WebChatListScreen(userName: '');
      }
      if (defaultTargetPlatform == TargetPlatform.windows) {
        return const windows_chat.WindowsChatListScreen(userName: '');
      }
      return const mobile_chat.ChatListScreen(userName: '');
    },
  };

  /// Resolve o builder para [drillDownRota], ou null se não houver entrada
  /// registrada.
  static WidgetBuilder? resolve(String? drillDownRota) {
    if (drillDownRota == null) return null;
    return _rotas[drillDownRota];
  }

  static bool _hasPermission(SecurityMatrix sec, AppScreen screen, String action) {
    final normalized = action.toLowerCase();
    if (normalized.contains('insert') || normalized.contains('create')) {
      return sec.canInsert(screen);
    }
    if (normalized.contains('edit') || normalized.contains('update')) {
      return sec.canUpdate(screen);
    }
    if (normalized.contains('delete') || normalized.contains('remove')) {
      return sec.canDelete(screen);
    }
    return sec.canView(screen);
  }

  /// Navega para a tela operacional resolvida a partir de [drillDownRota].
  /// periodoInicio/periodoFim são recebidos pelo contrato comum (Onda 0) mas
  /// não são repassados à tela de destino nesta prova de conceito — a tela de
  /// contas a pagar já filtra por TenantContext automaticamente; filtro de
  /// período explícito fica a cargo de cada card dependente quando aplicável.
  static void navigate(
    BuildContext context,
    String? drillDownRota,
    DateTime? periodoInicio,
    DateTime? periodoFim,
  ) {
    final builder = resolve(drillDownRota);
    if (builder == null) return; // no-op silencioso — rota desconhecida
    Navigator.push(context, MaterialPageRoute(builder: builder));
  }
}
