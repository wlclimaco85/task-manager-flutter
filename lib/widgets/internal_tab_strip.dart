import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/open_tab.dart';
import '../utils/grid_colors.dart';

/// Faixa horizontal de abas internas (estilo navegador/IDE), exibida no topo
/// da área de conteúdo do shell principal (entre a sidebar e o conteúdo).
///
/// Reutilizável tanto no shell Windows quanto no Web — a única diferença
/// visual entre as plataformas é a altura e as larguras min/max de cada aba,
/// controladas por [isCompact].
class InternalTabStrip extends StatelessWidget {
  final List<OpenTab> tabs;
  final int activeIndex;
  final ValueChanged<int> onActivate;
  final ValueChanged<int> onClose;

  /// Quando true, usa as métricas "web" (mais compactas).
  final bool isCompact;

  const InternalTabStrip({
    super.key,
    required this.tabs,
    required this.activeIndex,
    required this.onActivate,
    required this.onClose,
    this.isCompact = false,
  });

  double get _height => isCompact ? 38 : 44;
  double get _minWidth => isCompact ? 100 : 120;
  double get _maxWidth => isCompact ? 180 : 200;
  double get _hPadding => isCompact ? 10 : 12;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      decoration: const BoxDecoration(
        color: GridColors.filterBackground,
        border: Border(
          bottom: BorderSide(color: GridColors.divider, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            _TabChip(
              tab: tabs[i],
              isActive: i == activeIndex,
              height: _height,
              minWidth: _minWidth,
              maxWidth: _maxWidth,
              hPadding: _hPadding,
              onTap: () => onActivate(i),
              onClose: () => onClose(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabChip extends StatefulWidget {
  final OpenTab tab;
  final bool isActive;
  final double height;
  final double minWidth;
  final double maxWidth;
  final double hPadding;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabChip({
    required this.tab,
    required this.isActive,
    required this.height,
    required this.minWidth,
    required this.maxWidth,
    required this.hPadding,
    required this.onTap,
    required this.onClose,
  });

  @override
  State<_TabChip> createState() => _TabChipState();
}

class _TabChipState extends State<_TabChip> {
  bool _hovering = false;
  bool _hoveringClose = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;
    final textColor = isActive ? GridColors.textSecondary : GridColors.textMuted;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: widget.minWidth,
            maxWidth: widget.maxWidth,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: widget.height,
            padding: EdgeInsets.symmetric(horizontal: widget.hPadding),
            decoration: BoxDecoration(
              color: isActive
                  ? GridColors.card
                  : (_hovering
                      ? Color.alphaBlend(GridColors.hover, GridColors.filterBackground)
                      : GridColors.filterBackground),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              border: Border(
                top: BorderSide(
                  color: isActive ? GridColors.secondary : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(widget.tab.icon, size: 13, color: isActive ? GridColors.secondary : GridColors.textMuted),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                MouseRegion(
                  onEnter: (_) => setState(() => _hoveringClose = true),
                  onExit: (_) => setState(() => _hoveringClose = false),
                  child: GestureDetector(
                    onTap: () => widget.onClose(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: _hoveringClose
                            ? GridColors.error.withOpacity(0.12)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: widget.height >= 44 ? 16 : 14,
                        color: _hoveringClose ? GridColors.error : GridColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mostra o popup de "limite de abas atingido", permitindo ao usuário fechar
/// uma das abas abertas para liberar espaço para a [newTabLabel].
///
/// Retorna o índice da aba que o usuário escolheu fechar (para que o chamador
/// feche essa aba e abra a nova no lugar), ou `null` se o usuário cancelou.
Future<int?> showTabLimitDialog({
  required BuildContext context,
  required List<OpenTab> tabs,
  required String newTabLabel,
  required bool isCompact,
}) {
  return showDialog<int>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: GridColors.dialogBackground,
        content: SizedBox(
          width: isCompact ? 360 : 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Limite de abas atingido',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: GridColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Você já tem 5 abas abertas. Feche uma para abrir "$newTabLabel".',
                style: const TextStyle(color: GridColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              for (int i = 0; i < tabs.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: GridColors.divider),
                ListTile(
                  visualDensity: VisualDensity.compact,
                  dense: true,
                  leading: FaIcon(tabs[i].icon, color: GridColors.primary, size: 18),
                  title: Text(
                    tabs[i].label,
                    style: const TextStyle(color: GridColors.textSecondary, fontSize: 14),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: GridColors.error),
                    tooltip: 'Fechar esta aba e abrir a nova',
                    onPressed: () => Navigator.of(ctx).pop(i),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: GridColors.textSecondary)),
          ),
        ],
      );
    },
  );
}
