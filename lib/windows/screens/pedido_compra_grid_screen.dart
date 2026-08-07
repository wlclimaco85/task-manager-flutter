import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/pedido_compra_model.dart';
import '../../../services/pedido_compra_service.dart';
import '../../../utils/grid_colors.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show CustomAction;
import '../../../windows/dialogs/pedido_compra_historico_dialog.dart';
import '../../../windows/dialogs/receber_dialog.dart';
import '../../utils/grid_texts.dart';

class WindowsPedidoCompraGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsPedidoCompraGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<PedidoCompra>(
      telaNome: 'pedido_compra',
      hasPermission: hasPermission,
      fromJson: (json) => PedidoCompra.fromJson(json),
      toJson: (a) => a.toJson(),
      customActions: () => [
        CustomAction<PedidoCompra>(
          icon: Icons.send,
          label: GridTexts.issue,
          isVisible: (item) => item.id != null && item.status == 'RASCUNHO',
          onPressed: (context, item) => _showConfirm(
            context,
            GridTexts.issueOrderTitle,
            GridTexts.issueOrderQuestion,
            () => PedidoCompraService.emitir(item.id!),
          ),
        ),
        CustomAction<PedidoCompra>(
          icon: Icons.check_circle,
          label: GridTexts.approve,
          isVisible: (item) => item.id != null && item.status == 'EMITIDO',
          onPressed: (context, item) => _showConfirm(
            context,
            GridTexts.approveOrderTitle,
            GridTexts.approveOrderQuestion,
            () => PedidoCompraService.aprovar(item.id!),
          ),
        ),
        CustomAction<PedidoCompra>(
          icon: Icons.inventory,
          label: GridTexts.receivePartial,
          isVisible: (item) => item.id != null && item.status == 'APROVADO',
          onPressed: (context, item) => _showReceberParcial(context, item),
        ),
        CustomAction<PedidoCompra>(
          icon: Icons.done_all,
          label: GridTexts.receiveTotal,
          isVisible: (item) => item.id != null && (item.status == 'APROVADO' || item.status == 'RECEBIDO_PARCIAL'),
          onPressed: (context, item) => _showConfirm(
            context,
            GridTexts.receiveTotal,
            GridTexts.receiveTotalQuestion,
            () => PedidoCompraService.receberTotal(item.id!),
          ),
        ),
        CustomAction<PedidoCompra>(
          icon: Icons.block,
          label: GridTexts.cancel,
          isVisible: (item) => item.id != null && item.status == 'EMITIDO',
          onPressed: (context, item) => _showConfirm(
            context,
            GridTexts.cancelOrderTitle,
            GridTexts.cancelOrderQuestion,
            () => PedidoCompraService.cancelar(item.id!),
          ),
        ),
        CustomAction<PedidoCompra>(
          icon: Icons.history,
          label: GridTexts.viewHistory,
          isVisible: (item) => item.historico != null && item.historico!.isNotEmpty,
          onPressed: (context, item) => showDialog(
            context: context,
            builder: (_) => PedidoCompraHistoricoDialog(historico: item.historico ?? []),
          ),
        ),
      ],
    );
  }

  void _showReceberParcial(BuildContext context, PedidoCompra pedido) {
    if (pedido.id == null) return;
    final itens = pedido.itens?.map((i) => i.toJson()).toList() ?? [];
    try {
      showDialog(
        context: context,
        builder: (_) => ReceberDialog(
          pedidoId: pedido.id!,
          itens: itens,
          onSaved: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(GridTexts.completedAction(GridTexts.receivePartial)),
                backgroundColor: GridColors.success,
              ),
            );
          },
        ),
      );
    } catch (e) {
      debugPrint('Falha ao abrir recebimento parcial: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(GridTexts.actionFailure(GridTexts.receivePartial)),
          backgroundColor: GridColors.error,
        ),
      );
    }
  }

  Future<void> _showConfirm(
    BuildContext context,
    String title,
    String message,
    Future<bool> Function() action,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(GridTexts.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GridColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(GridTexts.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final success = await action();
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? GridTexts.completedAction(title)
            : GridTexts.actionFailure(title)),
        backgroundColor: success ? GridColors.success : GridColors.error,
      ));
    } catch (e) {
      debugPrint('Falha na acao "$title": $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(GridTexts.actionFailure(title)),
        backgroundColor: GridColors.error,
      ));
    }
  }
}
