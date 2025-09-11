import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:intl/intl.dart';

typedef FromJson<T> = T Function(Map<String, dynamic> json);
typedef ToJson<T> = Map<String, dynamic> Function(T item);
typedef FormBuilder<T> =
    Widget Function(
      BuildContext context,
      T? item,
      Function(T) onSave,
      bool isSaving,
    );
typedef ColumnBuilder<T> = List<DataColumn> Function(BuildContext context);
typedef CellBuilder<T> =
    List<DataCell> Function(BuildContext context, T item, int index);
typedef SecurityCheck = bool Function(String permission);

class GenericGridScreen<T> extends StatefulWidget {
  final String title;
  final String fetchEndpoint;
  final String createEndpoint;
  final String updateEndpoint;
  final String deleteEndpoint;
  final FromJson<T> fromJson;
  final ToJson<T> toJson;
  final FormBuilder<T> formBuilder;
  final ColumnBuilder<T> columnBuilder;
  final CellBuilder<T> cellBuilder;
  final SecurityCheck hasPermission;
  final Map<String, bool> buttonPermissions;

  const GenericGridScreen({
    super.key,
    required this.title,
    required this.fetchEndpoint,
    required this.createEndpoint,
    required this.updateEndpoint,
    required this.deleteEndpoint,
    required this.fromJson,
    required this.toJson,
    required this.formBuilder,
    required this.columnBuilder,
    required this.cellBuilder,
    required this.hasPermission,
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

  // filtros
  final Map<String, TextEditingController> _filterControllers = {};

  // ordenação
  int? sortColumnIndex;
  bool sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      isLoading = true;
    });

    final NetworkResponse response = await NetworkCaller().getRequest(
      widget.fetchEndpoint,
    );

    if (response.statusCode == 200 && response.body != null) {
      try {
        // Parse da resposta do servidor
        final List<dynamic> data = response.body!['data'];
        setState(() {
          items = data.map((json) => widget.fromJson(json)).toList();
          filtered = List.from(items);
        });
      } catch (e) {
        print('Erro no parse dos dados: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao processar os dados')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao carregar dados: ${response}')),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  void _applyFilters() {
    // Esta função precisa ser implementada de acordo com os campos do modelo
    // Pode ser sobrescrita ou personalizada conforme necessário
    setState(() {
      filtered = List.from(items);
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
    showDialog(
      context: context,
      builder: (ctx) {
        return widget.formBuilder(ctx, item, (newItem) async {
          final success = item == null
              ? await _createItem(newItem)
              : await _updateItem(newItem);

          if (success) {
            Navigator.pop(ctx);
            _loadItems();
          }
        }, _isUpdating);
      },
    );
  }

  Future<bool> _createItem(T item) async {
    if (!widget.hasPermission('create') ||
        !widget.buttonPermissions['create']!) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sem permissão para criar')));
      return false;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final response = await NetworkCaller().postRequest(
        widget.createEndpoint,
        widget.toJson(item),
      );

      setState(() {
        _isUpdating = false;
      });

      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item criado com sucesso')),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao criar item: ${response}')),
        );
        return false;
      }
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao criar item: $e')));
      return false;
    }
  }

  Future<bool> _updateItem(T item) async {
    if (!widget.hasPermission('edit') || !widget.buttonPermissions['edit']!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sem permissão para editar')),
      );
      return false;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final response = await NetworkCaller().postRequest(
        widget.updateEndpoint,
        widget.toJson(item),
      );

      setState(() {
        _isUpdating = false;
      });

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
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao atualizar item: $e')));
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

    setState(() {
      _isDeleting = true;
    });

    try {
      final response = await NetworkCaller().getRequest(
        widget.deleteEndpoint.replaceAll(':id', id),
      );

      setState(() {
        _isDeleting = false;
      });

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
    } catch (e) {
      setState(() {
        _isDeleting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao excluir item: $e')));
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
              setState(() {
                selectedRows.clear();
              });
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
                    // Botões de ação
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Botão Novo
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
                          // Botão Deletar Selecionados
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
                          // Botão para recarregar dados
                          IconButton(
                            onPressed: _loadItems,
                            icon: const Icon(Icons.refresh),
                            tooltip: "Recarregar",
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: PaginatedDataTable2(
                          columnSpacing: 12,
                          horizontalMargin: 12,
                          minWidth: 800,
                          sortColumnIndex: sortColumnIndex,
                          sortAscending: sortAscending,
                          columns: widget.columnBuilder(context),
                          source: _GenericDataSource<T>(
                            items: filtered,
                            selectedRows: selectedRows,
                            onEdit: (index) {
                              if (widget.hasPermission('edit') &&
                                  widget.buttonPermissions['edit']!) {
                                _openForm(item: filtered[index]);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sem permissão para editar'),
                                  ),
                                );
                              }
                            },
                            onDelete: (index) {
                              if (widget.hasPermission('delete') &&
                                  widget.buttonPermissions['delete']!) {
                                // Extrair ID do item - você precisará adaptar isso conforme seu modelo
                                final dynamic item = filtered[index];
                                final String id =
                                    item.id?.toString() ?? index.toString();
                                _deleteItem(id);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sem permissão para excluir'),
                                  ),
                                );
                              }
                            },
                            onSelect: (index, selected) {
                              setState(() {
                                final dynamic item = filtered[index];
                                final String id =
                                    item.id?.toString() ?? index.toString();
                                if (selected) {
                                  selectedRows.add(id);
                                } else {
                                  selectedRows.remove(id);
                                }
                              });
                            },
                            cellBuilder: widget.cellBuilder,
                            context: context, // Passe o contexto
                          ),
                          rowsPerPage: rowsPerPage,
                          availableRowsPerPage: const [25, 50, 75, 100],
                          onRowsPerPageChanged: (value) {
                            setState(() {
                              rowsPerPage = value ?? 25;
                            });
                          },
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
  final void Function(int index) onEdit;
  final void Function(int index) onDelete;
  final void Function(int index, bool selected) onSelect;
  final CellBuilder<T> cellBuilder;
  final BuildContext context;

  _GenericDataSource({
    required this.items,
    required this.selectedRows,
    required this.onEdit,
    required this.onDelete,
    required this.onSelect,
    required this.cellBuilder,
    required this.context,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= items.length) return null;
    final item = items[index];

    // Extrair ID do item - você precisará adaptar isso conforme seu modelo
    final dynamic itemObj = item;
    final String id = itemObj.id?.toString() ?? index.toString();
    final isSelected = selectedRows.contains(id);

    return DataRow(
      selected: isSelected,
      onSelectChanged: (selected) {
        onSelect(index, selected ?? false);
      },
      cells: cellBuilder(context, item, index),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => items.length;

  @override
  int get selectedRowCount => selectedRows.length;
}
