import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
// Importe apenas field_types.dart, pois field_factory.dart também importa field_types.dart e pode causar conflito.
import 'package:task_manager_flutter/ui/widgets/field_types.dart';
import 'package:task_manager_flutter/ui/widgets/field_factory.dart'
    hide FieldConfig, FieldType;

// ... resto do código
import 'audit_model.dart';
import 'empresa_model.dart';
import 'file_attachment_model.dart';
import 'forma_pagamento_model.dart';
import 'parceiro_model.dart';

enum StatusConta { ABERTA, BAIXADA, CANCELADA }

class ContaPagar {
  int? id;
  String descricao;
  double valor;
  DateTime dataVencimento;
  DateTime? dataBaixa;
  double? valorBaixa;
  double? valorMulta;
  double? valorJuros;
  double? valorDesconto;
  StatusConta status;
  Empresa empresa;
  Parceiro? parceiro;
  Parceiro? parceiroDev;
  FileAttachment? file;
  FormaPagamento? formaPagamento;
  Audit audit;

  ContaPagar({
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
    this.parceiro,
    this.parceiroDev,
    this.file,
    this.formaPagamento,
    required this.audit,
  });

  factory ContaPagar.fromJson(Map<String, dynamic> json) {
    return ContaPagar(
      id: json['id'],
      descricao: json['descricao'],
      valor: json['valor']?.toDouble() ?? 0.0,
      dataVencimento: DateTime.parse(json['dataVencimento']),
      dataBaixa: json['dataBaixa'] != null
          ? DateTime.parse(json['dataBaixa'])
          : null,
      valorBaixa: json['valorBaixa']?.toDouble(),
      valorMulta: json['valorMulta']?.toDouble(),
      valorJuros: json['valorJuros']?.toDouble(),
      valorDesconto: json['valorDesconto']?.toDouble(),
      status: _parseStatus(json['status']),
      empresa: Empresa.fromJson(json['empresa']),
      parceiro: json['parceiro'] != null
          ? Parceiro.fromJson(json['parceiro'])
          : null,
      parceiroDev: json['parceiroDev'] != null
          ? Parceiro.fromJson(json['parceiroDev'])
          : null,
      file: json['file'] != null ? FileAttachment.fromJson(json['file']) : null,
      formaPagamento: json['formaPagamento'] != null
          ? FormaPagamento.fromJson(json['formaPagamento'])
          : null,
      audit: Audit.fromJson(json['audit'] ?? {}),
    );
  }

  static StatusConta _parseStatus(dynamic status) {
    if (status is int) {
      switch (status) {
        case 0:
          return StatusConta.ABERTA;
        case 1:
          return StatusConta.BAIXADA;
        case 2:
          return StatusConta.CANCELADA;
        default:
          return StatusConta.ABERTA;
      }
    } else if (status is String) {
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
    } else {
      return StatusConta.ABERTA;
    }
  }

  int _statusToInt(StatusConta status) {
    switch (status) {
      case StatusConta.ABERTA:
        return 0;
      case StatusConta.BAIXADA:
        return 1;
      case StatusConta.CANCELADA:
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
      'parceiro': parceiro?.toJson(),
      'parceiroDev': parceiroDev?.toJson(),
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

  static Future<List<Map<String, dynamic>>> loadParceiros() async {
    final NetworkResponse response = await NetworkCaller().getRequest(
      ApiLinks.allParceiros,
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
    // Campos principais
    FieldConfigBuilder.dropdown(
      label: "Fornecedor",
      fieldName: "parceiro.id",
      displayFieldName: "parceiro.nome",
      icon: Icons.business,
      dropdownFutureBuilder: () async => await loadParceiros(),
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      isRequired: true,
    ),

    FieldConfigBuilder.dropdown(
      label: "Fornecedor Dev",
      fieldName: "parceiroDev.id",
      displayFieldName: "parceiroDev.nome",
      icon: Icons.business,
      dropdownFutureBuilder: () async => await loadParceiros(),
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      isRequired: true,
    ),

    FieldConfigBuilder.text(
      label: "Descrição",
      fieldName: "descricao",
      icon: Icons.description,
      isRequired: true,
      maxLines: 3,
    ),

    FieldConfigBuilder.number(
      label: "Valor",
      fieldName: "valor",
      icon: Icons.attach_money,
      isRequired: true,
      decimalDigits: 2,
      minValue: 0,
    ),

    FieldConfigBuilder.date(
      label: "Data Vencimento",
      fieldName: "dataVencimento",
      icon: Icons.calendar_today,
      isRequired: true,
    ),

    // Campos de baixa (visíveis apenas quando necessário)
    FieldConfigBuilder.date(
      label: "Data Baixa",
      fieldName: "dataBaixa",
      icon: Icons.calendar_today,
      isRequired: false,
      isVisibleByDefault: false,
      isInForm: false,
    ),

    FieldConfigBuilder.number(
      label: "Valor Baixa",
      fieldName: "valorBaixa",
      icon: Icons.attach_money,
      decimalDigits: 2,
      minValue: 0,
      isVisibleByDefault: false,
      isInForm: false,
    ),

    // Campos de cálculos
    FieldConfigBuilder.number(
      label: "Valor Multa",
      fieldName: "valorMulta",
      icon: Icons.money_off,
      decimalDigits: 2,
      minValue: 0,
      isVisibleByDefault: false,
    ),

    FieldConfigBuilder.number(
      label: "Valor Juros",
      fieldName: "valorJuros",
      icon: Icons.percent,
      decimalDigits: 2,
      minValue: 0,
      isVisibleByDefault: false,
    ),

    FieldConfigBuilder.number(
      label: "Valor Desconto",
      fieldName: "valorDesconto",
      icon: Icons.discount,
      decimalDigits: 2,
      minValue: 0,
      isVisibleByDefault: false,
    ),

    // Forma de pagamento
    FieldConfigBuilder.dropdown(
      label: "Forma Pagamento",
      fieldName: "formaPagamento.id",
      displayFieldName: "formaPagamento.nome",
      icon: Icons.payment,
      dropdownFutureBuilder: () async => await loadFormasPagamento(),
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      isRequired: true,
    ),

    // Status (apenas um campo - removido o duplicado)
    FieldConfig(
      label: "Status",
      fieldName: "status",
      icon: Icons.check_circle,
      fieldType: FieldType.dropdown,
      isFilterable: true,
      isVisibleByDefault: true,
      isInForm: false, // Não editável no formulário, apenas visual
      isFixed: false,
      dropdownOptions: [
        {'value': 0, 'label': 'Aberta'},
        {'value': 1, 'label': 'Baixada'},
        {'value': 2, 'label': 'Cancelada'},
      ],
      dropdownSelectedValue: 0,
      enabled: false, // Readonly
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Status é obrigatório';
        }
        return null;
      },
    ),

    // Anexo
    FieldConfig(
      label: "Anexo",
      fieldName: "file",
      fieldType: FieldType.file,
      icon: Icons.attach_file,
      isRequired: false,
      isVisibleByDefault: false,
      fileConfig: FileConfig(
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
        maxFileSize: 10 * 1024 * 1024, // 10MB
        fileFieldName: 'anexo',
      ),
      enabled: true,
      fieldSpecificConfig: {'showPreview': true, 'maxFiles': 3},
    ),
  ];
}
