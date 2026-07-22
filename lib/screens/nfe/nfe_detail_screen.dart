import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_flutter/core/responsive/responsive_helper.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_status.dart';
import 'package:task_manager_flutter/providers/nfe_notifier.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_items_table.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_status_badge.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';

/// Tela de detalhes de uma NFe com layouts responsivos (3 breakpoints)
///
/// Breakpoints:
/// - Mobile (<600px): Expandables stackadas + FAB menu ações
/// - Tablet (600-1023px): Tab navigation (Dados, Itens, Impostos, Histórico, Ações)
/// - Desktop (>=1024px): 2-col layout (info 60%, ações 40%)
class NfeDetailScreen extends StatefulWidget {
  final int nfeId;

  const NfeDetailScreen({
    super.key,
    required this.nfeId,
  });

  @override
  State<NfeDetailScreen> createState() => _NfeDetailScreenState();
}

class _NfeDetailScreenState extends State<NfeDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late ResponsiveHelper _responsiveHelper;

  @override
  void initState() {
    super.initState();
    _responsiveHelper = ResponsiveHelper();
    // TabController para tablet (5 abas)
    _tabController = TabController(length: 5, vsync: this);

    // Carrega detalhes da NFe ao abrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = context.read<NfeNotifier>();
      notifier.obterNfe(widget.nfeId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final breakpoint = _responsiveHelper.getBreakpoint(screenWidth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da NFe'),
        elevation: 0,
      ),
      body: Consumer<NfeNotifier>(
        builder: (context, notifier, child) {
          final state = notifier.state;

          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.hasError) {
            return _buildErrorState(context);
          }

          final nfe = state.selected;
          if (nfe == null) {
            return _buildEmptyState(context);
          }

          return _buildContent(context, nfe, breakpoint);
        },
      ),
      floatingActionButton: breakpoint == Breakpoint.mobile
          ? _buildMobileActionFab(context)
          : null,
    );
  }

  /// Constrói estado de erro
  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Erro ao carregar NFe'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }

  /// Constrói estado vazio (NFe não encontrada)
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('NFe não encontrada'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }

  /// Constrói conteúdo principal conforme breakpoint
  Widget _buildContent(BuildContext context, NfeModel nfe, Breakpoint breakpoint) {
    switch (breakpoint) {
      case Breakpoint.mobile:
        return _buildMobileLayout(context, nfe);
      case Breakpoint.tablet:
        return _buildTabletLayout(context, nfe);
      case Breakpoint.desktop:
        return _buildDesktopLayout(context, nfe);
    }
  }

  /// Layout mobile (<600px): Expandables stackadas
  Widget _buildMobileLayout(BuildContext context, NfeModel nfe) {
    final breakpoint = Breakpoint.mobile;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderCard(context, nfe, breakpoint),
            const SizedBox(height: 12),
            _buildInfoExpandable(context, nfe, breakpoint),
            const SizedBox(height: 8),
            _buildItensExpandable(context, nfe, breakpoint),
            const SizedBox(height: 8),
            _buildImpostosExpandable(context, nfe, breakpoint),
            const SizedBox(height: 8),
            _buildHistoricoExpandable(context, nfe, breakpoint),
            const SizedBox(height: 40), // Espaço para FAB
          ],
        ),
      ),
    );
  }

  /// Layout tablet (600-1023px): Tab navigation
  Widget _buildTabletLayout(BuildContext context, NfeModel nfe) {
    final breakpoint = Breakpoint.tablet;
    return Column(
      children: [
        _buildHeaderCard(context, nfe, breakpoint),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Dados'),
            Tab(text: 'Itens'),
            Tab(text: 'Impostos'),
            Tab(text: 'Histórico'),
            Tab(text: 'Ações'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Aba 1: Dados
              _buildTabDados(context, nfe, breakpoint),
              // Aba 2: Itens
              _buildTabItens(context, nfe, breakpoint),
              // Aba 3: Impostos
              _buildTabImpostos(context, nfe, breakpoint),
              // Aba 4: Histórico
              _buildTabHistorico(context, nfe, breakpoint),
              // Aba 5: Ações
              _buildTabAcoes(context, nfe, breakpoint),
            ],
          ),
        ),
      ],
    );
  }

  /// Layout desktop (>=1024px): 2 colunas (60/40)
  Widget _buildDesktopLayout(BuildContext context, NfeModel nfe) {
    final breakpoint = Breakpoint.desktop;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderCard(context, nfe, breakpoint),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coluna esquerda (60%): info e impostos
                Expanded(
                  flex: 60,
                  child: Column(
                    children: [
                      _buildInfoCard(context, nfe, breakpoint),
                      const SizedBox(height: 16),
                      _buildImpostosCard(context, nfe, breakpoint),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Coluna direita (40%): itens e ações
                Expanded(
                  flex: 40,
                  child: Column(
                    children: [
                      _buildItensCard(context, nfe, breakpoint),
                      const SizedBox(height: 16),
                      _buildActionButtonsCard(context, nfe, breakpoint),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Card header com número, status, ambiente
  Widget _buildHeaderCard(BuildContext context, NfeModel nfe, Breakpoint breakpoint) {
    final padding = breakpoint == Breakpoint.mobile ? 12.0 : 16.0;
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NFe ${nfe.numeroFormatado}',
                        style: Theme.of(context).textTheme.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nfe.ambienteLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: nfe.isProducao ? Colors.red : Colors.orange,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                NfeStatusBadge(
                  status: nfe.statusNfe,
                  expanded: breakpoint != Breakpoint.mobile,
                  breakpoint: breakpoint,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildInfoColumn('Emitente', nfe.cnpjEmitente),
                _buildInfoColumn('UF', nfe.uf),
                _buildInfoColumn('Data', nfe.dataHora.toString().split(' ')[0]),
                if (nfe.protocolo != null)
                  _buildInfoColumn('Protocolo', nfe.protocolo!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Coluna de informação (helper)
  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  /// Card de informações gerais
  Widget _buildInfoCard(BuildContext context, NfeModel nfe, Breakpoint breakpoint) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informações', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildInfoRow('Tomador', nfe.tomador.razaoSocial),
            _buildInfoRow('CNPJ/CPF', nfe.tomador.cnpjCpf),
            _buildInfoRow('Total', 'R\$ ${nfe.valores.total.toStringAsFixed(2)}', isBold: true),
            _buildInfoRow('Emissão', nfe.dataHora.toString()),
            if (nfe.atualizadoEm != null)
              _buildInfoRow('Atualização', nfe.atualizadoEm.toString()),
          ],
        ),
      ),
    );
  }

  /// Expandable de informações (mobile)
  Widget _buildInfoExpandable(BuildContext context, NfeModel nfe, Breakpoint breakpoint) {
    return Card(
      child: ExpansionTile(
        title: const Text('Informações'),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Tomador', nfe.tomador.razaoSocial),
                _buildInfoRow('CNPJ/CPF', nfe.tomador.cnpjCpf),
                _buildInfoRow('Total', 'R\$ ${nfe.valores.total.toStringAsFixed(2)}', isBold: true),
                _buildInfoRow('Emissão', nfe.dataHora.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card de itens (desktop/tablet)
  Widget _buildItensCard(BuildContext context, NfeModel nfe, Breakpoint breakpoint) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Itens', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            NfeItemsTable(
              items: nfe.itens,
              breakpoint: breakpoint,
              editable: false,
            ),
          ],
        ),
      ),
    );
  }

  /// Expandable de itens (mobile)
  Widget _buildItensExpandable(BuildContext context, NfeModel nfe, Breakpoint breakpoint) {
    return Card(
      child: ExpansionTile(
        title: const Text('Itens (${0})'),
        initiallyExpanded: false,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: NfeItemsTable(
              items: nfe.itens,
              breakpoint: breakpoint,
              editable: false,
            ),
          ),
        ],
      ),
    );
  }

  /// Card de impostos (desktop/tablet)
  Widget _buildImpostosCard(BuildContext context, NfeModel nfe, Breakpoint breakpoint) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Impostos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildImpostosContent(context, nfe),
          ],
        ),
      ),
    );
  }

  /// Expandable de impostos (mobile)
  Widget _buildImpostosExpandable(BuildContext context, NfeModel nfe, Breakpoint breakpoint) {
    return Card(
      child: ExpansionTile(
        title: const Text('Impostos'),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildImpostosContent(context, nfe),
          ),
        ],
      ),
    );
  }

  /// Conteúdo de impostos (reutilizável)
  Widget _buildImpostosContent(BuildContext context, NfeModel nfe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('ICMS', 'R\$ ${nfe.valores.totalIcms.toStringAsFixed(2)}'),
        _buildInfoRow('PIS', 'R\$ ${nfe.valores.totalPis.toStringAsFixed(2)}'),
        _buildInfoRow('COFINS', 'R\$ ${nfe.valores.totalCofins.toStringAsFixed(2)}'),
        const Divider(),
        _buildInfoRow('Subtotal', 'R\$ ${nfe.valores.subtotal.toStringAsFixed(2)}'),
        _buildInfoRow('Desconto', 'R\$ ${nfe.valores.desconto.toStringAsFixed(2)}'),
        const SizedBox(height: 8),
        _buildInfoRow('Total', 'R\$ ${nfe.valores.total.toStringAsFixed(2)}', isBold: true),
      ],
    );
  }

  /// Expandable de histórico (mobile)
  Widget _buildHistoricoExpandable(BuildContext context, NfeModel nfe, Breakpoint breakpoint) {
    return Card(
      child: ExpansionTile(
        title: const Text('Histórico'),
        children: [
          _buildHistoricoContent(context, nfe),
        ],
      ),
    );
  }

  /// Conteúdo de histórico (timeline)
  Widget _buildHistoricoContent(BuildContext context, NfeModel nfe) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimelineItem(
            'Criada',
            nfe.dataHora,
            Icons.add_circle,
            Colors.blue,
          ),
          if (nfe.statusNfe == NfeStatus.autorizada)
            _buildTimelineItem(
              'Autorizada',
              nfe.atualizadoEm ?? DateTime.now(),
              Icons.check_circle,
              Colors.green,
            ),
          if (nfe.statusNfe == NfeStatus.rejeitada)
            _buildTimelineItem(
              'Rejeitada',
              nfe.atualizadoEm ?? DateTime.now(),
              Icons.cancel,
              Colors.red,
            ),
        ],
      ),
    );
  }

  /// Item de timeline (helper)
  Widget _buildTimelineItem(
    String label,
    DateTime dateTime,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  dateTime.toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card de ações (desktop/tablet)
  Widget _buildActionButtonsCard(BuildContext context, NfeModel nfe, Breakpoint breakpoint) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Ações', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildActionButtonsList(context, nfe),
          ],
        ),
      ),
    );
  }

  /// Lista de botões de ação (reutilizável)
  Widget _buildActionButtonsList(BuildContext context, NfeModel nfe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (nfe.statusNfe == NfeStatus.pendente)
          ElevatedButton.icon(
            onPressed: () => _handleEmitir(context, nfe),
            icon: const Icon(Icons.send),
            label: const Text('Emitir'),
          ),
        if (nfe.statusNfe == NfeStatus.autorizada) ...[
          ElevatedButton.icon(
            onPressed: () => _handleCancelar(context, nfe),
            icon: const Icon(Icons.close),
            label: const Text('Cancelar'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
          const SizedBox(height: 8),
        ],
        if (nfe.canDownloadPdf)
          OutlinedButton.icon(
            onPressed: () => _handleDownloadPdf(context, nfe),
            icon: const Icon(Icons.download),
            label: const Text('Download PDF'),
          ),
        if (nfe.canViewXml)
          OutlinedButton.icon(
            onPressed: () => _handleViewXml(context, nfe),
            icon: const Icon(Icons.code),
            label: const Text('Visualizar XML'),
          ),
        OutlinedButton.icon(
          onPressed: () => _handleEnviarEmail(context, nfe),
          icon: const Icon(Icons.email),
          label: const Text('Enviar por Email'),
        ),
      ],
    );
  }

  /// FAB flutuante com menu popup (mobile)
  Widget _buildMobileActionFab(BuildContext context) {
    return Consumer<NfeNotifier>(
      builder: (context, notifier, _) {
        final nfe = notifier.state.selected;
        if (nfe == null) return const SizedBox.shrink();

        return FloatingActionButton(
          onPressed: () => _showActionBottomSheet(context, nfe),
          tooltip: 'Ações',
          child: const Icon(Icons.more_vert),
        );
      },
    );
  }

  /// Bottom sheet com ações (mobile)
  void _showActionBottomSheet(BuildContext context, NfeModel nfe) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Ações', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildActionButtonsList(context, nfe),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }

  /// Aba Dados (tablet)
  Widget _buildTabDados(BuildContext context, NfeModel nfe, Breakpoint breakpoint) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoCard(context, nfe, breakpoint),
            const SizedBox(height: 16),
            _buildImpostosCard(context, nfe, breakpoint),
          ],
        ),
      ),
    );
  }

  /// Aba Itens (tablet)
  Widget _buildTabItens(BuildContext context, NfeModel nfe, Breakpoint breakpoint) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildItensCard(context, nfe, breakpoint),
      ),
    );
  }

  /// Aba Impostos (tablet)
  Widget _buildTabImpostos(BuildContext context, NfeModel nfe, Breakpoint breakpoint) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildImpostosCard(context, nfe, breakpoint),
      ),
    );
  }

  /// Aba Histórico (tablet)
  Widget _buildTabHistorico(BuildContext context, NfeModel nfe, Breakpoint breakpoint) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: _buildHistoricoContent(context, nfe),
        ),
      ),
    );
  }

  /// Aba Ações (tablet)
  Widget _buildTabAcoes(BuildContext context, NfeModel nfe, Breakpoint breakpoint) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildActionButtonsCard(context, nfe, breakpoint),
      ),
    );
  }

  /// Handlers de ações
  void _handleEmitir(BuildContext context, NfeModel nfe) {
    L.d('[NfeDetailScreen] Emitindo NFe ${nfe.id}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emissão em implementação')),
    );
  }

  void _handleCancelar(BuildContext context, NfeModel nfe) {
    L.d('[NfeDetailScreen] Cancelando NFe ${nfe.id}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cancelamento em implementação')),
    );
  }

  void _handleDownloadPdf(BuildContext context, NfeModel nfe) {
    L.d('[NfeDetailScreen] Download PDF NFe ${nfe.id}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download em implementação')),
    );
  }

  void _handleViewXml(BuildContext context, NfeModel nfe) {
    L.d('[NfeDetailScreen] Visualizando XML NFe ${nfe.id}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('XML viewer em implementação')),
    );
  }

  void _handleEnviarEmail(BuildContext context, NfeModel nfe) {
    L.d('[NfeDetailScreen] Enviando email NFe ${nfe.id}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email em implementação')),
    );
  }

  /// Helper: linha de informação
  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isBold ? 14 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
