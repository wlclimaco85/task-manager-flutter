import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';

class Exercicio {
  int? id;
  String? nome;
  String? descricao;
  int? grupoMuscularId;

  Exercicio({this.id, this.nome, this.descricao, this.grupoMuscularId});

  Exercicio.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nome = json['nome'];
    descricao = json['descricao'];
    grupoMuscularId = json['grupoMuscularId'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'grupoMuscularId': grupoMuscularId,
    };
  }

  static List<FieldConfig> fieldConfigs = [
    FieldConfig(
      label: "Nome",
      fieldName: "nome",
      icon: Icons.fitness_center,
      isInForm: true,
      isFilterable: true,
    ),
    FieldConfig(
      label: "Descrição",
      fieldName: "descricao",
      icon: Icons.description,
      isInForm: true,
    ),
    FieldConfig(
      label: "Grupo Muscular ID",
      fieldName: "grupoMuscularId",
      icon: Icons.group,
      isInForm: true,
      isFilterable: true,
    ),
  ];
}
