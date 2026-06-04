// lib/widgets/notificacoes_drawer.dart
// H6B — Drawer lateral de notificações do sistema (alvarás vencendo, CP/CR vencidos)

import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/grid_colors.dart';
import 'package:http/http.dart' as http;

import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class NotificacoesDrawer extends StatefulWidget {
  final int? empresaId;

  const NotificacoesDrawer({super.key, this.empresaId});

  @override
  State<NotificacoesDrawer> createState() => _NotificacoesDrawerState();
}

class _NotificacoesDrawerState extends State<NotificacoesDrawer> {
  List<Map<String, dynamic>> _notifs = [];
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final empresaParam = widget.empresaId != null ? '?empresaId=${widget.empresaId}' : '';
      final resp = await TenantContext.get('${ApiLinks.baseUrl}/api/notificacoes$empresaParam');
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        List raw = [];
        if (body is List) {
          raw = body;
        } else if (body is Map) {
          raw = body['data'] is List
              ? body['data']
              : body['dados'] ?? body['content'] ?? body['items'] ?? [];
        }
        setState(() => _notifs = raw.whereType<Map>().map((n) => Map<String, dynamic>.from(n)).toList());
      } else {
        setState(() => _erro = 'Erro ao carregar notificações (${resp.statusCode})');
      }
    } catch (e) {
      setState(() => _erro = 'Falha de conexão: $e');
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(children: [
        DrawerHeader(
          decoration: const BoxDecoration(color: GridColors.primary),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const Icon(Icons.notifications, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text('Notificações',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white) ??
                  const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _carregar, tooltip: 'Atualizar'),
          ]),
        ),

        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_erro != null)
          Expanded(child: Center(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 8),
              Text(_erro!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Tentar novamente'),
                onPressed: _carregar,
              ),
            ]),
          )))
        else if (_notifs.isEmpty)
          const Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.notifications_none, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Nenhuma notificação', style: TextStyle(color: Colors.grey)),
          ])))
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _notifs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final n = _notifs[i];
                return ListTile(
                  leading: Icon(_iconeTipo(n['tipo']?.toString()), color: _corTipo(n['tipo']?.toString())),
                  title: Text(n['mensagem']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                  subtitle: n['dataVencimento'] != null
                      ? Text(n['dataVencimento'].toString(), style: const TextStyle(fontSize: 11, color: Colors.grey))
                      : null,
                  trailing: _badgeTipo(n['tipo']?.toString()),
                  dense: true,
                );
              },
            ),
          ),

        // Rodapé com resumo
        if (!_loading && _notifs.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
            child: Text('${_notifs.length} notificação(ões) pendente(s)',
              style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
          ),
      ]),
    );
  }

  IconData _iconeTipo(String? tipo) {
    switch (tipo?.toUpperCase()) {
      case 'ALVARA':           return Icons.assignment_late;
      case 'ALVARA_CADASTRADO': return Icons.assignment_add;
      case 'ALVARA_VENDIDO':   return Icons.sell;
      case 'ALVARA_STATUS':    return Icons.sync_alt;
      case 'CP':               return Icons.payment;
      case 'CR':               return Icons.receipt;
      case 'GED':              return Icons.attach_file;
      case 'COMUNICADO':       return Icons.campaign;
      case 'CHAMADO':          return Icons.support_agent;
      default:                 return Icons.notifications;
    }
  }

  Color _corTipo(String? tipo) {
    switch (tipo?.toUpperCase()) {
      case 'ALVARA':           return Colors.orange;
      case 'ALVARA_CADASTRADO': return Colors.teal;
      case 'ALVARA_VENDIDO':   return Colors.green;
      case 'ALVARA_STATUS':    return Colors.amber.shade700;
      case 'CP':               return Colors.red;
      case 'CR':               return Colors.blue;
      case 'GED':              return Colors.indigo;
      case 'COMUNICADO':       return Colors.purple;
      case 'CHAMADO':          return Colors.deepOrange;
      default:                 return Colors.grey;
    }
  }

  Widget? _badgeTipo(String? tipo) {
    final label = switch (tipo?.toUpperCase()) {
      'ALVARA'            => 'Alvará',
      'ALVARA_CADASTRADO' => 'Cadastrado',
      'ALVARA_VENDIDO'    => 'Vendido',
      'ALVARA_STATUS'     => 'Status',
      'CP'                => 'C.Pagar',
      'CR'                => 'C.Receber',
      'GED'               => 'Arquivo',
      'COMUNICADO'        => 'Comunicado',
      'CHAMADO'           => 'Chamado',
      _                   => null,
    };
    if (label == null) return null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: _corTipo(tipo).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: _corTipo(tipo).withValues(alpha: 0.5))),
      child: Text(label, style: TextStyle(fontSize: 10, color: _corTipo(tipo), fontWeight: FontWeight.bold)),
    );
  }
}

// ─── Botão de sino para usar no AppBar ───────────────────────────────────────
/// Adicione ao AppBar:
///   actions: [NotificacoesSinoButton(empresaId: TenantContext.empresaId)],
/// E ao Scaffold:
///   endDrawer: NotificacoesDrawer(empresaId: TenantContext.empresaId),
class NotificacoesSinoButton extends StatefulWidget {
  final int? empresaId;
  const NotificacoesSinoButton({super.key, this.empresaId});

  @override
  State<NotificacoesSinoButton> createState() => _NotificacoesSinoButtonState();
}

class _NotificacoesSinoButtonState extends State<NotificacoesSinoButton> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _carregarContagem();
  }

  Future<void> _carregarContagem() async {
    try {
      final empresaParam = widget.empresaId != null ? '?empresaId=${widget.empresaId}' : '';
      final resp = await http.get(
        Uri.parse('${ApiLinks.baseUrl}/api/notificacoes$empresaParam'),
        headers: TenantContext.headers,
      );
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final List raw = body is List ? body : (body['data'] ?? body['dados'] ?? []);
        if (mounted) setState(() => _count = raw.length);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      IconButton(
        icon: const Icon(Icons.notifications_outlined),
        tooltip: 'Notificações',
        onPressed: () => Scaffold.of(context).openEndDrawer(),
      ),
      if (_count > 0)
        Positioned(
          right: 6, top: 6,
          child: IgnorePointer(child: Container(
            width: 16, height: 16,
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            child: Center(child: Text(
              _count > 9 ? '9+' : '$_count',
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
          )),
        ),
    ]);
  }
}
