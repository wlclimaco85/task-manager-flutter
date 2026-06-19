import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class Exercicio {
  int? id;
  int? codTipoExerc;
  int? codGrupMusc;
  String? nome;
  String? linkVideo;
  int? nivel;
  String? foto;
  String? linkDoc;
  String? descricao;

  Exercicio({
    this.id,
    this.codTipoExerc,
    this.codGrupMusc,
    this.nome,
    this.linkVideo,
    this.nivel,
    this.foto,
    this.linkDoc,
    this.descricao,
  });

  Exercicio.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    codTipoExerc = json['codTipoExerc'];
    codGrupMusc = json['codGrupMusc'];
    nome = json['nome'];
    linkVideo = json['linkVideo'];
    nivel = json['nivel'] is int
        ? json['nivel']
        : int.tryParse(json['nivel']?.toString() ?? '');
    foto = json['foto'];
    linkDoc = json['linkDoc'];
    descricao = json['descricao'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codTipoExerc': codTipoExerc,
      'codGrupMusc': codGrupMusc,
      'nome': nome,
      'linkVideo': linkVideo,
      'nivel': nivel,
      'foto': foto,
      'linkDoc': linkDoc,
      'descricao': descricao,
    };
  }

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(
      label: "Nome",
      fieldName: "nome",
      icon: Icons.fitness_center,
      isInForm: true,
      isFilterable: true,
    ),
    const FieldConfig(
      label: "Descrição",
      fieldName: "descricao",
      icon: Icons.description,
      isInForm: true,
    ),
    const FieldConfig(
      label: "Grupo Muscular ID",
      fieldName: "codGrupMusc",
      icon: Icons.group,
      isInForm: true,
      isFilterable: true,
    ),
    const FieldConfig(
      label: "Tipo Exercício ID",
      fieldName: "codTipoExerc",
      icon: Icons.category,
      isInForm: true,
    ),
    const FieldConfig(
      label: "Nível",
      fieldName: "nivel",
      icon: Icons.bar_chart,
      isInForm: true,
      isFilterable: true,
    ),
    const FieldConfig(
      label: "Link do Vídeo",
      fieldName: "linkVideo",
      icon: Icons.video_library,
      isInForm: true,
    ),
    const FieldConfig(
      label: "Foto (URL)",
      fieldName: "foto",
      icon: Icons.image,
      isInForm: true,
    ),
    const FieldConfig(
      label: "Link do Documento",
      fieldName: "linkDoc",
      icon: Icons.article,
      isInForm: true,
    ),
  ];
}
