// conta_receber_model.dart
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

import '../customization/generic_grid_card.dart';
import 'audit_model.dart';
import 'empresa_model.dart';
import 'file_attachment_model.dart';
import 'forma_pagamento_model.dart';
import 'parceiro_model.dart';

enum StatusContaReceber { ABERTA, BAIXADA, CANCELADA }

class ContaReceber {
  int? id;
  String descricao;
  double valor;
  DateTime dataVencimento;
  DateTime? dataBaixa;
  double? valorBaixa;
  double? valorMulta;
  double? valorJuros;
  double? valorDesconto;
  StatusContaReceber status;
  Empresa empresa;
  Parceiro? cliente;
  Parceiro? clienteDev;
  FileAttachment? file;
  FormaPagamento? formaPagamento;
  Audit audit;

  ContaReceber({
    this.id,
    required this.descricao,
    required this.valor,
    required this.dataVencimento,
    this.dataBaixa,
    this.valorBaixa,
    this.valorMulta,
    this.valorJuros,
    this.valorDesconto,
    required this.status,
    required this.empresa,
    this.cliente,
    this.clienteDev,
    this.file,
    this.formaPagamento,
    required this.audit,
  });

  factory ContaReceber.fromJson(Map<String, dynamic> json) {
    return ContaReceber(
      id: json['id'],
      descricao: json['descricao'],
      valor: json['valor']?.toDouble() ?? 0.0,
      dataVencimento: DateTime.parse(json['dataVencimento']),
      dataBaixa:
          json['dataBaixa'] != null ? DateTime.parse(json['dataBaixa']) : null,
      valorBaixa: json['valorBaixa']?.toDouble(),
      valorMulta: json['valorMulta']?.toDouble(),
      valorJuros: json['valorJuros']?.toDouble(),
      valorDesconto: json['valorDesconto']?.toDouble(),
      status: _parseStatus(json['status']),
      empresa: Empresa.fromJson(json['empresa']),
      cliente:
          json['cliente'] != null ? Parceiro.fromJson(json['cliente']) : null,
      clienteDev: json['clienteDev'] != null
          ? Parceiro.fromJson(json['clienteDev'])
          : null,
      file: json['file'] != null ? FileAttachment.fromJson(json['file']) : null,
      formaPagamento: json['formaPagamento'] != null
          ? FormaPagamento.fromJson(json['formaPagamento'])
          : null,
      audit: Audit.fromJson(json['audit'] ?? {}),
    );
  }

  static StatusContaReceber _parseStatus(dynamic status) {
    if (status is int) {
      switch (status) {
        case 0:
          return StatusContaReceber.ABERTA;
        case 1:
          return StatusContaReceber.BAIXADA;
        case 2:
          return StatusContaReceber.CANCELADA;
        default:
          return StatusContaReceber.ABERTA;
      }
    } else if (status is String) {
      switch (status) {
        case 'ABERTA':
          return StatusContaReceber.ABERTA;
        case 'BAIXADA':
          return StatusContaReceber.BAIXADA;
        case 'CANCELADA':
          return StatusContaReceber.CANCELADA;
        default:
          return StatusContaReceber.ABERTA;
      }
    } else {
      return StatusContaReceber.ABERTA;
    }
  }

  int _statusToInt(StatusContaReceber status) {
    switch (status) {
      case StatusContaReceber.ABERTA:
        return 0;
      case StatusContaReceber.BAIXADA:
        return 1;
      case StatusContaReceber.CANCELADA:
        return 2;
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
      'valorMulta': valorMulta,
      'valorJuros': valorJuros,
      'valorDesconto': valorDesconto,
      'status': _statusToInt(status),
      'empresa': empresa.toJson(),
      'cliente': cliente?.toJson(),
      'clienteDev': clienteDev?.toJson(),
      'file': file?.toJson(),
      'formaPagamento': formaPagamento?.toJson(),
      'audit': audit.toJson(),
    };
  }

  // Classes auxiliares para as entidades relacionadas
  static Future<List<Map<String, dynamic>>> loadFormasPagamento() async {
    final NetworkResponse response = await NetworkCaller().getRequest(
      ApiLinks.allFormasPagamento,
    );

    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['dados'] ?? [];
      return data
          .map(
            (item) => {'value': item['id'], 'label': item['nome'].toString()},
          )
          .toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> loadClientes() async {
    final NetworkResponse response = await NetworkCaller().getRequest(
      ApiLinks
          .allParceiros, // Ou ApiLinks.allClientes se tiver endpoint específico
    );

    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['dados'] ?? [];
      return data
          .map(
            (item) => {'value': item['id'], 'label': item['nome'].toString()},
          )
          .toList();
    }
    return [];
  }

  static List<FieldConfig> fieldConfigs = [
    FieldConfig(
      label: "Cliente",
      fieldName: "parceiro.id",
      displayFieldName: "parceiro.nome",
      icon: Icons.person,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async => await loadClientes(),
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      isRequired: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    FieldConfig(
      label: "Cliente Dev",
      fieldName: "parceiroRec.id",
      displayFieldName: "parceiroRec.nome",
      icon: Icons.person,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async => await loadClientes(),
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      isRequired: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Descrição",
      fieldName: "descricao",
      icon: Icons.description,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Valor",
      fieldName: "valor",
      icon: Icons.attach_money,
      isInForm: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Data Vencimento",
      fieldName: "dataVencimento",
      icon: Icons.calendar_today,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Status",
      fieldName: "status",
      icon: Icons.info,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
      isInForm: false,
    ),
    const FieldConfig(
      label: "Data Baixa",
      fieldName: "dataBaixa",
      icon: Icons.calendar_today,
      isVisibleByDefault: false,
      isFixed: false,
      isInForm: false,
    ),
    const FieldConfig(
      label: "Valor Baixa",
      fieldName: "valorBaixa",
      icon: Icons.attach_money,
      isVisibleByDefault: false,
      isFixed: false,
      isInForm: false,
    ),
    const FieldConfig(
      label: "Valor Multa",
      fieldName: "valorMulta",
      icon: Icons.attach_money,
      isInForm: true,
      isVisibleByDefault: false,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Valor Juros",
      fieldName: "valorJuros",
      icon: Icons.attach_money,
      isInForm: true,
      isVisibleByDefault: false,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Valor Desconto",
      fieldName: "valorDesconto",
      icon: Icons.attach_money,
      isInForm: true,
      isVisibleByDefault: false,
      isFixed: false,
    ),
    FieldConfig(
      label: "Forma Pagamento",
      fieldName: "formaPagamento.id",
      displayFieldName: "formaPagamento.nome",
      icon: Icons.payment,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async => await loadFormasPagamento(),
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      isRequired: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Status",
      fieldName: "status",
      icon: Icons.check_circle,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
      fieldType: FieldType.dropdown,
      dropdownOptions: [
        {'value': 0, 'label': 'Aberta'},
        {'value': 1, 'label': 'Baixada'},
        {'value': 2, 'label': 'Cancelada'},
      ],
      dropdownSelectedValue: 0,
      enabled: false,
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
    ),
    const FieldConfig(
      label: "Anexo",
      fieldName: "file.id",
      displayFieldName: "file.nome",
      fieldType: FieldType.file,
      enabled: true,
    ),
  ];
}
