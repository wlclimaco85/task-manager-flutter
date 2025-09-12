import 'dart:convert';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';

class Setor {
  int? id;
  String? descricao;
  String? responsavel;
  String? ramal;

  Setor({this.id, this.descricao, this.responsavel, this.ramal});

  factory Setor.fromJson(Map<String, dynamic> json) {
    return Setor(
      id: json['id'],
      descricao: json['descricao'],
      responsavel: json['responsavel'],
      ramal: json['ramal'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descricao': descricao,
      'responsavel': responsavel,
      'ramal': ramal,
    };
  }

  @override
  String toString() => descricao ?? '';
}

class Comunicado {
  int? id;
  int? codApp;
  int? empId;
  String? titulo;
  String? conteudo;
  String? autor;
  Setor? setor;
  DateTime? dhCreatedAt;
  DateTime? dataPublicacao;
  DateTime? dhUpdatedAt;

  Comunicado({
    this.id,
    this.codApp,
    this.empId,
    this.titulo,
    this.conteudo,
    this.autor,
    this.setor,
    this.dhCreatedAt,
    this.dataPublicacao,
    this.dhUpdatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'empId': empId,
      'codApp': codApp,
      'titulo': titulo,
      'conteudo': conteudo,
      'setor': setor?.toJson(),
      'dataPublicacao': dataPublicacao?.toIso8601String(),
      'autor': autor,
      'dhCreatedAt': dhCreatedAt?.toIso8601String(),
    };
  }

  Comunicado.fromJson(Map<String, dynamic> json) {
    if (json.isNotEmpty) {
      id = json['id'];
      empId = json['empId'];
      codApp = json['codApp'];
      conteudo = json['conteudo'] != null
          ? utf8.decode(latin1.encode(json['conteudo']))
          : 'conteudo não disponível';
      titulo = json['titulo'] != null
          ? utf8.decode(latin1.encode(json['titulo']))
          : 'Título não disponível';
      autor = json['autor'] != null
          ? utf8.decode(latin1.encode(json['autor']))
          : 'autor não disponível';
      setor = json['setor'] != null ? Setor.fromJson(json['setor']) : null;
      autor = json['autor'] != null
          ? utf8.decode(latin1.encode(json['autor']))
          : 'autor desconhecido';
      dataPublicacao = DateTime.parse(json['dataPublicacao']);
    }
  }

  static List<Comunicado> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => Comunicado.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Comunicado.fromJson2(Map<String, dynamic> json) {
    if (json['comunicacaoDTO'] != null && json['comunicacaoDTO'].isNotEmpty) {
      var comunicacaoDTO = json['comunicacaoDTO'][0];
      id = comunicacaoDTO['id'];
      codApp = comunicacaoDTO['codApp'];
      empId = comunicacaoDTO['empId'];
      titulo = comunicacaoDTO['titulo'];
      conteudo = comunicacaoDTO['conteudo'];
      autor = comunicacaoDTO['autor'];
      setor = comunicacaoDTO['setor'] != null
          ? Setor.fromJson(comunicacaoDTO['setor'])
          : null;
      dataPublicacao = comunicacaoDTO['dataPublicacao'];
      dhUpdatedAt = comunicacaoDTO['dhUpdatedAt'];
    }
  }

  static List<Comunicado> fromJsonList2(List<Map<String, dynamic>> jsonList) {
    List<Comunicado> dataList = [];
    for (var json in jsonList) {}
    return dataList;
  }

  static Future<List<Map<String, dynamic>>> loadCategorias() async {
    final NetworkResponse response = await NetworkCaller().getRequest(
      ApiLinks.getCategorias,
    );

    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data'];
      return data
          .map(
            (item) => {
              'value': item['id'].toString(),
              'label': item['descricao'],
            },
          )
          .toList();
    }
    return [];
  }

  static List<FieldConfig> fieldConfigs = [
    FieldConfig(
      label: "Título",
      fieldName: "titulo",
      icon: Icons.title,
      isFilterable: true,
      isInForm: true,
      isRequired: true,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Título é obrigatório';
        if (value.length < 3) return 'Título deve ter pelo menos 3 caracteres';
        return null;
      },
    ),
    FieldConfig(
      label: "Conteúdo",
      fieldName: "conteudo",
      icon: Icons.description,
      isFilterable: true,
      isInForm: true,
      maxLines: 3,
      fieldType: FieldType.multiline,
      isRequired: true,
    ),
    FieldConfig(
      label: "Categoria",
      fieldName: "setor",
      icon: Icons.category,
      isFilterable: true,
      isInForm: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: Comunicado.loadCategorias,
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      isRequired: true,
    ),
    FieldConfig(
      label: "Autor",
      fieldName: "autor",
      icon: Icons.person,
      isFilterable: true,
      isInForm: true,
      isRequired: true,
    ),
  ];
}
