import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/aplicativo_model.dart';
import 'package:task_manager_flutter/data/models/audit_model.dart';
import 'package:task_manager_flutter/data/models/file_attachment_model.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/models/regime_tributario_model.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

import '../customization/generic_grid_card.dart';

enum Ambiente { HOMOLOGACAO, PRODUCAO }

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
  String? cnpj;
  String? ie;
  Ambiente? ambiente;
  Aplicativo? aplicativo;
  RegimeTributario? regime;
  FileAttachment? fileAttachment;
  Audit? audit;

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
    this.cnpj,
    this.ie,
    this.ambiente,
    this.aplicativo,
    this.regime,
    this.fileAttachment,
    this.audit,
  });

  // === Deserialização (fromJson)
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
    cnpj = json['cnpj'];
    ie = json['ie'];

    if (json['ambiente'] != null) {
      ambiente = Ambiente.values.firstWhere(
        (e) =>
            e.name.toUpperCase() == json['ambiente'].toString().toUpperCase(),
        orElse: () => Ambiente.HOMOLOGACAO,
      );
    }

    aplicativo = json['aplicativo'] != null
        ? Aplicativo.fromJson(json['aplicativo'])
        : null;

    regime = json['regime'] != null
        ? RegimeTributario.fromJson(json['regime'])
        : null;

    fileAttachment = json['fileAttachment'] != null
        ? FileAttachment.fromJson(json['fileAttachment'])
        : null;

    audit = json['audit'] != null ? Audit.fromJson(json['audit']) : null;
  }

  // === Serialização (toJson)
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['nome'] = nome;
    data['razaoSocial'] = razaoSocial;
    data['email'] = email;
    data['site'] = site;
    data['contato'] = contato;
    data['emailContato'] = emailContato;
    data['telefoneContato'] = telefoneContato;
    data['telefone'] = telefone;
    data['rua'] = rua;
    data['numero'] = numero;
    data['cidade'] = cidade;
    data['cep'] = cep;
    data['cnpj'] = cnpj;
    data['ie'] = ie;
    data['ambiente'] = ambiente?.name;

    if (aplicativo != null) data['aplicativo'] = aplicativo!.toJson();
    if (regime != null) data['regime'] = regime!.toJson();
    if (fileAttachment != null) {
      data['fileAttachment'] = fileAttachment!.toJson();
    }
    if (audit != null) data['audit'] = audit!.toJson();
    return data;
  }

  // === NOVO: Helper para exibir logo (imagem da empresa)
  Uint8List get logoBytes {
    if (fileAttachment?.fileData != null &&
        fileAttachment!.fileData!.isNotEmpty) {
      return Uint8List.fromList(fileAttachment!.fileData!);
    }
    return Uint8List(0);
  }

  Widget logoWidget({
    double size = 64,
    BoxFit fit = BoxFit.cover,
    Widget? fallback,
  }) {
    if (logoBytes.isNotEmpty) {
      return ClipOval(
        child: Image.memory(
          logoBytes,
          width: size,
          height: size,
          fit: fit,
          errorBuilder: (context, error, stack) {
            return fallback ??
                Icon(Icons.business, color: Colors.grey[600], size: size / 2);
          },
        ),
      );
    }
    return fallback ??
        Icon(Icons.business, color: Colors.grey[600], size: size / 2);
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
    const FieldConfig(
      label: "Nome",
      fieldName: "nome",
      icon: Icons.business,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Razão Social",
      fieldName: "razaoSocial",
      icon: Icons.apartment,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Email",
      fieldName: "email",
      icon: Icons.email,
      isInForm: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Telefone",
      fieldName: "telefone",
      icon: Icons.phone,
      isInForm: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Telefone Contato",
      fieldName: "telefoneContato",
      icon: Icons.phone_in_talk,
      isInForm: true,
      isVisibleByDefault: false,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Email Contato",
      fieldName: "emailContato",
      icon: Icons.contact_mail,
      isInForm: true,
      isVisibleByDefault: false,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Rua",
      fieldName: "rua",
      icon: Icons.home,
      isInForm: true,
      isVisibleByDefault: false,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Número",
      fieldName: "numero",
      icon: Icons.confirmation_number,
      isInForm: true,
      isVisibleByDefault: false,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Cidade",
      fieldName: "cidade",
      icon: Icons.location_city,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: false,
      isFixed: false,
    ),
    const FieldConfig(
      label: "CEP",
      fieldName: "cep",
      icon: Icons.local_post_office,
      isInForm: true,
      isVisibleByDefault: false,
      isFixed: false,
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
      isVisibleByDefault: true,
      isFixed: false,
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
      isVisibleByDefault: true,
      isFixed: false,
    ),
  ];
}
