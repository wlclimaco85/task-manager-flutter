import 'dart:convert';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:task_manager_flutter/core/design/design_tokens.dart';
import 'package:task_manager_flutter/core/responsive/responsive_helper.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_status.dart';
import 'package:task_manager_flutter/providers/nfe_notifier.dart';
import 'package:task_manager_flutter/utils/api_links.dart';
import 'package:task_manager_flutter/utils/tenant_context.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_status_badge.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_filter_chip.dart';
import 'package:task_manager_flutter/screens/nfe/nfe_detail_screen.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';

/// Tela responsiva de listagem de NFes com 3 layouts
/// - Mobile (<600): FAB stack, lista vertical compacta
/// - Tablet (600-1024): Card list, drawer navegação
/// - Desktop (>=1024): DataTable com sorting, filtros inline
class NfeListScreen extends StatefulWidget {
  const NfeListScreen({super.key});

  @override
  State<NfeListScreen> createState() => _NfeListScreenState();
}

class _NfeListScreenState extends State<NfeListScreen> {
  final _scrollController = ScrollController();
  late Breakpoint _currentBreakpoint;

  String? _selectedStatus;
  DateTime? _dataInicio;
  DateTime? _dataFim;
  String? _clienteCnpj;
  String _sortBy = 'dataHora';
  bool _sortAsc = false;

  @override
  void initState() {
    super.initState();
    _determineBreakpoint();
    _loadNfes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _determineBreakpoint();
  }

  void _determineBreakpoint() {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      _currentBreakpoint = Breakpoint.mobile;
    } else if (width < 1024) {
      _currentBreakpoint = Breakpoint.tablet;
    } else {
      _currentBreakpoint = Breakpoint.desktop;
    }
  }

  Future<void> _loadNfes() async {
    L.d('[NfeListScreen] Carregando NFes inicialmente');
    final notifier = context.read<NfeNotifier>();
    await notifier.listarNfe(
      page: 1,
      pageSize: 10,
      status: _selectedStatus,
      dataInicio: _dataInicio,
      dataFim: _dataFim,
      clienteCnpj: _clienteCnpj,
    );
  }

  Future<void> _applyFilters() async {
    L.d('[NfeListScreen] Aplicando filtros');
    final notifier = context.read<NfeNotifier>();
    await notifier.listarNfe(
      page: 1,
      pageSize: 10,
      status: _selectedStatus,
      dataInicio: _dataInicio,
      dataFim: _dataFim,
      clienteCnpj: _clienteCnpj,
    );
  }

  void _clearFilters() {
    L.d('[NfeListScreen] Limpando filtros');
    setState(() {
      _selectedStatus = null;
      _dataInicio = null;
      _dataFim = null;
      _clienteCnpj = null;
    });
    _applyFilters();
  }

  Future<void> _nextPage(NfeNotifier notifier) async {
    L.d('[NfeListScreen] Próxima página');
    await notifier.proximaPagina(
      status: _selectedStatus,
      dataInicio: _dataInicio,
      dataFim: _dataFim,
      clienteCnpj: _clienteCnpj,
    );
  }

  Future<void> _previousPage(NfeNotifier notifier) async {
    L.d('[NfeListScreen] Página anterior');
    await notifier.paginaAnterior(
      status: _selectedStatus,
      dataInicio: _dataInicio,
      dataFim: _dataFim,
      clienteCnpj: _clienteCnpj,
    );
  }

  String _formatCurrency(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final integer = parts[0];
    final decimal = parts[1];

    // Adiciona separador de milhares (ponto em pt_BR)
    final formatted = integer.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'R\$ $formatted,$decimal';
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Widget _buildFilterChip(String label, IconData icon, VoidCallback onRemove) {
    return NfeFilterChip(
      label: label,
      icon: icon,
      onRemoved: onRemove,
      breakpoint: _currentBreakpoint,
    );
  }

  Widget _buildFiltersBar() {
    final activeFilters = <Widget>[];

    if (_selectedStatus != null) {
      activeFilters.add(
        _buildFilterChip(
          _selectedStatus!,
          Icons.filter_alt,
          () => setState(() => _selectedStatus = null),
        ),
      );
    }

    if (_dataInicio != null) {
      activeFilters.add(
        _buildFilterChip(
          'De ${_formatDate(_dataInicio!)}',
          Icons.calendar_today,
          () => setState(() => _dataInicio = null),
        ),
      );
    }

    if (_dataFim != null) {
      activeFilters.add(
        _buildFilterChip(
          'Até ${_formatDate(_dataFim!)}',
          Icons.calendar_today,
          () => setState(() => _dataFim = null),
        ),
      );
    }

    if (activeFilters.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingMd,
        vertical: DesignTokens.spacingSm,
      ),
      child: Wrap(
        spacing: DesignTokens.spacingSm,
        runSpacing: DesignTokens.spacingSm,
        children: [
          ...activeFilters,
          TextButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.clear_all),
            label: const Text('Limpar tudo'),
          ),
        ],
      ),
    );
  }

  Widget _buildNfeCard(NfeModel nfe, {bool isGridView = false}) {
    if (isGridView && _currentBreakpoint == Breakpoint.desktop) {
      // Grid card for desktop
      return Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QR Code area (protocol/numero)
            Container(
              color: Colors.grey[100],
              height: 120,
              width: double.infinity,
              child: Center(
                child: nfe.protocolo != null && nfe.protocolo!.isNotEmpty
                    ? QrImageView(
                        data: nfe.protocolo!,
                        version: QrVersions.auto,
                        size: 100,
                        gapless: false,
                      )
                    : const Icon(Icons.qr_code_2, color: Colors.grey, size: 40),
              ),
            ),
            // Content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spacingSm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NFe ${nfe.numero}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'S: ${nfe.serie} | ${_formatDate(nfe.dataHora)}',
                          style: const TextStyle(fontSize: 10, color: DesignTokens.textMuted),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatCurrency(nfe.valores.total),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DesignTokens.primary),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: NfeStatusBadge(status: nfe.statusNfe, expanded: false, breakpoint: _currentBreakpoint),
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'Download PDF',
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              icon: const Icon(Icons.download, size: 14),
                              padding: EdgeInsets.zero,
                              onPressed: () => _handleReimprimirNfe(context, nfe),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // List card for mobile/tablet
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingMd,
        vertical: DesignTokens.spacingSm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingMd),
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
                        'NFe ${nfe.numero}',
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
                  expanded: true,
                  breakpoint: _currentBreakpoint,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Data', style: TextStyle(fontSize: 12, color: DesignTokens.textMuted)),
                    Text(_formatDate(nfe.dataHora), style: const TextStyle(fontSize: 13)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Valor', style: TextStyle(fontSize: 12, color: DesignTokens.textMuted)),
                    Text(
                      _formatCurrency(nfe.valores.total),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DesignTokens.primary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Cliente: ${nfe.tomador.razaoSocial}',
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            _buildActionButtons(nfe),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(NfeModel nfe) {
    if (_currentBreakpoint == Breakpoint.mobile) {
      return Center(
        child: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Row(
                children: [Icon(Icons.visibility, size: 18), SizedBox(width: 8), Text('Ver detalhes')],
              ),
              onTap: () {
                // Usar Future.microtask() para garantir execução async
                // Permite que PopupMenu feche e erros sejam capturados corretamente
                Future.microtask(() => _handleVerDetalhes(context, nfe));
              },
            ),
            PopupMenuItem(
              child: const Row(
                children: [Icon(Icons.print, size: 18), SizedBox(width: 8), Text('Reimprimir')],
              ),
              onTap: () {
                // Usar Future.microtask() para garantir execução async
                Future.microtask(() => _handleReimprimirNfe(context, nfe));
              },
            ),
            if (nfe.statusNfe != NfeStatus.cancelada)
              PopupMenuItem(
                child: const Row(
                  children: [Icon(Icons.cancel, size: 18, color: DesignTokens.error), SizedBox(width: 8), Text('Cancelar')],
                ),
                onTap: () {
                  // Usar Future.microtask() para garantir execução async
                  Future.microtask(() => _handleCancelarNfe(context, nfe));
                },
              ),
          ],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: () => L.d('[NfeListScreen] Navegando NFe ${nfe.id}'),
          icon: const Icon(Icons.visibility, size: 18),
          label: const Text('Detalhes'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () {
            L.d('[NfeListScreen] Reimprimindo NFe ${nfe.id}');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reimpressão iniciada')),
            );
          },
          icon: const Icon(Icons.print, size: 18),
          label: const Text('Reimprimir'),
        ),
        if (nfe.statusNfe != NfeStatus.cancelada) ...[
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () {
              L.d('[NfeListScreen] Cancelando NFe ${nfe.id}');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cancelamento iniciado')),
              );
            },
            icon: const Icon(Icons.cancel, size: 18),
            label: const Text('Cancelar'),
          ),
        ],
      ],
    );
  }

  Widget _buildDesktopDataTable(List<NfeModel> nfes) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        sortColumnIndex: _sortBy == 'dataHora' ? 0 : 4,
        sortAscending: _sortAsc,
        columns: [
          DataColumn(
            label: const Text('Data'),
            onSort: (index, ascending) => setState(() {
              _sortBy = 'dataHora';
              _sortAsc = ascending;
            }),
          ),
          const DataColumn(label: Text('NFe')),
          const DataColumn(label: Text('Cliente')),
          const DataColumn(label: Text('Status')),
          DataColumn(
            label: const Text('Valor'),
            numeric: true,
            onSort: (index, ascending) => setState(() {
              _sortBy = 'valor';
              _sortAsc = ascending;
            }),
          ),
          const DataColumn(label: Text('Ações')),
        ],
        rows: nfes.map((nfe) {
          return DataRow(
            cells: [
              DataCell(Text(_formatDate(nfe.dataHora))),
              DataCell(Text('${nfe.numero}/${nfe.serie}')),
              DataCell(
                SizedBox(
                  width: 200,
                  child: Text(nfe.tomador.razaoSocial, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
              DataCell(
                NfeStatusBadge(status: nfe.statusNfe, expanded: false, breakpoint: _currentBreakpoint),
              ),
              DataCell(Text(_formatCurrency(nfe.valores.total))),
              DataCell(
                Row(
                  children: [
                    Tooltip(
                      message: 'Ver detalhes',
                      child: IconButton(
                        icon: const Icon(Icons.visibility, size: 18),
                        onPressed: () => L.d('[NfeListScreen] Navegando NFe ${nfe.id}'),
                      ),
                    ),
                    Tooltip(
                      message: 'Reimprimir',
                      child: IconButton(
                        icon: const Icon(Icons.print, size: 18),
                        onPressed: () {
                          L.d('[NfeListScreen] Reimprimindo NFe ${nfe.id}');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reimpressão iniciada')),
                          );
                        },
                      ),
                    ),
                    if (nfe.statusNfe != NfeStatus.cancelada)
                      Tooltip(
                        message: 'Cancelar',
                        child: IconButton(
                          icon: const Icon(Icons.cancel, size: 18, color: DesignTokens.error),
                          onPressed: () {
                            L.d('[NfeListScreen] Cancelando NFe ${nfe.id}');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cancelamento iniciado')),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNfeList(List<NfeModel> nfes) {
    if (nfes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 64, color: DesignTokens.textMuted.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text('Nenhuma NFe encontrada', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Ajuste os filtros e tente novamente',
                style: TextStyle(color: DesignTokens.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.refresh),
                label: const Text('Limpar filtros'),
              ),
            ],
          ),
        ),
      );
    }

    // Grid virtualized for desktop
    if (_currentBreakpoint == Breakpoint.desktop) {
      return Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingMd),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: DesignTokens.spacingMd,
            mainAxisSpacing: DesignTokens.spacingMd,
            childAspectRatio: 0.75,
          ),
          itemCount: nfes.length,
          itemBuilder: (context, index) => _buildNfeCard(nfes[index], isGridView: true),
        ),
      );
    }

    // List for mobile/tablet
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: nfes.length,
      itemBuilder: (context, index) => _buildNfeCard(nfes[index]),
    );
  }

  Widget _buildStateIndicator(NfeNotifier notifier) {
    final state = notifier.state;

    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(DesignTokens.spacingMd),
        child: CircularProgressIndicator(),
      );
    }

    if (state.hasError) {
      return Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingMd),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: DesignTokens.error),
            const SizedBox(height: 12),
            Text('Erro ao carregar NFes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              state.errorMessage ?? 'Erro desconhecido',
              textAlign: TextAlign.center,
              style: TextStyle(color: DesignTokens.error, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadNfes,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (state.isEmpty) return _buildNfeList([]);
    return const SizedBox.shrink();
  }

  Widget _buildPaginationBar(NfeNotifier notifier) {
    final state = notifier.state;
    final canPrevious = state.canPreviousPage;
    final canNext = state.canNextPage;
    final currentPage = state.currentPage ?? 1;
    final totalPages = state.totalPages;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd, vertical: DesignTokens.spacingSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Página $currentPage de $totalPages', style: const TextStyle(fontSize: 13)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: canPrevious ? () => _previousPage(notifier) : null,
                tooltip: 'Página anterior',
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: canNext ? () => _nextPage(notifier) : null,
                tooltip: 'Próxima página',
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notas Fiscais Eletrônicas'),
        elevation: 0,
      ),
      body: Consumer<NfeNotifier>(
        builder: (context, notifier, _) {
          final state = notifier.state;
          final nfes = state.nfes;

          return Column(
            children: [
              if (_currentBreakpoint != Breakpoint.mobile) _buildFiltersBar(),
              if (state.isLoading || state.hasError || state.isEmpty)
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildStateIndicator(notifier),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        if (_currentBreakpoint == Breakpoint.desktop)
                          _buildDesktopDataTable(nfes)
                        else
                          _buildNfeList(nfes),
                        if (nfes.isNotEmpty) _buildPaginationBar(notifier),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: _currentBreakpoint == Breakpoint.mobile
          ? FloatingActionButton.extended(
              onPressed: () => L.d('[NfeListScreen] Criando nova NFe'),
              icon: const Icon(Icons.add),
              label: const Text('Nova NFe'),
            )
          : null,
    );
  }

  /// Handler para ver detalhes de uma NFe
  void _handleVerDetalhes(BuildContext context, NfeModel nfe) {
    try {
      L.d('[NfeListScreen] Navegando para detalhes NFe ${nfe.id}');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => NfeDetailScreen(nfeId: nfe.id),
        ),
      );
    } catch (e) {
      L.e('[NfeListScreen] Erro ao navegador: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao abrir detalhes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleReimprimirNfe(BuildContext context, NfeModel nfe) async {
    try {
      L.d('[NfeListScreen] Reimprimindo DANFE NFe ${nfe.id}');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Baixando DANFE...')));
      final r = await TenantContext.get(ApiLinks.danfeNfe(nfe.id.toString()));
      if (!mounted) return;
      if (r.statusCode == 200) {
        await FileSaver.instance.saveFile(name: 'danfe_${nfe.id}', bytes: r.bodyBytes, fileExtension: 'pdf');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('DANFE baixado!'), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ${r.statusCode}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      L.e('[NfeListScreen] Erro ao reimprimir: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _handleCancelarNfe(BuildContext context, NfeModel nfe) async {
    final motivoCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar NF-e'),
        content: SizedBox(width: 360, child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('NF-e #${nfe.id} - ${nfe.numero}'),
          const SizedBox(height: 12),
          TextField(controller: motivoCtrl, maxLines: 3,
            decoration: const InputDecoration(labelText: 'Motivo do cancelamento *', border: OutlineInputBorder(), isDense: true, hintText: 'Mínimo 15 caracteres')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Voltar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar NF-e'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (motivoCtrl.text.trim().length < 15) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Motivo deve ter pelo menos 15 caracteres'), backgroundColor: Colors.red));
      return;
    }
    try {
      L.d('[NfeListScreen] Cancelando NFe ${nfe.id}');
      final r = await TenantContext.post(ApiLinks.cancelarNfe(nfe.id.toString()), {'justificativa': motivoCtrl.text.trim()});
      if (!mounted) return;
      if (r.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NF-e cancelada!'), backgroundColor: Colors.green));
        context.read<NfeNotifier>().listarNfe();
      } else {
        String msg = 'Erro ${r.statusCode}';
        try { final b = jsonDecode(r.body); msg = b['message']?.toString() ?? msg; } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    } catch (e) {
      L.e('[NfeListScreen] Erro ao cancelar: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
    }
  }
}
