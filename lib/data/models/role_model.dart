import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/data/models/aplicativo_model.dart';

class Role {
  int? id;
  String? description;
  bool? available;
  String? key;
  Aplicativo? aplicativo;

  Role({this.id, this.description, this.available, this.key, this.aplicativo});

  Role.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    description = json['description'];
    available = json['available'];
    key = json['key'];
    aplicativo = json['aplicativo'] != null
        ? Aplicativo.fromJson(json['aplicativo'])
        : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'available': available,
      'key': key,
      'aplicativo': aplicativo?.toJson(),
    };
  }

  static List<FieldConfig> fieldConfigs = [
    FieldConfig(
      label: "Descrição",
      fieldName: "description",
      icon: Icons.description,
      isInForm: true,
      isFilterable: true,
    ),
    FieldConfig(
      label: "Disponível",
      fieldName: "available",
      icon: Icons.check_circle,
      isInForm: true,
      isFilterable: true,
    ),
    FieldConfig(
      label: "Chave",
      fieldName: "key",
      icon: Icons.vpn_key,
      isInForm: true,
      isFilterable: true,
    ),
    FieldConfig(
      label: "Aplicativo",
      fieldName: "aplicativo.nome", // aqui mostra o nome do aplicativo
      icon: Icons.apps,
      isInForm: false, // não edita direto aqui
      isFilterable: true,
    ),
  ];
}
