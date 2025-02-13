// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';

class LocalizacaoWidget extends StatefulWidget {
  final Function(Pais?, Estado?, Cidade?) onSaved;
  final bool required;

  const LocalizacaoWidget({
    Key? key,
    required this.onSaved,
    this.required = false,
  }) : super(key: key);

  @override
  _LocalizacaoWidgetState createState() => _LocalizacaoWidgetState();
}

class _LocalizacaoWidgetState extends State<LocalizacaoWidget> {
  Pais? selectedPais;
  Estado? selectedEstado;
  Cidade? selectedCidade;

  List<Pais> paises = [];
  List<Estado> estados = [];
  List<Cidade> cidades = [];

  @override
  void initState() {
    super.initState();
    fetchPaises();
    fetchEstados('1');
  }

  Future<void> fetchPaises() async {
    //  final NetworkResponse response =
    //     await NetworkCaller().getRequest(ApiLinks.fecthAllPaises);
    // if (response.statusCode == 200 && response.body != null) {
    setState(() {
      paises.add(Pais(
          id: 1,
          nome: "Brasil",
          nomePt: "Brasil",
          iso2: "BR",
          iso3: "BRA",
          bacen: 1058));
    });
    // }
  }

  Future<void> fetchEstados(String? paisId) async {
    if (paisId == null) return;

    final NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.fecthEstadoByPais + paisId);
    EstadoModel model;
    if (response.statusCode == 200 && response.body != null) {
      setState(() {
        model = EstadoModel.fromJson(response.body!);
        estados.addAll(model.estados ?? []);
        selectedEstado = null;
        selectedCidade = null;
      });
    }
  }

  Future<void> fetchCidades(String? estadoId) async {
    if (estadoId == null) return;

    final NetworkResponse response = await NetworkCaller()
        .getRequest(ApiLinks.fecthCidadeByEstado + estadoId);
    CidadeModel model;
    if (response.statusCode == 200) {
      setState(() {
        model = CidadeModel.fromJson(response.body!);
        cidades.addAll(model.estados ?? []);
        selectedCidade = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<Pais>(
          decoration: const InputDecoration(
            labelText: 'País',
            border: OutlineInputBorder(),
          ),
          value: selectedPais,
          items: paises
              .map((pais) => DropdownMenuItem<Pais>(
                    value: pais,
                    child: Text(pais.nomePt),
                  ))
              .toList(),
          onChanged: (Pais? newValue) {
            setState(() {
              selectedPais = newValue;
              estados = [];
              cidades = [];
              selectedEstado = null;
              selectedCidade = null;
            });
            if (newValue != null) {
              fetchEstados(newValue.id.toString());
            }
          },
          validator: (value) =>
              widget.required && value == null ? 'Selecione um país' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Estado>(
          decoration: const InputDecoration(
            labelText: 'Estado',
            border: OutlineInputBorder(),
          ),
          value: selectedEstado,
          items: estados
              .map((estado) => DropdownMenuItem<Estado>(
                    value: estado,
                    child: Text('${estado.nome} (${estado.uf})'),
                  ))
              .toList(),
          onChanged: (Estado? newValue) {
            setState(() {
              selectedEstado = newValue;
              cidades = [];
              selectedCidade = null;
            });
            if (newValue != null) {
              fetchCidades(newValue.id.toString());
            }
          },
          validator: (value) =>
              widget.required && value == null ? 'Selecione um estado' : null,
        ),
        SizedBox(height: 16),
        DropdownButtonFormField<Cidade>(
          decoration: const InputDecoration(
            labelText: 'Cidade',
            border: OutlineInputBorder(),
          ),
          value: selectedCidade,
          items: cidades
              .map((cidade) => DropdownMenuItem<Cidade>(
                    value: cidade,
                    child: Text(cidade.nome),
                  ))
              .toList(),
          onChanged: (Cidade? newValue) {
            setState(() {
              selectedCidade = newValue;
            });
          },
          validator: (value) =>
              widget.required && value == null ? 'Selecione uma cidade' : null,
        ),
      ],
    );
  }
}

class PaisModel {
  String? status;
  String? token;
  List<Pais>? pais;

  PaisModel({this.status, this.token, this.pais});

  PaisModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    token = json['token'];
    pais =
        json['data'] != null ? Pais.fromJsonList(json['data']['account']) : [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;
    if (pais != null) {
      data['data'] = pais!.map((produto) => produto.toJson()).toList();
    }
    return data;
  }
}

class EstadoModel {
  String? status;
  String? token;
  List<Estado>? estados;

  EstadoModel({this.status, this.token, this.estados});

  EstadoModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    token = json['token'];
    estados = json['data'] != null
        ? Estado.fromJsonList(json['data']['account'])
        : [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;
    if (estados != null) {
      data['data'] = estados!.map((produto) => produto.toJson()).toList();
    }
    return data;
  }
}

class CidadeModel {
  String? status;
  String? token;
  List<Cidade>? estados;

  CidadeModel({this.status, this.token, this.estados});

  CidadeModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    token = json['token'];
    estados = json['data'] != null
        ? Cidade.fromJsonList(json['data']['account'])
        : [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;
    if (estados != null) {
      data['data'] = estados!.map((produto) => produto.toJson()).toList();
    }
    return data;
  }
}

// Model classes
class Pais {
  final int id;
  final String nome;
  final String nomePt;
  final String iso2;
  final String iso3;
  final int bacen;

  Pais({
    required this.id,
    required this.nome,
    required this.nomePt,
    required this.iso2,
    required this.iso3,
    required this.bacen,
  });

  factory Pais.fromJson(Map<String, dynamic> json) {
    return Pais(
      id: json['id'],
      nome: utf8.decode(latin1.encode(json['nome'])),
      nomePt: json['nomePt'],
      iso2: json['iso2'],
      iso3: json['iso3'] ?? '',
      bacen: json['bacen'],
    );
  }

  // Método para serializar o objeto Parceiro em JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['nome'] = nome;
    data['nomePt'] = nomePt;
    data['iso2'] = iso2;
    data['iso3'] = iso3;
    data['bacen'] = bacen;
    return data;
  }

  static List<Pais> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => Pais.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class Estado {
  final int id;
  final String nome;
  final String uf;
  final int ibge;
  final Pais pais;

  Estado({
    required this.id,
    required this.nome,
    required this.uf,
    required this.ibge,
    required this.pais,
  });

  factory Estado.fromJson(Map<String, dynamic> json) {
    return Estado(
      id: json['id'],
      nome: utf8.decode(latin1.encode(json['nome'])),
      uf: json['uf'],
      ibge: json['ibge'],
      pais: (json['pais'] != null && json['pais'] is Map<String, dynamic>)
          ? Pais.fromJson(json['pais'] as Map<String, dynamic>)
          : Pais(
              id: 0,
              nome: 'Brasil',
              nomePt: 'Brasil',
              iso2: 'BR',
              iso3: 'BRA',
              bacen: 1058), // Criar um objeto padrão
    );
  }
  // Método para serializar o objeto Parceiro em JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['nome'] = nome;
    data['uf'] = uf;
    data['ibge'] = ibge;
    data['pais'] = pais;
    return data;
  }

  static List<Estado> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => Estado.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class Cidade {
  final int id;
  final String nome;
  // final int uf;
  final int ibge;
  final String latLon;

  Cidade({
    required this.id,
    required this.nome,
    //  required this.uf,
    required this.ibge,
    required this.latLon,
  });

  factory Cidade.fromJson(Map<String, dynamic> json) {
    return Cidade(
      id: json['id'],
      nome: utf8.decode(latin1.encode(json['nome'])),
      //   uf: json['uf'],
      ibge: json['ibge'],
      latLon: json['latLon'] ?? '',
    );
  }

  // Método para serializar o objeto Parceiro em JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['nome'] = nome;
    // data['uf'] = uf;
    data['ibge'] = ibge;
    data['latLon'] = latLon;
    return data;
  }

  static List<Cidade> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => Cidade.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
