import 'package:flutter/material.dart';
import 'package:task_manager_flutter/core/design/design_tokens.dart';
import 'package:task_manager_flutter/core/responsive/responsive_helper.dart';
import 'package:task_manager_flutter/models/nfe/nfe_status.dart';

/// Badge responsivo que exibe o status de uma NFe
///
/// Suporta 2 variantes:
/// - compact: apenas ícone + cor (pill)
/// - expanded: ícone + label + cor
///
/// Adapta-se por breakpoint (mobile/tablet/desktop) ajustando
/// padding, font size e espaçamento.
class NfeStatusBadge extends StatelessWidget {
  final NfeStatus status;
  final bool expanded;
  final Breakpoint breakpoint;

  const NfeStatusBadge({
    super.key,
    required this.status,
    this.expanded = false,
    required this.breakpoint,
  });

  /// Retorna a cor correspondente ao status
  Color _getStatusColor() {
    switch (status) {
      case NfeStatus.autorizada:
        return DesignTokens.success;
      case NfeStatus.rejeitada:
        return DesignTokens.error;
      case NfeStatus.cancelada:
        return DesignTokens.warning;
      case NfeStatus.pendente:
        return DesignTokens.info;
      case NfeStatus.contingencia:
        return DesignTokens.warning;
      case NfeStatus.erro:
        return DesignTokens.error;
    }
  }

  /// Retorna o ícone correspondente ao status
  IconData _getStatusIcon() {
    switch (status) {
      case NfeStatus.autorizada:
        return Icons.check_circle;
      case NfeStatus.rejeitada:
        return Icons.cancel;
      case NfeStatus.cancelada:
        return Icons.block;
      case NfeStatus.pendente:
        return Icons.schedule;
      case NfeStatus.contingencia:
        return Icons.warning;
      case NfeStatus.erro:
        return Icons.error;
    }
  }

  /// Retorna padding responsivo
  EdgeInsets _getPadding() {
    switch (breakpoint) {
      case Breakpoint.mobile:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case Breakpoint.tablet:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case Breakpoint.desktop:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }

  /// Retorna tamanho de ícone responsivo
  double _getIconSize() {
    switch (breakpoint) {
      case Breakpoint.mobile:
        return 16;
      case Breakpoint.tablet:
        return 18;
      case Breakpoint.desktop:
        return 20;
    }
  }

  /// Retorna tamanho de fonte responsivo
  double _getFontSize() {
    switch (breakpoint) {
      case Breakpoint.mobile:
        return 12;
      case Breakpoint.tablet:
        return 13;
      case Breakpoint.desktop:
        return 14;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    final icon = _getStatusIcon();
    final padding = _getPadding();
    final iconSize = _getIconSize();
    final fontSize = _getFontSize();

    if (!expanded) {
      // Variante compacta — apenas ícone em pill
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: color,
          size: iconSize,
        ),
      );
    }

    // Variante expandida — ícone + label
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: iconSize,
          ),
          SizedBox(width: breakpoint == Breakpoint.mobile ? 4 : 8),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
