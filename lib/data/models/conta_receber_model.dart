// Classe Endereco
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/ui/widgets/field_factory.dart';

class ContaReceber {
  int? id;
  String descricao;
  double valor;
  DateTime dataVencimento;
  DateTime? dataBaixa;
  double? valorBaixa;
  String? formaPagamento;
  String status;
  int empresaId;
  DateTime createdAt;

  ContaReceber({
    this.id,
    required this.descricao,
    required this.valor,
    required this.dataVencimento,
    this.dataBaixa,
    this.valorBaixa,
    this.formaPagamento,
    required this.status,
    required this.empresaId,
    required this.createdAt,
  });

  factory ContaReceber.fromJson(Map<String, dynamic> json) {
    return ContaReceber(
      id: json['id'],
      descricao: json['descricao'],
      valor: json['valor'].toDouble(),
      dataVencimento: DateTime.parse(json['dataVencimento']),
      dataBaixa: json['dataBaixa'] != null
          ? DateTime.parse(json['dataBaixa'])
          : null,
      valorBaixa: json['valorBaixa']?.toDouble(),
      formaPagamento: json['formaPagamento'],
      status: json['status'],
      empresaId: json['empresaId'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descricao': descricao,
      'valor': valor,
      'dataVencimento': dataVencimento.toIso8601String(),
      'dataBaixa': dataBaixa?.toIso8601String(),
      'valorBaixa': valorBaixa,
      'formaPagamento': formaPagamento,
      'status': status,
      'empresaId': empresaId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static List<FieldConfig> fieldConfigs = [
    FieldConfig(
      label: "Descrição",
      fieldName: "descricao",
      icon: Icons.description,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    FieldConfig(
      label: "Valor",
      fieldName: "valor",
      icon: Icons.attach_money,
      isInForm: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    FieldConfig(
      label: "Data Vencimento",
      fieldName: "dataVencimento",
      icon: Icons.calendar_today,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    FieldConfig(
      label: "Status",
      fieldName: "status",
      icon: Icons.abc,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    FieldConfig(
      label: "Data Baixa",
      fieldName: "dataBaixa",
      icon: Icons.calendar_today,
      isVisibleByDefault: false,
      isFixed: false,
    ),
    FieldConfig(
      label: "Valor Baixa",
      fieldName: "valorBaixa",
      icon: Icons.attach_money,
      isVisibleByDefault: false,
      isFixed: false,
    ),
    FieldConfig(
      label: "Forma Pagamento",
      fieldName: "formaPagamento",
      icon: Icons.payment,
      isVisibleByDefault: false,
      isFixed: false,
    ),
  ];
}
