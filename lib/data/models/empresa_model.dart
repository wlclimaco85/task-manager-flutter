import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';

class Empresa {
  int? id;
  String? nome;
  String? razaoSocial;
  String? email;
  String? site;
  String? contato;
  String? telefone;
  String? cidade;

  Empresa({
    this.id,
    this.nome,
    this.razaoSocial,
    this.email,
    this.site,
    this.contato,
    this.telefone,
    this.cidade,
  });

  Empresa.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nome = json['nome'];
    razaoSocial = json['razaoSocial'];
    email = json['email'];
    site = json['site'];
    contato = json['contato'];
    telefone = json['telefone'];
    cidade = json['cidade'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'razaoSocial': razaoSocial,
      'email': email,
      'site': site,
      'contato': contato,
      'telefone': telefone,
      'cidade': cidade,
    };
  }

  static List<FieldConfig> fieldConfigs = [
    FieldConfig(
      label: "Nome",
      fieldName: "nome",
      icon: Icons.business,
      isInForm: true,
      isFilterable: true,
    ),
    FieldConfig(
      label: "Razão Social",
      fieldName: "razaoSocial",
      icon: Icons.apartment,
      isInForm: true,
      isFilterable: true,
    ),
    FieldConfig(
      label: "Email",
      fieldName: "email",
      icon: Icons.email,
      isInForm: true,
    ),
    FieldConfig(
      label: "Telefone",
      fieldName: "telefone",
      icon: Icons.phone,
      isInForm: true,
    ),
    FieldConfig(
      label: "Cidade",
      fieldName: "cidade",
      icon: Icons.location_city,
      isInForm: true,
      isFilterable: true,
    ),
  ];
}
