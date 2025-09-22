import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/field_factory.dart';

class Chamado {
  int? id;
  String titulo;
  String descricao;
  String status;
  String prioridade;
  int empresaId;
  int? usuarioId;
  DateTime createdAt;
  DateTime updatedAt;

  Chamado({
    this.id,
    required this.titulo,
    required this.descricao,
    required this.status,
    required this.prioridade,
    required this.empresaId,
    this.usuarioId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Chamado.fromJson(Map<String, dynamic> json) {
    return Chamado(
      id: json['id'],
      titulo: json['titulo'],
      descricao: json['descricao'],
      status: json['status'],
      prioridade: json['prioridade'],
      empresaId: json['empresaId'],
      usuarioId: json['usuarioId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'status': status,
      'prioridade': prioridade,
      'empresaId': empresaId,
      'usuarioId': usuarioId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static List<FieldConfig> fieldConfigs = [
    FieldConfig(
      label: "Título",
      fieldName: "titulo",
      icon: Icons.title,
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
      label: "Status",
      fieldName: "status",
      icon: Icons.info,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    FieldConfig(
      label: "Prioridade",
      fieldName: "prioridade",
      icon: Icons.priority_high,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    FieldConfig(
      label: "Data Criação",
      fieldName: "createdAt",
      icon: Icons.calendar_today,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    FieldConfig(
      label: "Última Atualização",
      fieldName: "updatedAt",
      icon: Icons.update,
      isVisibleByDefault: false,
      isFixed: false,
    ),
  ];
}
