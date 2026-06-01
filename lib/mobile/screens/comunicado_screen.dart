import 'package:flutter/material.dart';
import 'package:task_manager_flutter/customization/generic_grid_card.dart';
import 'package:task_manager_flutter/utils/api_links.dart';
import '../../../utils/security_matrix.dart';

class ComunicadoMobile {
  final String? id;
  final String titulo;
  final String conteudo;
  final String categoria;
  final String autor;

  const ComunicadoMobile({
    this.id,
    required this.titulo,
    required this.conteudo,
    required this.categoria,
    required this.autor,
  });

  factory ComunicadoMobile.fromJson(Map<String, dynamic> j) =>
      ComunicadoMobile(
        id: (j['_id'] ?? j['id'])?.toString(),
        titulo: j['titulo']?.toString() ?? '',
        conteudo: j['conteudo']?.toString() ?? '',
        categoria: j['categoria']?.toString() ?? '',
        autor: j['autor']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'titulo': titulo,
        'conteudo': conteudo,
        'categoria': categoria,
        'autor': autor,
      };

  static const List<FieldConfig> fieldConfigs = [
    FieldConfig(
      label: 'Título',
      fieldName: 'titulo',
      isRequired: true,
      isFilterable: true,
      icon: Icons.title,
    ),
    FieldConfig(
      label: 'Conteúdo',
      fieldName: 'conteudo',
      isRequired: true,
      isFilterable: true,
      fieldType: FieldType.multiline,
      maxLines: 4,
      icon: Icons.article,
    ),
    FieldConfig(
      label: 'Categoria',
      fieldName: 'categoria',
      isRequired: true,
      isFilterable: true,
      icon: Icons.category,
    ),
    FieldConfig(
      label: 'Autor',
      fieldName: 'autor',
      isRequired: true,
      isFilterable: true,
      icon: Icons.person,
    ),
  ];
}

class ComunicadoScreen extends StatelessWidget {
  const ComunicadoScreen({super.key});

  bool _hasPermission(String permission) {
    final sec = SecurityMatrix.current();
    final lower = permission.toLowerCase();
    if (lower.contains('create') || lower.contains('insert')) {
      return sec.canInsert(AppScreen.comunicados);
    }
    if (lower.contains('edit') || lower.contains('update')) {
      return sec.canUpdate(AppScreen.comunicados);
    }
    if (lower.contains('delete') || lower.contains('remove')) {
      return sec.canDelete(AppScreen.comunicados);
    }
    return sec.canView(AppScreen.comunicados);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GenericMobileGridScreen<ComunicadoMobile>(
        title: 'Comunicados',
        fetchEndpoint: ApiLinks.allComunicados,
        createEndpoint: ApiLinks.createComunicado,
        updateEndpoint: ApiLinks.updateComunicado(':id'),
        deleteEndpoint: ApiLinks.deleteComunicado(':id'),
        fieldConfigs: ComunicadoMobile.fieldConfigs,
        idFieldName: '_id',
        useUserBannerAppBar: true,
        enableSearch: true,
        storageKey: 'comunicado_mobile_grid',
        hasPermission: _hasPermission,
        fromJson: (json) =>
            ComunicadoMobile.fromJson(Map<String, dynamic>.from(json)),
        toJson: (obj) => obj.toJson(),
        paginationConfig: const PaginationConfig(
          defaultRowsPerPage: 20,
          availableRowsPerPage: [10, 20, 50],
        ),
      ),
    );
  }
}
