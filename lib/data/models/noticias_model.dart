import 'dart:convert';

class Data {
  int? id;
  int? codApp;
  String? link;
  String? noticia;
  String? titulo;
  String? tituloResu;
  String? fonte;
  String? autor;
  String? resumo;
  DateTime? dtImport; // Novo campo
  DateTime? dtNoticia; // Novo campo

  Data(
      {this.id,
      this.codApp,
      this.link,
      this.noticia,
      this.titulo,
      this.tituloResu,
      this.fonte,
      this.autor,
      this.resumo,
      this.dtImport,
      this.dtNoticia});

  /* Data.fromJson(Map<String, dynamic> json) {
    id = json['noticiasDTO'][0]['id'];
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['noticiasDTO']['id'] = id;
    data['noticiasDTO']['codApp'] = codApp;
    data['noticiasDTO']['link'] = link;
    data['noticiasDTO']['noticia'] = noticia;
    data['noticiasDTO']['titulo'] = titulo;
    data['noticiasDTO']['tituloResu'] = tituloResu;
    data['noticiasDTO']['fonte'] = fonte;
    data['noticiasDTO']['autor'] = autor;
    data['noticiasDTO']['resumo'] = resumo;
    data['noticiasDTO']['dtImport'] =
        dtImport?.toIso8601String(); // Converter DateTime para string
    data['noticiasDTO']['dtNoticia'] =
        dtNoticia?.toIso8601String(); // Converter DateTime para string

    return data;
  }

  // Método para converter de JSON para a classe Data
  Data.fromJson(Map<String, dynamic> json) {
    if (json.isNotEmpty) {
      id = json['id'];
      codApp = json['codApp'];
      link = json['link'];
      noticia = utf8.decode(latin1.encode(json['noticia']));
      titulo = utf8.decode(latin1.encode(json['titulo']));
      tituloResu = utf8.decode(latin1.encode(json['tituloResu']));
      fonte = utf8.decode(latin1.encode(json['fonte']));
      autor = json['autor'];
      resumo = utf8.decode(latin1.encode(json['resumo']));
      dtImport =
          DateTime.parse(json['dtImport']); // Converter string para DateTime
      dtNoticia =
          DateTime.parse(json['dtNoticia']); // Converter string para DateTime
    }
  }

  // Método para converter uma lista de JSON para uma lista de objetos Data
  static List<Data> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => Data.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // Método para converter de JSON para a classe Data
  Data.fromJson2(Map<String, dynamic> json) {
    if (json['noticiasDTO'] != null && json['noticiasDTO'].isNotEmpty) {
      var noticiasDTO = json['noticiasDTO'][0];
      id = noticiasDTO['id'];
      codApp = noticiasDTO['codApp'];
      link = noticiasDTO['link'];
      noticia = noticiasDTO['noticia'];
      titulo = noticiasDTO['titulo'];
      tituloResu = noticiasDTO['tituloResu'];
      fonte = noticiasDTO['fonte'];
      autor = noticiasDTO['autor'];
      resumo = noticiasDTO['resumo'];
    }
  }

  // Método para converter uma lista de JSON para uma lista de objetos Data
  static List<Data> fromJsonList2(List<Map<String, dynamic>> jsonList) {
    List<Data> dataList = [];
    for (var json in jsonList) {
      // dataList.add(Data.fromJson(json));
    }
    return dataList;
  }

  // Método para converter uma lista de mapas para uma lista de objetos Data
  // static List<Data> fromJsonList(List<Map<String, dynamic>> jsonList) {
  //   return jsonList.map((json) => Data.fromJson(json)).toList();
  // }
}
