import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/field_factory.dart';

class Plano {
  int? id;
  String? nome;
  String? descricao;
  double? valor;

  Plano({this.id, this.nome, this.descricao, this.valor});

  Plano.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nome = json['nome'];
    descricao = json['descricao'];
    valor = (json['valor'] as num?)?.toDouble();
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nome': nome, 'descricao': descricao, 'valor': valor};
  }

  static List<FieldConfig> fieldConfigs = [
    FieldConfig(
      label: "Nome",
      fieldName: "nome",
      icon: Icons.assignment,
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
      label: "Valor",
      fieldName: "valor",
      icon: Icons.attach_money,
      isInForm: true,
      isFilterable: true,
    ),
  ];
}
