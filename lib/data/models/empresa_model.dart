import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/models/aplicativo_model.dart';

class Empresa {
  int? id;
  String? nome;
  String? razaoSocial;
  String? email;
  String? site;
  String? contato;
  String? emailContato;
  String? telefoneContato;
  String? telefone;
  String? rua;
  String? numero;
  String? cidade;
  String? cep;
  Aplicativo? aplicativo; // Pode ser detalhado depois como um model separado

  Empresa({
    this.id,
    this.nome,
    this.razaoSocial,
    this.email,
    this.site,
    this.contato,
    this.emailContato,
    this.telefoneContato,
    this.telefone,
    this.rua,
    this.numero,
    this.cidade,
    this.cep,
    this.aplicativo,
  });

  Empresa.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nome = json['nome'];
    razaoSocial = json['razaoSocial'];
    email = json['email'];
    site = json['site'];
    contato = json['contato'];
    emailContato = json['emailContato'];
    telefoneContato = json['telefoneContato'];
    telefone = json['telefone'];
    rua = json['rua'];
    numero = json['numero'];
    cidade = json['cidade'];
    cep = json['cep'];
    aplicativo = json['aplicativo'] != null
        ? Aplicativo.fromJson(json['aplicativo'])
        : null; // pode ser adaptado se tiver DTO no back
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'razaoSocial': razaoSocial,
      'email': email,
      'site': site,
      'contato': contato,
      'emailContato': emailContato,
      'telefoneContato': telefoneContato,
      'telefone': telefone,
      'rua': rua,
      'numero': numero,
      'cidade': cidade,
      'cep': cep,
      'aplicativo': aplicativo?.toJson(),
    };
  }

  static Future<List<Map<String, dynamic>>> loadAplicativos() async {
    final NetworkResponse response = await NetworkCaller().getRequest(
      ApiLinks.allAplicativos,
    );

    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['dados'] ?? [];
      return data
          .map(
            (item) => {'value': item['id'].toString(), 'label': item['nome']},
          )
          .toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> loadCategorias() async {
    final NetworkResponse response = await NetworkCaller().getRequest(
      ApiLinks.allRegimetributario,
    );

    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['dados'] ?? [];
      return data
          .map(
            (item) => {'value': item['id'].toString(), 'label': item['codigo']},
          )
          .toList();
    }
    return [];
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
      label: "Telefone Contato",
      fieldName: "telefoneContato",
      icon: Icons.phone_in_talk,
      isInForm: true,
    ),
    FieldConfig(
      label: "Email Contato",
      fieldName: "emailContato",
      icon: Icons.contact_mail,
      isInForm: true,
    ),
    FieldConfig(
      label: "Rua",
      fieldName: "rua",
      icon: Icons.home,
      isInForm: true,
    ),
    FieldConfig(
      label: "Número",
      fieldName: "numero",
      icon: Icons.confirmation_number,
      isInForm: true,
    ),
    FieldConfig(
      label: "Cidade",
      fieldName: "cidade",
      icon: Icons.location_city,
      isInForm: true,
      isFilterable: true,
    ),
    FieldConfig(
      label: "CEP",
      fieldName: "cep",
      icon: Icons.local_post_office,
      isInForm: true,
    ),
    FieldConfig(
      label: "Aplicativo",
      fieldName: "aplicativo",
      displayFieldName: "aplicativo.nome",
      icon: Icons.apps,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async {
        return await loadAplicativos();
      },
      dropdownValueField: 'id',
      dropdownDisplayField: 'nome',
      isRequired: true,
    ),
    FieldConfig(
      label: "Regime",
      fieldName: "regime", // Para o formulário (dropdown)
      displayFieldName: "regime.codigo", // Para exibição na grid
      icon: Icons.business_center,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async {
        return await loadCategorias();
      },
      dropdownValueField: 'id',
      dropdownDisplayField: 'codigo',
      isRequired: true,
    ),
  ];
}
