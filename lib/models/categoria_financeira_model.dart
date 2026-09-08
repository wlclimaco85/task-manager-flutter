import 'package:flutter/material.dart';

import '../widgets/generic_grid_screen.dart';

class CategoriaFinanceira {
  int? id;
  String? nome;
  String? descricao;
  String? tipo;
  bool? ativa;
  int? parentId;
  String? codigo;
  bool? analitico;

  CategoriaFinanceira({
    this.id,
    this.nome,
    this.descricao,
    this.tipo = 'AMBOS',
    this.ativa = true,
    this.parentId,
    this.codigo,
    this.analitico = true,
  });

  factory CategoriaFinanceira.fromJson(Map<String, dynamic> json) {
    return CategoriaFinanceira(
      id: json['id'],
      nome: json['nome']?.toString(),
      descricao: json['descricao']?.toString(),
      tipo: json['tipo']?.toString(),
      ativa: json['ativa'] == true || json['ativa'] == 'true',
      parentId: json['parentId'] ?? json['parent_id'] ?? (json['parent'] != null ? json['parent']['id'] : null),
      codigo: json['codigo']?.toString(),
      analitico: json['analitico'] == true || json['analitico'] == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'tipo': tipo,
      'ativa': ativa,
      'parent': parentId != null ? {'id': parentId} : null,
      'codigo': codigo,
      'analitico': analitico,
    };
  }

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(
      label: 'Código',
      fieldName: 'codigo',
      icon: Icons.numbers,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: true,
    ),
    const FieldConfig(
      label: 'Nome',
      fieldName: 'nome',
      icon: Icons.category,
      isInForm: true,
      isFilterable: true,
      isRequired: true,
      isVisibleByDefault: true,
      isFixed: true,
    ),
    const FieldConfig(
      label: 'Descrição',
      fieldName: 'descricao',
      icon: Icons.description,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: 'Ativa',
      fieldName: 'ativa',
      icon: Icons.check_circle,
      isInForm: true,
      fieldType: FieldType.boolean,
      isVisibleByDefault: true,
    ),
    const FieldConfig(
      label: 'Analítico',
      fieldName: 'analitico',
      icon: Icons.account_tree,
      isInForm: true,
      fieldType: FieldType.boolean,
      isVisibleByDefault: true,
    ),
  ];
}
