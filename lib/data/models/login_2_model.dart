import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/data/models/parceiro_model.dart';
import 'package:task_manager_flutter/data/models/empresa_model.dart';
import 'package:task_manager_flutter/data/models/aplicativo_model.dart';

class Login {
  int? id;
  String? email;
  String? senha;
  String? nome;
  String? cpfCnpj;
  List<Role>? roles;
  LoginEnum? tipoLogin;
  Empresa? empresa;
  Parceiro? parceiro;
  Aplicativo? aplicativo;
  DateTime? dhCreatedAt;
  DateTime? dhUpdatedAt;

  Login({
    this.id,
    this.email,
    this.senha,
    this.nome,
    this.cpfCnpj,
    this.roles,
    this.tipoLogin,
    this.empresa,
    this.parceiro,
    this.aplicativo,
    this.dhCreatedAt,
    this.dhUpdatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'senha': senha,
      'nome': nome,
      'cpfCnpj': cpfCnpj,
      'roles': roles?.map((role) => role.toJson()).toList(),
      'tipoLogin': tipoLogin?.index,
      'empresa': empresa?.toJson(),
      'parceiro': parceiro?.toJson(),
      'aplicativo': aplicativo?.toJson(),
      'dhCreatedAt': dhCreatedAt?.toIso8601String(),
      'dhUpdatedAt': dhUpdatedAt?.toIso8601String(),
    };
  }

  Login.fromJson(Map<String, dynamic> json) {
    if (json.isNotEmpty) {
      id = json['id'];
      email = json['email'];
      senha = json['senha'];
      nome = json['nome'];
      cpfCnpj = json['cpfCnpj'];
      roles = json['roles'] != null
          ? (json['roles'] as List).map((i) => Role.fromJson(i)).toList()
          : null;
      // No método fromJson, substitua a linha problemática por:
      if (json['tipoLogin'] != null) {
        // Converte para int se for string
        final tipoLoginValue = json['tipoLogin'] is String
            ? int.tryParse(json['tipoLogin'])
            : json['tipoLogin'] as int?;

        tipoLogin = tipoLoginValue != null
            ? LoginEnum.fromValue(tipoLoginValue)
            : LoginEnum.APP_ABRACO; // valor padrão
      } else {
        tipoLogin = LoginEnum.APP_ABRACO; // valor padrão se for nulo
      }
      aplicativo = json['aplicativo'] != null
          ? Aplicativo.fromJson(json['endereco'])
          : null;
      empresa = json['empresa'] != null
          ? Empresa.fromJson(json['empresa'])
          : null;
      parceiro = json['parceiro'] != null
          ? Parceiro.fromJson(json['regime'])
          : null;
      dhCreatedAt = json['audit][dhCreatedAt'] != null
          ? DateTime.parse(json['audit][dhCreatedAt'])
          : null;
      dhUpdatedAt = json['audit][dhUpdatedAt'] != null
          ? DateTime.parse(json['audit][dhUpdatedAt'])
          : null;
    }
  }

  static List<FieldConfig> fieldConfigs = [
    FieldConfig(
      label: "Email",
      fieldName: "email",
      icon: Icons.email,
      isFilterable: true,
      isInForm: true,
      isRequired: true,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Email é obrigatório';
        if (!value.contains('@')) return 'Email inválido';
        return null;
      },
    ),
    FieldConfig(
      label: "Senha",
      fieldName: "senha",
      icon: Icons.lock,
      isInForm: true,
      isRequired: true,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Senha é obrigatória';
        if (value.length < 6) return 'Senha deve ter pelo menos 6 caracteres';
        return null;
      },
    ),
    FieldConfig(
      label: "Nome",
      fieldName: "nome",
      icon: Icons.person,
      isFilterable: true,
      isInForm: true,
      isRequired: true,
    ),
    FieldConfig(
      label: "CPF/CNPJ",
      fieldName: "cpfCnpj",
      icon: Icons.badge,
      isFilterable: true,
      isInForm: true,
    ),
    FieldConfig(
      label: "Tipo Login",
      fieldName: "tipoLogin",
      icon: Icons.login,
      isFilterable: false,
      isInForm: false,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async {
        return LoginEnum.values
            .map((e) => {'value': e.name, 'label': e.name})
            .toList();
      },
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      isRequired: true,
    ),
  ];
}

// Primeiro, defina o LoginEnum com valores explícitos para evitar problemas
enum LoginEnum {
  MASTER(0, 'Administrador'),
  APP_PERSONAL(1, 'Usuário'),
  APP_ACADEMIA(2, 'Parceiro'),
  APP_NUTRICIONISTA(3, 'Parceiro'),
  APP_ALUNO(4, 'Parceiro'),
  APP_ABRACO(5, 'Parceiro'),
  APP_CONTABILIDADE(6, 'Parceiro'),
  APP_AGROPECUARIA(7, 'Parceiro');

  final int value;
  final String label;
  const LoginEnum(this.value, this.label);

  // Método para converter de valor inteiro para enum
  static LoginEnum fromValue(int value) {
    return LoginEnum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => LoginEnum.APP_ABRACO, // valor padrão se não encontrado
    );
  }
}

class Role {
  // Add role properties
  Map<String, dynamic> toJson() => {};
  static Role fromJson(Map<String, dynamic> json) => Role();
}
