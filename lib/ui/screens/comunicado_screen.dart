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
  bool filtrosAbertos = false;

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
      appBar: AppBar(title: const Text("Comunicados")),
      body: Column(
        children: [
          // Botões de ação
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Botão Novo com cor verde
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
                ElevatedButton.icon(
                  onPressed: selectedRows.isNotEmpty ? _deleteSelected : null,
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
                // Botão para expandir/recolher filtros
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      filtrosAbertos = !filtrosAbertos;
                    });
                  },
                  icon: Icon(
                    filtrosAbertos ? Icons.expand_less : Icons.expand_more,
                  ),
                  label: Text(
                    filtrosAbertos ? "Ocultar Filtros" : "Mostrar Filtros",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[50],
                    foregroundColor: Colors.blueGrey[800],
                  ),
                ),
              ],
            ),
          ),

          // 🔎 filtros - Painel com borda e cor diferenciada
          if (filtrosAbertos)
            Container(
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
                      Flexible(
                        child: TextField(
                          controller: _tituloFilter,
                          decoration: const InputDecoration(
                            labelText: "Filtrar Título",
                            prefixIcon: Icon(Icons.search),
                            isDense: true,
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
                            isDense: true,
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
                            isDense: true,
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
                            isDense: true,
                          ),
                          onChanged: (_) => _applyFilters(),
                        ),
                      ),
                    ],
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
                columns: [
                  // Coluna de seleção apenas se houver dados
                  if (filtered.isNotEmpty)
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
                        selectedRows.remove(
                          comunicados.indexOf(filtered[index]),
                        );
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
                empty: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: const Text(
                      "Nenhum comunicado encontrado",
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

    // Criar as células da linha
    List<DataCell> cells = [];

    // Adicionar célula de seleção apenas se houver dados
    if (comunicados.isNotEmpty) {
      cells.add(
        DataCell(
          Checkbox(
            value: isSelected,
            onChanged: (value) {
              onSelect(index, value ?? false);
            },
          ),
        ),
      );
    }

    // Adicionar as demais células
    cells.addAll([
      DataCell(Text(comunicado.titulo)),
      DataCell(Text(comunicado.conteudo)),
      DataCell(Text(comunicado.categoria)),
      DataCell(Text(comunicado.autor)),
      DataCell(
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => onEdit(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () => onDelete(index),
            ),
          ],
        ),
      ),
    ]);

    return DataRow(
      selected: isSelected,
      onSelectChanged: comunicados.isEmpty
          ? null
          : (selected) {
              onSelect(index, selected ?? false);
            },
      cells: cells,
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => comunicados.length;

  @override
  int get selectedRowCount => selectedRows.length;
}
