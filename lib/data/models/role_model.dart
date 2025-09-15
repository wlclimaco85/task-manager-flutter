import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';

class Role {
  int? id;
  String? nome;

  Role({this.id, this.nome});

  Role.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nome = json['nome'];
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nome': nome};
  }

  static List<FieldConfig> fieldConfigs = [
    FieldConfig(
      label: "Nome",
      fieldName: "nome",
      icon: Icons.security,
      isInForm: true,
      isFilterable: true,
    ),
  ];
}
