import 'package:flutter/material.dart';
import 'package:task_manager_flutter/core/design/design_tokens.dart';
import 'package:task_manager_flutter/core/responsive/responsive_helper.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_status.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_status_badge.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';

/// Card reutilizável para renderizar uma NFe com QR code, status, e ações contextuais
/// Responsivo: PopupMenu em mobile, botões inline em tablet/desktop
class NfeCard extends StatelessWidget {
  final NfeModel nfe;
  final Breakpoint breakpoint;
  final VoidCallback? onDetails;
  final VoidCallback? onReprint;
  final VoidCallback? onCancel;

  const NfeCard({
    super.key,
    required this.nfe,
    required this.breakpoint,
    this.onDetails,
    this.onReprint,
    this.onCancel,
  });

  String _formatCurrency(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final integer = parts[0];
    final decimal = parts[1];

    final formatted = integer.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'R\$ $formatted,$decimal';
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  /// Renderiza os botões de ação contextuais (mobile vs desktop/tablet)
  Widget _buildActionButtons() {
    if (breakpoint == Breakpoint.mobile) {
      return PopupMenuButton(
        itemBuilder: (context) => [
          PopupMenuItem(
            child: const Row(
              children: [Icon(Icons.visibility, size: 18), SizedBox(width: 8), Text('Detalhes')],
            ),
            onTap: () {
              Future.microtask(() => onDetails?.call());
            },
          ),
          PopupMenuItem(
            child: const Row(
              children: [Icon(Icons.print, size: 18), SizedBox(width: 8), Text('Reimprimir')],
            ),
            onTap: () {
              Future.microtask(() => onReprint?.call());
            },
          ),
          if (nfe.statusNfe != NfeStatus.cancelada)
            PopupMenuItem(
              child: const Row(
                children: [Icon(Icons.cancel, size: 18, color: DesignTokens.error), SizedBox(width: 8), Text('Cancelar')],
              ),
              onTap: () {
                Future.microtask(() => onCancel?.call());
              },
            ),
        ],
      );
    }

    // Tablet/Desktop: botões inline
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Tooltip(
          message: 'Ver detalhes',
          child: OutlinedButton.icon(
            onPressed: onDetails,
            icon: const Icon(Icons.visibility, size: 16),
            label: const Text('Detalhes'),
          ),
        ),
        Tooltip(
          message: 'Reimprimir DANFE',
          child: OutlinedButton.icon(
            onPressed: onReprint,
            icon: const Icon(Icons.print, size: 16),
            label: const Text('Reimprimir'),
          ),
        ),
        if (nfe.statusNfe != NfeStatus.cancelada)
          Tooltip(
            message: 'Cancelar NFe',
            child: OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel, size: 16),
              label: const Text('Cancelar'),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDetails,
      child: Card(
        margin: const EdgeInsets.all(DesignTokens.spacingSm),
        elevation: 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).cardColor,
          ),
          child: MouseRegion(
            onEnter: (_) => L.d('[NfeCard] Hover sobre NFe ${nfe.id}'),
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Número + Serie + Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NF-e ${nfe.numero}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Série ${nfe.serie}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: DesignTokens.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      NfeStatusBadge(
                        status: nfe.statusNfe,
                        expanded: false,
                        breakpoint: breakpoint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Data + Valor
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data',
                            style: TextStyle(fontSize: 11, color: DesignTokens.textMuted),
                          ),
                          Text(
                            _formatDate(nfe.dataHora),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Valor',
                            style: TextStyle(fontSize: 11, color: DesignTokens.textMuted),
                          ),
                          Text(
                            _formatCurrency(nfe.valores.total),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: DesignTokens.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Cliente (Tomador)
                  Semantics(
                    label: 'Cliente ${nfe.tomador.razaoSocial}',
                    child: Text(
                      'Cliente: ${nfe.tomador.razaoSocial}',
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // CNPJ do cliente
                  Text(
                    'CNPJ: ${nfe.tomador.cnpjCpf}',
                    style: const TextStyle(fontSize: 11, color: DesignTokens.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Semantics(
                    button: true,
                    enabled: true,
                    child: _buildActionButtons(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
