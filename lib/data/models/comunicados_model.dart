import 'dart:convert';

class Data {
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

  Data(
      {this.id,
      this.codApp,
      this.empId,
      this.titulo,
      this.conteudo,
      this.autor,
      this.categoria,
      this.dhCreatedAt,
      this.dataPublicacao,
      this.dhUpdatedAt});

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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['comunicacaoDTO']['id'] = id;
    data['comunicacaoDTO']['empId'] = empId;
    data['comunicacaoDTO']['codApp'] = codApp;
    data['comunicacaoDTO']['titulo'] = titulo;
    data['comunicacaoDTO']['conteudo'] = conteudo;
    data['comunicacaoDTO']['autor'] = autor;
    data['comunicacaoDTO']['categoria'] = categoria;
    data['comunicacaoDTO']['dataPublicacao'] =
        dataPublicacao?.toIso8601String(); // Converter DateTime para string
    data['comunicacaoDTO']['dhUpdatedAt'] =
        dhUpdatedAt?.toIso8601String(); // Converter DateTime para string

    return data;
  }

  // Método para converter de JSON para a classe Data
  Data.fromJson(Map<String, dynamic> json) {
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
          json['dataPublicacao']); // Converter string para DateTime
      //   dhUpdatedAt = DateTime.parse(
      //       json['audit'] ?? ['dataUpdated']); // Converter string para DateTime
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
