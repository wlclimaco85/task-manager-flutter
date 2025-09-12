import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:intl/intl.dart';

class FieldConfig {
  final String label;
  final String fieldName;
  final bool isFilterable;
  final bool isInForm;
  final int flex;
  final int maxLines;
  final IconData? icon;
  final bool isSortable;

  const FieldConfig({
    required this.label,
    required this.fieldName,
    this.isFilterable = true,
    this.isInForm = true,
    this.flex = 1,
    this.maxLines = 1,
    this.icon,
    this.isSortable = true,
  });
}

typedef FromJson<T> = T Function(Map<String, dynamic> json);
typedef ToJson<T> = Map<String, dynamic> Function(T item);
typedef SecurityCheck = bool Function(String permission);

class GenericGridScreen<T> extends StatefulWidget {
  final String title;
  final String fetchEndpoint;
  final String createEndpoint;
  final String updateEndpoint;
  final String deleteEndpoint;
  final FromJson<T> fromJson;
  final ToJson<T> toJson;
  final SecurityCheck hasPermission;
  final Map<String, bool> buttonPermissions;
  final List<FieldConfig> fieldConfigs;
  final String idFieldName;
  final String dateFieldName;

  const GenericGridScreen({
    super.key,
    required this.title,
    required this.fetchEndpoint,
    required this.createEndpoint,
    required this.updateEndpoint,
    required this.deleteEndpoint,
    required this.fromJson,
    required this.toJson,
    required this.hasPermission,
    required this.fieldConfigs,
    this.idFieldName = 'id',
    this.dateFieldName = 'dhCreatedAt',
    this.buttonPermissions = const {
      'create': true,
      'edit': true,
      'delete': true,
      'deleteMultiple': true,
    },
  });

  @override
  State<GenericGridScreen<T>> createState() => _GenericGridScreenState<T>();
}

class _GenericGridScreenState<T> extends State<GenericGridScreen<T>> {
  List<T> items = [];
  List<T> filtered = [];
  Set<String> selectedRows = {};
  int rowsPerPage = 25;
  bool filtrosAbertos = false;
  bool isLoading = false;
  bool _isUpdating = false;
  bool _isDeleting = false;

  final Map<String, TextEditingController> _filterControllers = {};
  int? sortColumnIndex;
  bool sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => isLoading = true);

    final NetworkResponse response = await NetworkCaller().getRequest(
      widget.fetchEndpoint,
    );

    if (response.statusCode == 200 && response.body != null) {
      try {
        final List<dynamic> data = response.body!['data'] is Map
            ? response.body!['data']['comunicadoDTO']
            : response.body!['data'];

        setState(() {
          items = data.map((json) => widget.fromJson(json)).toList();
          filtered = List.from(items);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao processar os dados')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao carregar dados: ${response}')),
      );
    }

    setState(() => isLoading = false);
  }

  void _applyFilters() {
    setState(() {
      filtered = items.where((item) {
        final itemMap = widget.toJson(item);
        for (final config in widget.fieldConfigs) {
          if (config.isFilterable &&
              _filterControllers[config.fieldName]?.text.isNotEmpty == true) {
            final value =
                itemMap[config.fieldName]?.toString().toLowerCase() ?? '';
            final filterText = _filterControllers[config.fieldName]!.text
                .toLowerCase();
            if (!value.contains(filterText)) return false;
          }
        }
        return true;
      }).toList();
    });
  }

  void _sort<U>(
    Comparable<U> Function(T c) getField,
    int columnIndex,
    bool asc,
  ) {
    setState(() {
      filtered.sort((a, b) {
        final aValue = getField(a);
        final bValue = getField(b);
        return asc
            ? Comparable.compare(aValue, bValue)
            : Comparable.compare(bValue, aValue);
      });
      sortColumnIndex = columnIndex;
      sortAscending = asc;
    });
  }

  void _openForm({T? item}) {
    final controllers = <String, TextEditingController>{};
    final itemMap = item != null ? widget.toJson(item) : {};

    for (final config in widget.fieldConfigs.where((c) => c.isInForm)) {
      controllers[config.fieldName] = TextEditingController(
        text: itemMap[config.fieldName]?.toString() ?? '',
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => _buildForm(ctx, item, controllers),
    );
  }

  Widget _buildForm(
    BuildContext context,
    T? item,
    Map<String, TextEditingController> controllers,
  ) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: Offset(0.0, 10.0),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey, width: 0.5),
                  ),
                ),
                child: Text(
                  item == null ? "Novo Item" : "Editar Item",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              ...widget.fieldConfigs.where((config) => config.isInForm).map((
                config,
              ) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: controllers[config.fieldName],
                    maxLines: config.maxLines,
                    decoration: InputDecoration(
                      labelText: config.label,
                      labelStyle: const TextStyle(color: Colors.grey),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green, width: 2.0),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 1.0),
                      ),
                      prefixIcon: Icon(config.icon, color: Colors.green),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 15,
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: const Text("CANCELAR"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isUpdating
                        ? null
                        : () => _saveItem(item, controllers, context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isUpdating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text("SALVAR"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveItem(
    T? item,
    Map<String, TextEditingController> controllers,
    BuildContext context,
  ) async {
    setState(() => _isUpdating = true);

    final formData = <String, dynamic>{};
    for (final config in widget.fieldConfigs.where((c) => c.isInForm)) {
      formData[config.fieldName] = controllers[config.fieldName]!.text;
    }

    // Preservar ID e data se estiver editando
    if (item != null) {
      final itemMap = widget.toJson(item);
      formData[widget.idFieldName] = itemMap[widget.idFieldName];
      if (itemMap.containsKey(widget.dateFieldName)) {
        formData[widget.dateFieldName] = itemMap[widget.dateFieldName];
      }
    }

    final success = item == null
        ? await _createItem(formData)
        : await _updateItem(formData);

    if (success) {
      Navigator.pop(context);
      _loadItems();
    }

    setState(() => _isUpdating = false);
  }

  Future<bool> _createItem(Map<String, dynamic> formData) async {
    if (!widget.hasPermission('create') ||
        !widget.buttonPermissions['create']!) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sem permissão para criar')));
      return false;
    }

    final response = await NetworkCaller().postRequest(
      widget.createEndpoint,
      formData,
    );

    if (response.isSuccess) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item criado com sucesso')));
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao criar item: ${response}')),
      );
      return false;
    }
  }

  Future<bool> _updateItem(Map<String, dynamic> formData) async {
    if (!widget.hasPermission('edit') || !widget.buttonPermissions['edit']!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sem permissão para editar')),
      );
      return false;
    }

    final response = await NetworkCaller().postRequest(
      widget.updateEndpoint.replaceAll(
        ':id',
        formData[widget.idFieldName].toString(),
      ),
      formData,
    );

    if (response.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item atualizado com sucesso')),
      );
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao atualizar item: ${response}')),
      );
      return false;
    }
  }

  Future<void> _deleteItem(String id) async {
    if (!widget.hasPermission('delete') ||
        !widget.buttonPermissions['delete']!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sem permissão para excluir')),
      );
      return;
    }

    setState(() => _isDeleting = true);

    final response = await NetworkCaller().getRequest(
      widget.deleteEndpoint.replaceAll(':id', id),
    );

    setState(() => _isDeleting = false);

    if (response.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item excluído com sucesso')),
      );
      _loadItems();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao excluir item: ${response}')),
      );
    }
  }

  void _deleteSelected() {
    if (!widget.hasPermission('deleteMultiple') ||
        !widget.buttonPermissions['deleteMultiple']!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sem permissão para excluir múltiplos itens'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Deseja excluir ${selectedRows.length} item(s) selecionado(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              for (final id in selectedRows) {
                await _deleteItem(id);
              }
              setState(() => selectedRows.clear());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    if (_isUpdating || _isDeleting) {
      return Container(
        color: Colors.black54,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildFilters() {
    // Inicializar controladores
    for (final config in widget.fieldConfigs.where((c) => c.isFilterable)) {
      _filterControllers[config.fieldName] ??= TextEditingController();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            "Filtros",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final config in widget.fieldConfigs.where(
                (c) => c.isFilterable,
              ))
                Expanded(
                  flex: config.flex,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextField(
                      controller: _filterControllers[config.fieldName],
                      decoration: InputDecoration(
                        labelText: "Filtrar ${config.label}",
                        prefixIcon: Icon(config.icon ?? Icons.search),
                        isDense: true,
                      ),
                      onChanged: (_) => _applyFilters(),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    return [
      for (final config in widget.fieldConfigs.where((c) => c.isSortable))
        DataColumn(
          label: Text(config.label),
          onSort: (columnIndex, ascending) {
            _sort<dynamic>(
              (c) {
                final value = widget.toJson(c)[config.fieldName];
                return value is Comparable ? value : value.toString();
              },
              widget.fieldConfigs.indexOf(config),
              ascending,
            );
          },
        ),
      const DataColumn(label: Text("Data")),
      const DataColumn(label: Text("Ações")),
    ];
  }

  List<DataCell> _buildCells(T item, int index) {
    final itemMap = widget.toJson(item);
    return [
      for (final config in widget.fieldConfigs)
        DataCell(Text(itemMap[config.fieldName]?.toString() ?? '')),
      DataCell(
        Text(
          itemMap[widget.dateFieldName] != null
              ? DateFormat('dd/MM/yyyy HH:mm').format(
                  DateTime.parse(itemMap[widget.dateFieldName]).toLocal(),
                )
              : 'N/A',
        ),
      ),
      DataCell(
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _openForm(item: item),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () =>
                  _deleteItem(itemMap[widget.idFieldName].toString()),
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: Text(widget.title)),
          body: isLoading && items.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          if (widget.hasPermission('create') &&
                              widget.buttonPermissions['create']!)
                            ElevatedButton.icon(
                              onPressed: () => _openForm(),
                              icon: const Icon(Icons.add),
                              label: const Text("Novo"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                          if (widget.hasPermission('deleteMultiple') &&
                              widget.buttonPermissions['deleteMultiple']!)
                            ElevatedButton.icon(
                              onPressed: selectedRows.isNotEmpty
                                  ? _deleteSelected
                                  : null,
                              icon: const Icon(Icons.delete),
                              label: const Text("Deletar Selecionados"),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          const Spacer(),
                          IconButton(
                            onPressed: _loadItems,
                            icon: const Icon(Icons.refresh),
                            tooltip: "Recarregar",
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => setState(
                              () => filtrosAbertos = !filtrosAbertos,
                            ),
                            icon: Icon(
                              filtrosAbertos
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                            label: Text(
                              filtrosAbertos
                                  ? "Ocultar Filtros"
                                  : "Mostrar Filtros",
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey[50],
                              foregroundColor: Colors.blueGrey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (filtrosAbertos) _buildFilters(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: PaginatedDataTable2(
                          columnSpacing: 12,
                          horizontalMargin: 12,
                          minWidth: 800,
                          sortColumnIndex: sortColumnIndex,
                          sortAscending: sortAscending,
                          columns: _buildColumns(),
                          source: _GenericDataSource<T>(
                            items: filtered,
                            selectedRows: selectedRows,
                            cellBuilder: _buildCells,
                            onSelect: (index, selected) {
                              setState(() {
                                final itemMap = widget.toJson(filtered[index]);
                                final id = itemMap[widget.idFieldName]
                                    .toString();
                                selected
                                    ? selectedRows.add(id)
                                    : selectedRows.remove(id);
                              });
                            },
                          ),
                          rowsPerPage: rowsPerPage,
                          availableRowsPerPage: const [25, 50, 75, 100],
                          onRowsPerPageChanged: (value) =>
                              setState(() => rowsPerPage = value ?? 25),
                          empty: Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              child: const Text(
                                "Nenhum item encontrado",
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        _buildLoadingOverlay(),
      ],
    );
  }
}

class _GenericDataSource<T> extends DataTableSource {
  final List<T> items;
  final Set<String> selectedRows;
  final List<DataCell> Function(T item, int index) cellBuilder;
  final void Function(int index, bool selected) onSelect;

  _GenericDataSource({
    required this.items,
    required this.selectedRows,
    required this.cellBuilder,
    required this.onSelect,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= items.length) return null;
    final item = items[index];
    final isSelected = selectedRows.contains(index.toString());

    return DataRow(
      selected: isSelected,
      onSelectChanged: (selected) => onSelect(index, selected ?? false),
      cells: cellBuilder(item, index),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => items.length;

  @override
  int get selectedRowCount => selectedRows.length;
}
