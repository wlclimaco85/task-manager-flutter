import 'dart:convert';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:flutter/material.dart';

class Comunicado {
  int? id;
  int? codApp;
  int? empId;
  String? titulo;
  String? conteudo;
  String? autor;
  String? categoria;
  DateTime? dhCreatedAt;
  DateTime? dataPublicacao; // Novo campo
  DateTime? dhUpdatedAt; // Novo campo

  Comunicado({
    this.id,
    this.codApp,
    this.empId,
    this.titulo,
    this.conteudo,
    this.autor,
    this.categoria,
    this.dhCreatedAt,
    this.dataPublicacao,
    this.dhUpdatedAt,
  });

  /* Data.fromJson(Map<String, dynamic> json) {
    id = json['comunicacaoDTO'][0]['id'];
    codApp = json['codApp'];
    link = json['link'];
    noticia = json['noticia'];
    titulo = json['titulo'];
    tituloResu = json['tituloResu'];
    tituloResu = json['fonte'];
    tituloResu = json['autor'];
    tituloResu = json['resumo'];
  } */

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'empId': empId,
      'codApp': codApp,
      'titulo': titulo,
      'conteudo': conteudo,
      'categoria': categoria,
      'dataPublicacao': dataPublicacao?.toIso8601String(),
      'autor': autor,
      'dhCreatedAt': dhCreatedAt?.toIso8601String(),
    };
  }

  // Método para converter de JSON para a classe Data
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
      categoria = json['categoria'] != null
          ? utf8.decode(latin1.encode(json['categoria']))
          : 'Fonte desconhecida';
      autor = json['autor'] != null
          ? utf8.decode(latin1.encode(json['autor']))
          : 'autor desconhecido';
      dataPublicacao = DateTime.parse(
        json['dataPublicacao'],
      ); // Converter string para DateTime
      //   dhUpdatedAt = DateTime.parse(
      //       json['audit'] ?? ['dataUpdated']); // Converter string para DateTime
    }
  }

  // Método para converter uma lista de JSON para uma lista de objetos Data
  static List<Comunicado> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => Comunicado.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // Método para converter de JSON para a classe Data
  Comunicado.fromJson2(Map<String, dynamic> json) {
    if (json['comunicacaoDTO'] != null && json['comunicacaoDTO'].isNotEmpty) {
      var comunicacaoDTO = json['comunicacaoDTO'][0];
      id = comunicacaoDTO['id'];
      codApp = comunicacaoDTO['codApp'];
      empId = comunicacaoDTO['empId'];
      titulo = comunicacaoDTO['titulo'];
      conteudo = comunicacaoDTO['conteudo'];
      autor = comunicacaoDTO['autor'];
      categoria = comunicacaoDTO['categoria'];
      dataPublicacao = comunicacaoDTO['dataPublicacao'];
      dhUpdatedAt = comunicacaoDTO['dhUpdatedAt'];
    }
  }

  // Método para converter uma lista de JSON para uma lista de objetos Data
  static List<Comunicado> fromJsonList2(List<Map<String, dynamic>> jsonList) {
    List<Comunicado> dataList = [];
    for (var json in jsonList) {
      // dataList.add(Data.fromJson(json));
    }
    return dataList;
  }

  // Configuração dos campos para a grid
  static const List<FieldConfig> fieldConfigs = [
    FieldConfig(
      label: "Título",
      fieldName: "titulo",
      icon: Icons.title,
      isFilterable: true,
      isInForm: true,
    ),
    FieldConfig(
      label: "Conteúdo",
      fieldName: "conteudo",
      icon: Icons.description,
      isFilterable: true,
      isInForm: true,
      maxLines: 3,
    ),
    FieldConfig(
      label: "Categoria",
      fieldName: "categoria",
      icon: Icons.category,
      isFilterable: true,
      isInForm: true,
    ),
    FieldConfig(
      label: "Autor",
      fieldName: "autor",
      icon: Icons.person,
      isFilterable: true,
      isInForm: true,
    ),
  ];
}
