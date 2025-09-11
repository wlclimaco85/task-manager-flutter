import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:intl/intl.dart';

class Comunicado {
  String id;
  String titulo;
  String conteudo;
  String categoria;
  String autor;
  DateTime? dhCreatedAt;

  Comunicado({
    required this.id,
    required this.titulo,
    required this.conteudo,
    required this.categoria,
    required this.autor,
    this.dhCreatedAt,
  });

  factory Comunicado.fromJson(Map<String, dynamic> json) {
    return Comunicado(
      id: json['_id'] ?? '',
      titulo: json['titulo'] ?? '',
      conteudo: json['conteudo'] ?? '',
      categoria: json['categoria'] ?? '',
      autor: json['autor'] ?? '',
      dhCreatedAt: json['dhCreatedAt'] != null
          ? DateTime.parse(json['dhCreatedAt']).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'titulo': titulo,
      'conteudo': conteudo,
      'categoria': categoria,
      'autor': autor,
      'dhCreatedAt': dhCreatedAt?.toIso8601String(),
    };
  }
}

class ComunicadoGridComponentesScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const ComunicadoGridComponentesScreen({
    super.key,
    required this.hasPermission,
  });

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Comunicado>(
      title: "Comunicados",
      fetchEndpoint: ApiLinks.allComunicados,
      createEndpoint: ApiLinks.createComunicado,
      updateEndpoint: ApiLinks.updateComunicado(":id"),
      deleteEndpoint: ApiLinks.deleteComunicado(":id"),
      fromJson: (json) => Comunicado.fromJson(json),
      toJson: (comunicado) => comunicado.toJson(),
      formBuilder: _buildForm,
      columnBuilder: _buildColumns,
      cellBuilder: _buildCells,
      hasPermission: hasPermission,
      buttonPermissions: {
        'create': true,
        'edit': true,
        'delete': true,
        'deleteMultiple': true,
      },
    );
  }

  Widget _buildForm(
    BuildContext context,
    Comunicado? item,
    Function(Comunicado) onSave,
    bool isSaving,
  ) {
    final tituloController = TextEditingController(text: item?.titulo ?? "");
    final conteudoController = TextEditingController(
      text: item?.conteudo ?? "",
    );
    final categoriaController = TextEditingController(
      text: item?.categoria ?? "",
    );
    final autorController = TextEditingController(text: item?.autor ?? "");

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
              // Cabeçalho
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey, width: 0.5),
                  ),
                ),
                child: Text(
                  item == null ? "Novo Comunicado" : "Editar Comunicado",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 20),

              // Campo Título
              TextFormField(
                controller: tituloController,
                decoration: InputDecoration(
                  labelText: "Título",
                  labelStyle: const TextStyle(color: Colors.grey),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green, width: 2.0),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 1.0),
                  ),
                  prefixIcon: const Icon(Icons.title, color: Colors.green),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 15,
                  ),
                ),
                style: const TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 16),

              // Campo Conteúdo
              TextFormField(
                controller: conteudoController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Conteúdo",
                  labelStyle: const TextStyle(color: Colors.grey),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green, width: 2.0),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 1.0),
                  ),
                  prefixIcon: const Icon(
                    Icons.description,
                    color: Colors.green,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 15,
                  ),
                ),
                style: const TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 16),

              // Campo Categoria
              TextFormField(
                controller: categoriaController,
                decoration: InputDecoration(
                  labelText: "Categoria",
                  labelStyle: const TextStyle(color: Colors.grey),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green, width: 2.0),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 1.0),
                  ),
                  prefixIcon: const Icon(Icons.category, color: Colors.green),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 15,
                  ),
                ),
                style: const TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 16),

              // Campo Autor
              TextFormField(
                controller: autorController,
                decoration: InputDecoration(
                  labelText: "Autor",
                  labelStyle: const TextStyle(color: Colors.grey),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green, width: 2.0),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 1.0),
                  ),
                  prefixIcon: const Icon(Icons.person, color: Colors.green),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 15,
                  ),
                ),
                style: const TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 24),

              // Botões de ação
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
                    onPressed: isSaving
                        ? null
                        : () {
                            final newComunicado = Comunicado(
                              id:
                                  item?.id ??
                                  DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                              titulo: tituloController.text,
                              conteudo: conteudoController.text,
                              categoria: categoriaController.text,
                              autor: autorController.text,
                            );
                            onSave(newComunicado);
                          },
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
                    child: isSaving
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

  List<DataColumn> _buildColumns(BuildContext context) {
    return [
      const DataColumn(label: Text("Título")),
      const DataColumn(label: Text("Conteúdo")),
      const DataColumn(label: Text("Categoria")),
      const DataColumn(label: Text("Autor")),
      const DataColumn(label: Text("Data")),
      const DataColumn(label: Text("Ações")),
    ];
  }

  List<DataCell> _buildCells(BuildContext context, Comunicado item, int index) {
    return [
      DataCell(Text(item.titulo)),
      DataCell(Text(item.conteudo)),
      DataCell(Text(item.categoria)),
      DataCell(Text(item.autor)),
      DataCell(
        Text(
          item.dhCreatedAt != null
              ? DateFormat('dd/MM/yyyy HH:mm').format(item.dhCreatedAt!)
              : 'N/A',
        ),
      ),
      DataCell(
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () {
                // A edição será tratada pelo onEdit do GenericDataSource
                // Esta função será chamada quando o ícone for pressionado
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () {
                // A exclusão será tratada pelo onDelete do GenericDataSource
                // Esta função será chamada quando o ícone for pressionado
              },
            ),
          ],
        ),
      ),
    ];
  }
}
