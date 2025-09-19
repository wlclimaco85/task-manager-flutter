import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';

enum StatusConta { ABERTA, BAIXADA, CANCELADA }

class ContaPagar {
  int? id;
  String descricao;
  double valor;
  DateTime dataVencimento;
  DateTime? dataBaixa;
  double? valorBaixa;
  String? formaPagamento;
  StatusConta status;
  int empresaId;
  DateTime createdAt;

  ContaPagar({
    this.id,
    required this.descricao,
    required this.valor,
    required this.dataVencimento,
    this.dataBaixa,
    this.valorBaixa,
    this.formaPagamento,
    this.status = StatusConta.ABERTA,
    required this.empresaId,
    required this.createdAt,
  });

  factory ContaPagar.fromJson(Map<String, dynamic> json) {
    return ContaPagar(
      id: json['id'],
      descricao: json['descricao'],
      valor: json['valor'].toDouble(),
      dataVencimento: DateTime.parse(json['dataVencimento']),
      dataBaixa: json['dataBaixa'] != null
          ? DateTime.parse(json['dataBaixa'])
          : null,
      valorBaixa: json['valorBaixa']?.toDouble(),
      formaPagamento: json['formaPagamento'],
      status: _parseStatus(json['status']),
      empresaId: json['empresaId'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  static StatusConta _parseStatus(String status) {
    switch (status) {
      case 'ABERTA':
        return StatusConta.ABERTA;
      case 'BAIXADA':
        return StatusConta.BAIXADA;
      case 'CANCELADA':
        return StatusConta.CANCELADA;
      default:
        return StatusConta.ABERTA;
    }
  }

  String _statusToString(StatusConta status) {
    switch (status) {
      case StatusConta.ABERTA:
        return 'ABERTA';
      case StatusConta.BAIXADA:
        return 'BAIXADA';
      case StatusConta.CANCELADA:
        return 'CANCELADA';
    }
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
      'status': _statusToString(status),
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
      icon: Icons.info,
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
