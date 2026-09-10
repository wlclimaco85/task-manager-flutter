import 'dart:convert';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_flutter/core/design/design_tokens.dart';
import 'package:task_manager_flutter/core/responsive/responsive_helper.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_status.dart';
import 'package:task_manager_flutter/providers/nfe_notifier.dart';
import 'package:task_manager_flutter/utils/api_links.dart';
import 'package:task_manager_flutter/utils/tenant_context.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_status_badge.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_filter_chip.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_card.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_pagination_bar.dart';
import 'package:task_manager_flutter/screens/nfe/nfe_detail_screen.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';

/// Tela responsiva de listagem de NFes com grid 4-2-1
/// - Mobile (<768): 1 coluna
/// - Tablet (768-1200): 2 colunas
/// - Desktop (>=1200): 4 colunas
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
    if (width < 768) {
      _currentBreakpoint = Breakpoint.mobile;
    } else if (width < 1200) {
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

  Future<void> _onStatusChanged(String? newStatus) async {
    L.d('[NfeListScreen] Status filtro mudou para: $newStatus');
    setState(() => _selectedStatus = newStatus);
    await _applyFilters(); // Refetch com novo filtro
  }

  Future<void> _onDateRangeChanged(DateTime? inicio, DateTime? fim) async {
    L.d('[NfeListScreen] Data range mudou: $inicio até $fim');
    setState(() {
      _dataInicio = inicio;
      _dataFim = fim;
    });
    await _applyFilters(); // Refetch com novas datas
  }

  Future<void> _onClienteCnpjChanged(String? cnpj) async {
    L.d('[NfeListScreen] Cliente CNPJ mudou para: $cnpj');
    setState(() => _clienteCnpj = cnpj);
    await _applyFilters(); // Refetch com novo cliente
  }

  Future<void> _onSortChanged(String sortField, bool ascending) async {
    L.d('[NfeListScreen] Sort mudou para: $sortField (ascending=$ascending)');
    setState(() {
      _sortBy = sortField;
      _sortAsc = ascending;
    });
    await _applyFilters(); // Refetch com novo sort
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

  /// Determina o número de colunas para grid responsivo
  int _getCrossAxisCount() {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) {
      return 4; // Desktop
    } else if (width >= 768) {
      return 2; // Tablet
    } else {
      return 1; // Mobile
    }
  }

  /// Constrói grid responsivo com NfeCard widgets
  Widget _buildResponsiveGrid(List<NfeModel> nfes) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: nfes.length,
      itemBuilder: (context, index) {
        final nfe = nfes[index];
        return RepaintBoundary(
          child: NfeCard(
            nfe: nfe,
            breakpoint: _currentBreakpoint,
            onDetails: () => _handleVerDetalhes(context, nfe),
            onReprint: () => _handleReimprimirNfe(context, nfe),
            onCancel: () => _handleCancelarNfe(context, nfe),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
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
              // Filtros (ocultos em mobile)
              if (_currentBreakpoint != Breakpoint.mobile)
                _buildFiltersBar(),

              // Conteúdo principal
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      // Estados: Loading, Error, Empty
                      if (state.isLoading)
                        Padding(
                          padding: const EdgeInsets.all(DesignTokens.spacingLg),
                          child: Column(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                'Carregando NFes...',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        )
                      else if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.all(DesignTokens.spacingMd),
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: DesignTokens.error,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Erro ao carregar NFes',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                state.errorMessage ?? 'Erro desconhecido',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: DesignTokens.error,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadNfes,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        )
                      else if (nfes.isEmpty)
                        _buildEmptyState()
                      else ...[
                        // Grid responsivo
                        Padding(
                          padding: const EdgeInsets.all(DesignTokens.spacingMd),
                          child: _buildResponsiveGrid(nfes),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Pagination bar (sticky no bottom)
              if (!state.isLoading && !state.hasError && nfes.isNotEmpty)
                NfePaginationBar(
                  currentPage: state.currentPage ?? 1,
                  totalPages: state.totalPages,
                  canPrevious: state.canPreviousPage,
                  canNext: state.canNextPage,
                  onPreviousPage: () => _previousPage(notifier),
                  onNextPage: () => _nextPage(notifier),
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
      L.e('[NfeListScreen] Erro ao navegar: $e');
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
