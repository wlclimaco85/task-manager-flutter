import 'dart:convert';

class Produto {
  int? id;
  int? tipoProdutoId;
  int? produtoId;
  String? descricao;
  List<Foto>? listFotos;
  int? qtdSacos;
  double? vlrSacos;
  int? vendedorId;
  List<Classificacao>? classificacao;
  List<String>? fotos;
  bool? cargaFechada;
  Parceiro? parceiro;

  Produto({
    this.id,
    this.tipoProdutoId,
    this.produtoId,
    this.descricao,
    this.listFotos,
    this.qtdSacos,
    this.vlrSacos,
    this.vendedorId,
    this.classificacao,
    this.fotos,
    this.cargaFechada,
    this.parceiro,
  });

  // Método para converter de JSON para a classe Produto
  Produto.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    tipoProdutoId = json['tipoProdutoId'];
    produtoId = json['produtoId'];
    descricao = utf8.decode(latin1.encode(json['descricao']));
    qtdSacos = json['qtdSacos'];
    vlrSacos = json['vlrSacos']?.toDouble();
    vendedorId = json['vendedorId'];
    cargaFechada = json['cargaFechada'];
    parceiro = Parceiro.fromJson(json['parceiro']);
    listFotos = json['listFotos'] != null
        ? (json['listFotos'] as List)
            .map((item) => Foto.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : [];
    classificacao = json['classificacao'] != null
        ? (json['classificacao'] as List)
            .map((item) =>
                Classificacao.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : [];
    fotos = json['fotos'] != null
        ? (json['fotos'] as List).map((item) => item.toString()).toList()
        : [];
  }

  // Método para converter Produto para JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['tipoProdutoId'] = tipoProdutoId;
    data['produtoId'] = produtoId;
    data['descricao'] = descricao;
    data['qtdSacos'] = qtdSacos;
    data['vlrSacos'] = vlrSacos;
    data['vendedorId'] = vendedorId;
    data['cargaFechada'] = cargaFechada;
    if (listFotos != null) {
      data['listFotos'] = listFotos!.map((foto) => foto.toJson()).toList();
    }
    if (classificacao != null) {
      data['classificacao'] =
          classificacao!.map((item) => item.toJson()).toList();
    }
    data['fotos'] = fotos;
    return data;
  }

  // Método para converter uma lista de JSON para uma lista de objetos Produto
  static List<Produto> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => Produto.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

// Classe para "Foto"
class Foto {
  int? id;
  String? foto;
  bool? principal;

  Foto({this.id, this.foto, this.principal});

  Foto.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    foto = json['foto'];
    principal = json['principal'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['foto'] = foto;
    data['principal'] = principal;
    return data;
  }
}

// Classe para "Classificacao"
class Classificacao {
  int? id;
  String? descricao;
  double? valor;
  int? parentId;

  Classificacao({this.id, this.descricao, this.valor, this.parentId});

  Classificacao.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    descricao = json['descricao'];
    valor = json['valor']?.toDouble();
    parentId = json['parentId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['descricao'] = descricao;
    data['valor'] = valor;
    data['parentId'] = parentId;
    return data;
  }
}

class Parceiro {
  int? id;
  String? nome;
  String? cpf;
  String? codProdutor;
  Endereco? endereco;

  Parceiro({this.id, this.nome, this.cpf, this.codProdutor, this.endereco});

  Parceiro.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nome = json['nome'];
    cpf = json['cpf'];
    codProdutor = json['codProdutor'];
    endereco = Endereco.fromJson(json['endereco']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['nome'] = nome;
    data['cpf'] = cpf;
    data['codProdutor'] = codProdutor;
    data['endereco'] = endereco;

    return data;
  }
}

class Endereco {
  int? id;
  String? rua;
  String? numero;
  String? bairro;
  String? cidade;
  String? estado;
  String? cep;
  int? parceiroId;

  Endereco(
      {this.id,
      this.rua,
      this.numero,
      this.bairro,
      this.cidade,
      this.estado,
      this.cep,
      this.parceiroId});

  Endereco.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    rua = json['rua'];
    numero = json['numero'];
    bairro = json['bairro'];
    cidade = json['cidade'];
    estado = json['estado'];
    cep = json['cep'];
    parceiroId = json['parceiroId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['rua'] = rua;
    data['numero'] = numero;
    data['bairro'] = bairro;
    data['cidade'] = cidade;
    data['estado'] = estado;
    data['cep'] = cep;
    data['parceiroId'] = parceiroId;
    return data;
  }
}

// Classe principal para agrupar a lista de produtos e outros dados
class ProdutoModel {
  String? status;
  String? token;
  List<Produto>? produtos;

  ProdutoModel({this.status, this.token, this.produtos});

  ProdutoModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    token = json['token'];
    produtos = json['data'] != null
        ? Produto.fromJsonList(json['data']['account'])
        : [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;
    if (produtos != null) {
      data['data'] = produtos!.map((produto) => produto.toJson()).toList();
    }
    return data;
  }
}
