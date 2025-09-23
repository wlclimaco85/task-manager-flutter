import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';

class Mensalidade {
  int? id;
  double? valor;
  DateTime? dtPagamento;
  int? alunoId;
  int? planoId;

  Mensalidade({
    this.id,
    this.valor,
    this.dtPagamento,
    this.alunoId,
    this.planoId,
  });

  Mensalidade.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    valor = (json['valor'] as num?)?.toDouble();
    dtPagamento = json['dtPagamento'] != null
        ? DateTime.parse(json['dtPagamento'])
        : null;
    alunoId = json['alunoId'];
    planoId = json['planoId'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'valor': valor,
      'dtPagamento': dtPagamento?.toIso8601String(),
      'alunoId': alunoId,
      'planoId': planoId,
    };
  }

  static List<FieldConfig> fieldConfigs = [
    FieldConfig(
      label: "Valor",
      fieldName: "valor",
      icon: Icons.attach_money,
      isInForm: true,
      isFilterable: true,
    ),
    FieldConfig(
      label: "Data Pagamento",
      fieldName: "dtPagamento",
      icon: Icons.date_range,
      isInForm: true,
    ),
    FieldConfig(
      label: "Aluno ID",
      fieldName: "alunoId",
      icon: Icons.person,
      isInForm: true,
    ),
    FieldConfig(
      label: "Plano ID",
      fieldName: "planoId",
      icon: Icons.assignment,
      isInForm: true,
    ),
  ];
}
