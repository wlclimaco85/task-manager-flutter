import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class CentroCusto {
  int? id;
  String? nome;
  int? parentId;
  String? codigo;
  bool? analitico;

  CentroCusto({this.id, this.nome, this.parentId, this.codigo, this.analitico = true});

  factory CentroCusto.fromJson(Map<String, dynamic> json) => CentroCusto(
        id: json['id'],
        nome: json['nome']?.toString(),
        parentId: json['parentId'] ?? json['parent_id'] ?? (json['parent'] != null ? json['parent']['id'] : null),
        codigo: json['codigo']?.toString(),
        analitico: json['analitico'] == true || json['analitico'] == 'true',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'parent': parentId != null ? {'id': parentId} : null,
        'codigo': codigo,
        'analitico': analitico,
      };

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(label: "Código", fieldName: "codigo", icon: Icons.numbers, isInForm: true, isFilterable: true, isFixed: true),
    const FieldConfig(label: "Nome", fieldName: "nome", icon: Icons.account_balance, isInForm: true, isFilterable: true, isFixed: true, isRequired: true),
    const FieldConfig(label: "Analítico", fieldName: "analitico", icon: Icons.account_tree, isInForm: true, fieldType: FieldType.boolean, isVisibleByDefault: true),
  ];
}
