import 'package:flutter/material.dart';
import 'package:task_manager_flutter/core/responsive/responsive_helper.dart';
import 'package:task_manager_flutter/models/nfe/nfe_status.dart';

class NfeStatusBadge extends StatelessWidget {
  final NfeStatus status;
  final bool expanded;
  final Breakpoint breakpoint;

  const NfeStatusBadge({
    super.key,
    required this.status,
    required this.expanded,
    required this.breakpoint,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorForStatus(status);
    return Container(
      constraints: BoxConstraints(
        minWidth: expanded ? 96 : 72,
        maxWidth: breakpoint == Breakpoint.mobile ? 120 : 160,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _colorForStatus(NfeStatus status) {
    return switch (status) {
      NfeStatus.autorizada => const Color(0xFF047857),
      NfeStatus.rejeitada => const Color(0xFFB91C1C),
      NfeStatus.cancelada => const Color(0xFF6B7280),
      NfeStatus.contingencia => const Color(0xFFB45309),
      NfeStatus.erro => const Color(0xFF991B1B),
      NfeStatus.pendente => const Color(0xFF1D4ED8),
    };
  }
}
