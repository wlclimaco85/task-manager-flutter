import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';

class Diretorio {
  int? id;
  String nome;
  String descricao;
  int empresaId;
  DateTime createdAt;
  DateTime updatedAt;

  Diretorio({
    this.id,
    required this.nome,
    required this.descricao,
    required this.empresaId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Diretorio.fromJson(Map<String, dynamic> json) {
    return Diretorio(
      id: json['id'],
      nome: json['nome'],
      descricao: json['descricao'],
      empresaId: json['empresaId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'empresaId': empresaId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static Future<List<Map<String, dynamic>>> loadCategorias() async {
    final NetworkResponse response = await NetworkCaller().getRequest(
      ApiLinks.getCategorias,
    );

    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['account'] ?? [];
      return data
          .map(
            (item) => {
              'value': item['id'].toString(),
              'label': item['descricao'],
            },
          )
          .toList();
    }
    return [];
  }

  static List<FieldConfig> fieldConfigs = [
    FieldConfig(
      label: "Nome",
      fieldName: "nome",
      icon: Icons.folder,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    FieldConfig(
      label: "Descrição",
      fieldName: "descricao",
      icon: Icons.description,
      isInForm: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    FieldConfig(
      label: "Empresa",
      fieldName: "empresaId",
      displayFieldName: "empresa.nome",
      icon: Icons.business,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async {
        return await loadCategorias();
      },
      dropdownValueField: 'id',
      dropdownDisplayField: 'nome',
      isRequired: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
  ];
}
