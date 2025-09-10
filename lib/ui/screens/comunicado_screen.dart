import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';

class Comunicado {
  String titulo;
  String conteudo;
  String categoria;
  String autor;

  Comunicado({
    required this.titulo,
    required this.conteudo,
    required this.categoria,
    required this.autor,
  });
}

class ComunicadoGridScreen extends StatefulWidget {
  const ComunicadoGridScreen({super.key});

  @override
  State<ComunicadoGridScreen> createState() => _ComunicadoGridScreenState();
}

class _ComunicadoGridScreenState extends State<ComunicadoGridScreen> {
  List<Comunicado> comunicados = [
    Comunicado(
      titulo: "Título C",
      conteudo: "Conteúdo 3",
      categoria: "Aviso",
      autor: "Carlos",
    ),
    Comunicado(
      titulo: "Título A",
      conteudo: "Conteúdo 1",
      categoria: "Notícia",
      autor: "Ana",
    ),
    Comunicado(
      titulo: "Título B",
      conteudo: "Conteúdo 2",
      categoria: "Evento",
      autor: "Bruno",
    ),
  ];

  List<Comunicado> filtered = [];
  Set<int> selectedRows = {};
  int rowsPerPage = 25;

  // filtros
  final _tituloFilter = TextEditingController();
  final _conteudoFilter = TextEditingController();
  final _categoriaFilter = TextEditingController();
  final _autorFilter = TextEditingController();

  // ordenação
  int? sortColumnIndex;
  bool sortAscending = true;

  @override
  void initState() {
    super.initState();
    filtered = List.from(comunicados);
  }

  void _applyFilters() {
    setState(() {
      filtered = comunicados.where((c) {
        final tituloOk = c.titulo.toLowerCase().contains(
          _tituloFilter.text.toLowerCase(),
        );
        final conteudoOk = c.conteudo.toLowerCase().contains(
          _conteudoFilter.text.toLowerCase(),
        );
        final categoriaOk = c.categoria.toLowerCase().contains(
          _categoriaFilter.text.toLowerCase(),
        );
        final autorOk = c.autor.toLowerCase().contains(
          _autorFilter.text.toLowerCase(),
        );
        return tituloOk && conteudoOk && categoriaOk && autorOk;
      }).toList();
    });
  }

  void _sort<T>(
    Comparable<T> Function(Comunicado c) getField,
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

  void _openForm({Comunicado? comunicado, int? index}) {
    final tituloController = TextEditingController(
      text: comunicado?.titulo ?? "",
    );
    final conteudoController = TextEditingController(
      text: comunicado?.conteudo ?? "",
    );
    final categoriaController = TextEditingController(
      text: comunicado?.categoria ?? "",
    );
    final autorController = TextEditingController(
      text: comunicado?.autor ?? "",
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            comunicado == null ? "Novo Comunicado" : "Editar Comunicado",
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tituloController,
                  decoration: const InputDecoration(labelText: "Título"),
                ),
                TextField(
                  controller: conteudoController,
                  decoration: const InputDecoration(labelText: "Conteúdo"),
                ),
                TextField(
                  controller: categoriaController,
                  decoration: const InputDecoration(labelText: "Categoria"),
                ),
                TextField(
                  controller: autorController,
                  decoration: const InputDecoration(labelText: "Autor"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Fechar"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (comunicado == null) {
                    comunicados.add(
                      Comunicado(
                        titulo: tituloController.text,
                        conteudo: conteudoController.text,
                        categoria: categoriaController.text,
                        autor: autorController.text,
                      ),
                    );
                  } else {
                    comunicados[index!] = Comunicado(
                      titulo: tituloController.text,
                      conteudo: conteudoController.text,
                      categoria: categoriaController.text,
                      autor: autorController.text,
                    );
                  }
                  _applyFilters();
                });
                Navigator.pop(ctx);
              },
              child: const Text("Salvar"),
            ),
          ],
        );
      },
    );
  }

  void _deleteSelected() {
    setState(() {
      comunicados.removeWhere(
        (element) => selectedRows.contains(comunicados.indexOf(element)),
      );
      selectedRows.clear();
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Comunicados"),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
            label: const Text("Novo"),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: selectedRows.isNotEmpty ? _deleteSelected : null,
            icon: const Icon(Icons.delete),
            label: const Text("Deletar Selecionados"),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // 🔎 filtros
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Flexible(
                  child: TextField(
                    controller: _tituloFilter,
                    decoration: const InputDecoration(
                      labelText: "Filtrar Título",
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => _applyFilters(),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: TextField(
                    controller: _conteudoFilter,
                    decoration: const InputDecoration(
                      labelText: "Filtrar Conteúdo",
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => _applyFilters(),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: TextField(
                    controller: _categoriaFilter,
                    decoration: const InputDecoration(
                      labelText: "Filtrar Categoria",
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => _applyFilters(),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: TextField(
                    controller: _autorFilter,
                    decoration: const InputDecoration(
                      labelText: "Filtrar Autor",
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => _applyFilters(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PaginatedDataTable2(
              sortColumnIndex: sortColumnIndex,
              sortAscending: sortAscending,
              columns: [
                const DataColumn(label: Text("Selecionar")),
                DataColumn(
                  label: const Text("Título"),
                  onSort: (i, asc) => _sort((c) => c.titulo, i, asc),
                ),
                DataColumn(
                  label: const Text("Conteúdo"),
                  onSort: (i, asc) => _sort((c) => c.conteudo, i, asc),
                ),
                DataColumn(
                  label: const Text("Categoria"),
                  onSort: (i, asc) => _sort((c) => c.categoria, i, asc),
                ),
                DataColumn(
                  label: const Text("Autor"),
                  onSort: (i, asc) => _sort((c) => c.autor, i, asc),
                ),
                const DataColumn(label: Text("Ações")),
              ],
              source: _ComunicadoDataSource(
                comunicados: filtered,
                selectedRows: selectedRows,
                onEdit: (index) => _openForm(
                  comunicado: filtered[index],
                  index: comunicados.indexOf(filtered[index]),
                ),
                onDelete: (index) {
                  setState(() {
                    comunicados.remove(filtered[index]);
                    _applyFilters();
                  });
                },
                onSelect: (index, selected) {
                  setState(() {
                    if (selected) {
                      selectedRows.add(comunicados.indexOf(filtered[index]));
                    } else {
                      selectedRows.remove(comunicados.indexOf(filtered[index]));
                    }
                  });
                },
              ),
              rowsPerPage: rowsPerPage,
              availableRowsPerPage: const [25, 50, 75, 100],
              onRowsPerPageChanged: (value) {
                setState(() {
                  rowsPerPage = value ?? 25;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ComunicadoDataSource extends DataTableSource {
  final List<Comunicado> comunicados;
  final Set<int> selectedRows;
  final void Function(int index) onEdit;
  final void Function(int index) onDelete;
  final void Function(int index, bool selected) onSelect;

  _ComunicadoDataSource({
    required this.comunicados,
    required this.selectedRows,
    required this.onEdit,
    required this.onDelete,
    required this.onSelect,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= comunicados.length) return null;
    final comunicado = comunicados[index];
    final isSelected = selectedRows.contains(index);

    return DataRow(
      selected: isSelected,
      onSelectChanged: (selected) {
        onSelect(index, selected ?? false);
      },
      cells: [
        DataCell(
          Checkbox(
            value: isSelected,
            onChanged: (value) {
              onSelect(index, value ?? false);
            },
          ),
        ),
        DataCell(Text(comunicado.titulo)),
        DataCell(Text(comunicado.conteudo)),
        DataCell(Text(comunicado.categoria)),
        DataCell(Text(comunicado.autor)),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => onEdit(index),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => onDelete(index),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => comunicados.length;

  @override
  int get selectedRowCount => selectedRows.length;
}
