import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:task_manager_flutter/data/models/comunicados_model.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:intl/intl.dart';

class ComunicadoGridScreen extends StatefulWidget {
  const ComunicadoGridScreen({super.key});

  @override
  State<ComunicadoGridScreen> createState() => _ComunicadoGridScreenState();
}

class _ComunicadoGridScreenState extends State<ComunicadoGridScreen> {
  late ComunicadoDataSource _comunicadoDataSource;
  bool isLoading = true;
  final List<Data> _newsList = [];

  @override
  void initState() {
    super.initState();
    _fetchComunicados();
  }

  Future<void> _fetchComunicados() async {
    final response = await NetworkCaller().getRequest(ApiLinks.allComunicados);
    if (response.isSuccess && response.body != null) {
      final model = ComunicadoModel.fromJson(response.body!);
      if (model.data != null) {
        _newsList.addAll(model.data!);
      }
    }
    _comunicadoDataSource = ComunicadoDataSource(_newsList);
    setState(() => isLoading = false);
  }

  void _deleteSelected() {
    setState(() {
      _comunicadoDataSource.rows.removeWhere((row) => row.isSelected == true);
      _comunicadoDataSource.updateDataGrid();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📢 Comunicados')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barra de ação com botões
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Novo'),
                        onPressed: () {
                          debugPrint('Adicionar novo comunicado');
                        },
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.delete),
                        label: const Text('Excluir selecionados'),
                        onPressed: _deleteSelected,
                      ),
                    ],
                  ),
                ),
                // DataGrid Syncfusion
                Expanded(
                  child: SfDataGrid(
                    source: _comunicadoDataSource,
                    allowSorting: true,
                    allowMultiColumnSorting: true,
                    selectionMode: SelectionMode.multiple,
                    columns: [
                      GridColumn(
                        columnName: 'titulo',
                        label: const Text('Título'),
                      ),
                      GridColumn(
                        columnName: 'conteudo',
                        label: const Text('Conteúdo'),
                      ),
                      GridColumn(
                        columnName: 'categoria',
                        label: const Text('Categoria'),
                      ),
                      GridColumn(columnName: 'data', label: const Text('Data')),
                      GridColumn(
                        columnName: 'autor',
                        label: const Text('Autor'),
                      ),
                      GridWidgetColumn(
                        columnName: 'acoes',
                        width: 100,
                        label: const Text('Ações'),
                        widget: (column, row) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  debugPrint(
                                    'Editar: ${row.getCells()['titulo']?.value}',
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  debugPrint(
                                    'Excluir: ${row.getCells()['titulo']?.value}',
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class ComunicadoDataSource extends DataGridSource {
  List<DataGridRow> rows = [];

  ComunicadoDataSource(List<Data> comunicados) {
    rows = comunicados.map((com) {
      return DataGridRow(
        cells: [
          DataGridCell(columnName: 'titulo', value: com.titulo),
          DataGridCell(columnName: 'conteudo', value: com.conteudo),
          DataGridCell(columnName: 'categoria', value: com.categoria),
          DataGridCell(
            columnName: 'data',
            value: com.dhCreatedAt != null
                ? DateFormat('dd/MM/yyyy HH:mm').format(com.dhCreatedAt!)
                : '',
          ),
          DataGridCell(columnName: 'autor', value: com.autor),
          DataGridCell(columnName: 'acoes', value: null),
        ],
      );
    }).toList();
  }

  @override
  List<DataGridRow> get dataGridRows => rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map((cell) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.centerLeft,
          child: Text(cell.value?.toString() ?? ''),
        );
      }).toList(),
    );
  }

  void updateDataGrid() {
    notifyListeners();
  }
}
