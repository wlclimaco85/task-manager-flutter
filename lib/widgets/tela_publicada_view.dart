import 'package:flutter/material.dart';

import '../services/construtor_telas_service.dart';
import '../services/menu_publicado_service.dart';
import '../services/relatorio_personalizado_service.dart';
import '../utils/app_logger.dart';
import 'planilha_view.dart';
import 'relatorios_personalizados_view.dart';

/// Conteudo de um item publicado no menu. [construirTela] monta a grade dinamica da plataforma (Web/Windows ou Mobile).
class TelaPublicadaView extends StatefulWidget {
  final ItemPublicado? item;
  final Widget Function(TelaConstruida tela) construirTela;

  const TelaPublicadaView({super.key, required this.item, required this.construirTela});

  @override
  State<TelaPublicadaView> createState() => _TelaPublicadaViewState();
}

class _TelaPublicadaViewState extends State<TelaPublicadaView> {
  late final Future<Widget> _conteudo = _montar();

  Future<Widget> _montar() async {
    final item = widget.item;
    if (item == null) return _aviso('Este item não está mais no menu.');
    try {
      switch (item.tipo) {
        case 'PLANILHA':
          return PlanilhaView(modeloId: item.refId);
        case 'RELATORIO':
          final servico = RelatorioPersonalizadoService();
          return RelatorioGerarView(relatorio: await servico.buscar(item.refId), servico: servico);
        case 'TELA':
          for (final t in await ConstrutorTelasService().ativas()) {
            if (t.id == item.refId) return widget.construirTela(t);
          }
          return _aviso('A tela está desativada ou foi excluída.');
        default:
          return _aviso('Atualize o aplicativo para abrir este item.');
      }
    } catch (e) {
      AppLogger.i.warn('TelaPublicadaView: erro ao abrir ${item.menuId}: $e');
      return _aviso('Não foi possível abrir: $e');
    }
  }

  static Widget _aviso(String texto) =>
      Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(texto, textAlign: TextAlign.center)));

  @override
  Widget build(BuildContext context) => FutureBuilder<Widget>(
        future: _conteudo,
        builder: (_, s) => s.data ?? const Center(child: CircularProgressIndicator()),
      );
}
