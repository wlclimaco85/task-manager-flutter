import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_flutter/models/nfe_state.dart';
import 'package:task_manager_flutter/providers/nfe_notifier.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';

/// Tela de listagem de NFes com filtros, paginação e pull-to-refresh
class NfeListScreen extends StatefulWidget {
  const NfeListScreen({Key? key}) : super(key: key);

  @override
  State<NfeListScreen> createState() => _NfeListScreenState();
}

class _NfeListScreenState extends State<NfeListScreen> {
  late TextEditingController _searchController;
  String? _selectedStatus;
  DateTime? _dataInicio;
  DateTime? _dataFim;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // Carrega NFes ao abrir tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = context.read<NfeNotifier>();
      notifier.listarNfe();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Abre date picker e retorna data selecionada
  Future<DateTime?> _selectDate(BuildContext context, DateTime? initialDate) async {
    return await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
  }

  /// Reconstrói a lista de NFes com filtros atuais
  Future<void> _applyFilters() async {
    final notifier = context.read<NfeNotifier>();
    await notifier.listarNfe(
      page: 1,
      status: _selectedStatus,
      dataInicio: _dataInicio,
      dataFim: _dataFim,
      clienteCnpj: _searchController.text.isEmpty ? null : _searchController.text,
    );
  }

  /// Limpa todos os filtros
  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = null;
      _dataInicio = null;
      _dataFim = null;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notas Fiscais'),
        elevation: 0,
      ),
      body: Consumer<NfeNotifier>(
        builder: (context, notifier, child) {
          final state = notifier.state;

          return RefreshIndicator(
            onRefresh: () => notifier.listarNfe(),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // === SEÇÃO DE FILTROS ===
                    _buildFilterSection(context, isMobile),
                    const SizedBox(height: 16),

                    // === CONTEÚDO PRINCIPAL ===
                    if (state.isLoading)
                      const _LoadingWidget()
                    else if (state.hasError)
                      _ErrorWidget(
                        message: state.errorMessage ?? 'Erro desconhecido',
                        onRetry: _applyFilters,
                      )
                    else if (state.isEmpty)
                      const _EmptyWidget()
                    else
                      _NfeListView(
                        nfes: state.nfes,
                        currentPage: state.currentPage ?? 1,
                        totalPages: state.totalPages,
                        canNextPage: state.canNextPage,
                        canPreviousPage: state.canPreviousPage,
                        onRowTap: (nfe) {
                          L.d('[NfeListScreen] Navegando para NFe ${nfe.id}');
                          Navigator.of(context).pushNamed(
                            '/nfe/detail',
                            arguments: nfe.id,
                          );
                        },
                        onNextPage: () async {
                          await notifier.proximaPagina(
                            status: _selectedStatus,
                            dataInicio: _dataInicio,
                            dataFim: _dataFim,
                            clienteCnpj: _searchController.text.isEmpty ? null : _searchController.text,
                          );
                        },
                        onPreviousPage: () async {
                          await notifier.paginaAnterior(
                            status: _selectedStatus,
                            dataInicio: _dataInicio,
                            dataFim: _dataFim,
                            clienteCnpj: _searchController.text.isEmpty ? null : _searchController.text,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Constrói seção de filtros
  Widget _buildFilterSection(BuildContext context, bool isMobile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Filtros', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // Número NFe
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Número NFe',
                hintText: 'Digite o número',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // Status
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              items: const [
                DropdownMenuItem(value: null, child: Text('Todos os status')),
                DropdownMenuItem(value: 'RASCUNHO', child: Text('Rascunho')),
                DropdownMenuItem(value: 'AUTORIZADA', child: Text('Autorizada')),
                DropdownMenuItem(value: 'REJEITADA', child: Text('Rejeitada')),
                DropdownMenuItem(value: 'CANCELADA', child: Text('Cancelada')),
              ],
              onChanged: (value) => setState(() => _selectedStatus = value),
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // Data range
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await _selectDate(context, _dataInicio);
                      if (date != null) {
                        setState(() => _dataInicio = date);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data início',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _dataInicio?.toString().split(' ')[0] ?? 'Selecionar',
                        style: TextStyle(
                          color: _dataInicio != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await _selectDate(context, _dataFim);
                      if (date != null) {
                        setState(() => _dataFim = date);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data fim',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _dataFim?.toString().split(' ')[0] ?? 'Selecionar',
                        style: TextStyle(
                          color: _dataFim != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Botões de ação
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _applyFilters,
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar'),
                ),
                OutlinedButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget de carregamento
class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Widget de erro
class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({
    Key? key,
    required this.message,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar NFes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget de estado vazio
class _EmptyWidget extends StatelessWidget {
  const _EmptyWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Nenhuma NFe encontrada',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Ajuste os filtros ou crie uma nova NFe',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget de lista de NFes com DataTable
class _NfeListView extends StatelessWidget {
  final List nfes;
  final int currentPage;
  final int totalPages;
  final bool canNextPage;
  final bool canPreviousPage;
  final Function(dynamic nfe) onRowTap;
  final VoidCallback onNextPage;
  final VoidCallback onPreviousPage;

  const _NfeListView({
    Key? key,
    required this.nfes,
    required this.currentPage,
    required this.totalPages,
    required this.canNextPage,
    required this.canPreviousPage,
    required this.onRowTap,
    required this.onNextPage,
    required this.onPreviousPage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Número')),
              DataColumn(label: Text('Série')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Data')),
              DataColumn(label: Text('Valor')),
              DataColumn(label: Text('Ação')),
            ],
            rows: nfes.map<DataRow>((nfe) {
              return DataRow(
                onSelectChanged: (_) => onRowTap(nfe),
                cells: [
                  DataCell(Text(nfe.numero)),
                  DataCell(Text(nfe.serie.toString())),
                  DataCell(Text(nfe.statusNfe.label)),
                  DataCell(Text(nfe.dataHora.toString().split(' ')[0])),
                  DataCell(Text('R\$ ${nfe.valores.total.toStringAsFixed(2)}')),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () => onRowTap(nfe),
                      tooltip: 'Visualizar',
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        // Paginação
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Página $currentPage de $totalPages'),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: canPreviousPage ? onPreviousPage : null,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: canNextPage ? onNextPage : null,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
