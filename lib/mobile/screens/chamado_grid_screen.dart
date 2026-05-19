import 'package:flutter/material.dart';

import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../utils/api_links.dart';

// WINDOWS (DynamicGridWindowsScreen / GenericDetailFormScreen)
import '../../../widgets/generic_grid_windows_screen.dart' as win;

// MOBILE (GenericMobileGridScreen / generic_grid_card)
import '../../../customization/generic_grid_card.dart' as mob;

import '../../../models/login_model.dart';
import '../../../models/empresa_model.dart';
import '../../../models/parceiro_model.dart';
import '../../../models/setor_model.dart';

// =========================================================
// ENUMS
// =========================================================

enum StatusChamadoEnum {
  ABERTO(1, "Aberto"),
  EM_ANDAMENTO(2, "Em Andamento"),
  FECHADO(3, "Fechado"),
  CANCELADO(4, "Cancelado");

  final int value;
  final String label;
  const StatusChamadoEnum(this.value, this.label);

  static StatusChamadoEnum fromString(String s) =>
      values.firstWhere((e) => e.name.toUpperCase() == s.toUpperCase());
}

enum PrioridadeChamadoEnum {
  BAIXA(1, "Baixa"),
  MEDIA(2, "Média"),
  ALTA(3, "Alta"),
  URGENTE(4, "Urgente");

  final int value;
  final String label;
  const PrioridadeChamadoEnum(this.value, this.label);

  static PrioridadeChamadoEnum fromString(String s) =>
      values.firstWhere((e) => e.name.toUpperCase() == s.toUpperCase());
}

// =========================================================
// MODEL CHAMADO
// =========================================================

class Chamado {
  int? id;
  String titulo;
  String descricao;
  String? motivoFechamento;

  StatusChamadoEnum status;
  PrioridadeChamadoEnum prioridade;

  Empresa empresa;
  Login? usuarioAbertura;
  Login? usuarioFechamento;
  Parceiro? parceiro;
  Setor? setor;

  DateTime dataAbertura;
  DateTime? dataFechamento;

  Chamado({
    this.id,
    required this.titulo,
    required this.descricao,
    this.motivoFechamento,
    required this.status,
    required this.prioridade,
    required this.empresa,
    this.usuarioAbertura,
    this.usuarioFechamento,
    this.parceiro,
    this.setor,
    required this.dataAbertura,
    this.dataFechamento,
  });

  factory Chamado.fromJson(Map<String, dynamic> json) {
    return Chamado(
      id: json['id'],
      titulo: json['titulo'],
      descricao: json['descricao'],
      motivoFechamento: json['motivoFechamento'],
      status: StatusChamadoEnum.fromString(json['status']),
      prioridade: PrioridadeChamadoEnum.fromString(json['prioridade']),
      empresa: Empresa.fromJson(json['empresa']),
      usuarioAbertura: json['usuarioAbertura'] != null
          ? Login.fromJson(json['usuarioAbertura'])
          : null,
      usuarioFechamento: json['usuarioFechamento'] != null
          ? Login.fromJson(json['usuarioFechamento'])
          : null,
      parceiro:
          json['parceiro'] != null ? Parceiro.fromJson(json['parceiro']) : null,
      setor: json['setor'] != null ? Setor.fromJson(json['setor']) : null,
      dataAbertura: json['dataAbertura'] != null
          ? DateTime.parse(json['dataAbertura'])
          : DateTime.now(),
      dataFechamento: json['dataFechamento'] != null
          ? DateTime.parse(json['dataFechamento'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'motivoFechamento': motivoFechamento,
      // aqui mando o name (string) pra bater com o fromString do backend
      'status': status.name,
      'prioridade': prioridade.name,
      'empresa': empresa.toJson(),
      'usuarioAbertura': usuarioAbertura?.toJson(),
      'usuarioFechamento': usuarioFechamento?.toJson(),
      'parceiro': parceiro?.toJson(),
      'setor': setor?.toJson(),
      'dataAbertura': dataAbertura.toIso8601String(),
      'dataFechamento': dataFechamento?.toIso8601String(),
    };
  }

  // =========================================================
  // DROPDOWNS
  // =========================================================

  static List<Map<String, dynamic>> getStatusDropdownItems() {
    return StatusChamadoEnum.values
        .map((e) => {'value': e.name, 'label': e.label})
        .toList();
  }

  static List<Map<String, dynamic>> getPrioridadeDropdownItems() {
    return PrioridadeChamadoEnum.values
        .map((e) => {'value': e.name, 'label': e.label})
        .toList();
  }

  static Future<List<Map<String, dynamic>>> loadSetores() async {
    final NetworkResponse res =
        await NetworkCaller().getRequest(ApiLinks.allSetores);

    if (res.isSuccess && res.body != null) {
      final List<dynamic> dados = res.body!["data"]["dados"] ?? [];
      return dados
          .map<Map<String, dynamic>>(
            (item) => {
              'value': item['id'].toString(),
              'label': item['descricao'].toString(),
            },
          )
          .toList();
    }
    return [];
  }

  // =========================================================
  // FIELDS WINDOWS (DynamicGridWindowsScreen / Detail Windows)
  // =========================================================

  static List<win.FieldConfigWindows> fieldConfigsWindows = [
    const win.FieldConfigWindows(
      label: "Título",
      fieldName: "titulo",
      icon: Icons.title,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: true,
      fieldType: win.FieldType.text,
    ),
    const win.FieldConfigWindows(
      label: "Descrição",
      fieldName: "descricao",
      icon: Icons.description,
      isInForm: true,
      isVisibleByDefault: true,
      fieldType: win.FieldType.multiline,
      maxLines: 4,
    ),
    win.FieldConfigWindows(
      label: "Status",
      fieldName: "status",
      icon: Icons.info,
      isFilterable: true,
      isVisibleByDefault: true,
      fieldType: win.FieldType.dropdown,
      dropdownOptions: getStatusDropdownItems(),
      dropdownSelectedValue: StatusChamadoEnum.ABERTO.name,
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
    ),
    win.FieldConfigWindows(
      label: "Prioridade",
      fieldName: "prioridade",
      icon: Icons.flag,
      isFilterable: true,
      isVisibleByDefault: true,
      fieldType: win.FieldType.dropdown,
      dropdownOptions: getPrioridadeDropdownItems(),
      dropdownSelectedValue: PrioridadeChamadoEnum.BAIXA.name,
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
    ),
    win.FieldConfigWindows(
      label: "Parceiro",
      fieldName: "parceiro.id",
      displayFieldName: "parceiro.nome",
      icon: Icons.person,
      isInForm: true,
      isFilterable: true,
      fieldType: win.FieldType.dropdown,
      dropdownFutureBuilder: () => Parceiro.loadCategorias(),
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
    ),
    win.FieldConfigWindows(
      label: "Setor",
      fieldName: "setor.id",
      displayFieldName: "setor.descricao",
      icon: Icons.business,
      isInForm: true,
      isFilterable: true,
      fieldType: win.FieldType.dropdown,
      dropdownFutureBuilder: () => loadSetores(),
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
    ),
    const win.FieldConfigWindows(
      label: "Motivo Fechamento",
      fieldName: "motivoFechamento",
      icon: Icons.close,
      isInForm: false,
      isVisibleByDefault: false,
      fieldType: win.FieldType.text,
    ),
  ];

  // =========================================================
  // FIELDS MOBILE (GenericMobileGridScreen)
  // =========================================================

  static List<mob.FieldConfig> fieldConfigsMobile() {
    return fieldConfigsWindows.map((fw) {
      return mob.FieldConfig(
        label: fw.label,
        fieldName: fw.fieldName,
        icon: fw.icon,
        isInForm: fw.isInForm,
        isFilterable: fw.isFilterable ?? true,
        isVisibleByDefault: fw.isVisibleByDefault ?? true,
        isFixed: fw.isFixed ?? false,
        fieldType: mob.FieldType.values[fw.fieldType.index],
        dropdownOptions: fw.dropdownOptions,
        dropdownFutureBuilder: fw.dropdownFutureBuilder,
        dropdownValueField: fw.dropdownValueField,
        dropdownDisplayField: fw.dropdownDisplayField,
      );
    }).toList();
  }
}
