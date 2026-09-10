import 'package:flutter/material.dart';
import 'package:task_manager_flutter/core/design/design_tokens.dart';
import 'package:task_manager_flutter/core/responsive/responsive_helper.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_detail_summary_tab.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_detail_impostos_tab.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_detail_actions_tab.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_items_table.dart';

/// Dialog responsivo com 4 tabs para visualizar detalhes completos de uma NFe
/// Tabs:
/// 1. Resumo (valores + tomador)
/// 2. Itens (tabela responsiva)
/// 3. Impostos (breakdown)
/// 4. Ações (emitir, cancelar, download)
class NfeDetailDialog extends StatefulWidget {
  final NfeModel nfe;

  const NfeDetailDialog({super.key, required this.nfe});

  @override
  State<NfeDetailDialog> createState() => _NfeDetailDialogState();
}

class _NfeDetailDialogState extends State<NfeDetailDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Breakpoint _breakpoint;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _updateBreakpoint();
  }

  void _updateBreakpoint() {
    final width = MediaQuery.of(context).size.width;
    _breakpoint = ResponsiveHelper.getBreakpoint(width);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateBreakpoint();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Determina a largura do dialog baseado no breakpoint
  double _getDialogWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 768) {
      return width * 0.9; // Mobile: 90%
    } else if (width < 1200) {
      return width * 0.7; // Tablet: 70%
    } else {
      return width * 0.6; // Desktop: 60%
    }
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = _getDialogWidth(context);
    final dialogHeight = MediaQuery.of(context).size.height * 0.85;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            // Header com Close button
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingMd,
                vertical: DesignTokens.spacingSm,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalhes NF-e #${widget.nfe.numero}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Série ${widget.nfe.serie}',
                          style: const TextStyle(fontSize: 12, color: DesignTokens.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Fechar',
                  ),
                ],
              ),
            ),

            // TabBar
            TabBar(
              controller: _tabController,
              labelColor: DesignTokens.primary,
              unselectedLabelColor: DesignTokens.textMuted,
              indicatorColor: DesignTokens.primary,
              tabs: const [
                Tab(text: 'Resumo'),
                Tab(text: 'Itens'),
                Tab(text: 'Impostos'),
                Tab(text: 'Ações'),
              ],
            ),

            // TabBarView
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Resumo
                  SingleChildScrollView(
                    child: NfeDetailSummaryTab(nfe: widget.nfe),
                  ),

                  // Tab 2: Itens
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(DesignTokens.spacingMd),
                      child: NfeItemsTable(
                        items: widget.nfe.itens,
                        breakpoint: _breakpoint,
                      ),
                    ),
                  ),

                  // Tab 3: Impostos
                  SingleChildScrollView(
                    child: NfeDetailImpostosTab(nfe: widget.nfe),
                  ),

                  // Tab 4: Ações
                  SingleChildScrollView(
                    child: NfeDetailActionsTab(nfe: widget.nfe),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
