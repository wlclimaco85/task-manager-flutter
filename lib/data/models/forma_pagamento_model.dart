import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';

class FormaPagamento {
  int? id;
  String nome;
  String descricao;
  bool ativo;
  int empresaId;
  DateTime createdAt;

  FormaPagamento({
    this.id,
    required this.nome,
    required this.descricao,
    required this.ativo,
    required this.empresaId,
    required this.createdAt,
  });

  factory FormaPagamento.fromJson(Map<String, dynamic> json) {
    return FormaPagamento(
      id: json['id'],
      nome: json['nome'],
      descricao: json['descricao'],
      ativo: json['ativo'],
      empresaId: json['empresaId'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'ativo': ativo,
      'empresaId': empresaId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static List<FieldConfig> fieldConfigs = [
    FieldConfig(
      label: "Nome",
      fieldName: "nome",
      icon: Icons.payment,
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
      label: "Ativo",
      fieldName: "ativo",
      icon: Icons.check_circle,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    FieldConfig(
      label: "Data Criação",
      fieldName: "createdAt",
      icon: Icons.calendar_today,
      isVisibleByDefault: false,
      isFixed: false,
    ),
  ];
}
