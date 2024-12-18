// Classe Endereco
class Endereco {
  int? id;
  String? rua;
  String? numero;
  String? bairro;
  String? cidade;
  String? estado;
  String? cep;
  int? parceiroId;

  Endereco({
    this.id,
    this.rua,
    this.numero,
    this.bairro,
    this.cidade,
    this.estado,
    this.cep,
    this.parceiroId,
  });

  // Método para deserializar o JSON em um objeto Endereco
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

  // Método para serializar o objeto Endereco em JSON
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

class ParceiroModel {
  String? status;
  String? token;
  List<Parceiro>? parceiros;

  ParceiroModel({this.status, this.token, this.parceiros});

  ParceiroModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    token = json['token'];
    parceiros = json['data'] != null
        ? Parceiro.fromJsonList(json['data']['account'])
        : [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;
    if (parceiros != null) {
      data['data'] = parceiros!.map((produto) => produto.toJson()).toList();
    }
    return data;
  }
}

// Classe Parceiro
class Parceiro {
  int? id;
  String? nome;
  String? cpf;
  String? codProdutor;
  String? email;
  String? telefone1;
  String? telefone2;
  String? razaoSocial;
  String? incrMun;
  String? status;
  Endereco? endereco;

  Parceiro({
    this.id,
    this.nome,
    this.cpf,
    this.codProdutor,
    this.email,
    this.telefone1,
    this.telefone2,
    this.razaoSocial,
    this.incrMun,
    this.status,
    this.endereco,
  });

  // Método para deserializar o JSON em um objeto Parceiro
  Parceiro.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nome = json['nome'];
    cpf = json['cpf'];
    codProdutor = json['codProdutor'];
    email = json['email'];
    telefone1 = json['telefone1'];
    telefone2 = json['telefone2'];
    razaoSocial = json['razaoSocial'];
    incrMun = json['incrMun'];
    status = json['status'];
    endereco =
        json['endereco'] != null ? Endereco.fromJson(json['endereco']) : null;
  }

  // Método para serializar o objeto Parceiro em JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['nome'] = nome;
    data['cpf'] = cpf;
    data['codProdutor'] = codProdutor;
    data['email'] = email;
    data['telefone1'] = telefone1;
    data['telefone2'] = telefone2;
    data['razaoSocial'] = razaoSocial;
    data['incrMun'] = incrMun;
    data['status'] = status;
    if (endereco != null) {
      data['endereco'] = endereco!.toJson();
    }
    return data;
  }

  static List<Parceiro> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => Parceiro.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
