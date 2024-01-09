class LoginModel {
  String? status;
  String? token;
  Data? data;

  LoginModel({this.status, this.token, this.data});

  LoginModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    token = json['token'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? email;
  String? firstName;
  String? lastName;
  String? mobile;
  String? photo;
  DadosPessoal? codDadosPessoal;

  Data(
      {this.email,
      this.firstName,
      this.lastName,
      this.mobile,
      this.photo,
      this.codDadosPessoal});

  Data.fromJson(Map<String, dynamic> json) {
    email = json['email'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    mobile = json['mobile'];
    photo = json['photo'];
    codDadosPessoal = json['codDadosPessoal'] != null
        ? DadosPessoal.fromJson(json['codDadosPessoal'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['email'] = email;
    data['firstName'] = firstName;
    data['lastName'] = lastName;
    data['mobile'] = mobile;
    data['photo'] = photo;
    data['codDadosPessoal'].id = codDadosPessoal?.id;
    data['codDadosPessoal'].nome = codDadosPessoal?.nome;
    data['codDadosPessoal'].cpf = codDadosPessoal?.cpf;
    data['codDadosPessoal'].telefone1 = codDadosPessoal?.telefone1;
    data['codDadosPessoal'].telefone2 = codDadosPessoal?.telefone2;
    data['codDadosPessoal'].logradouro = codDadosPessoal?.logradouro;
    data['codDadosPessoal'].numero = codDadosPessoal?.numero;
    data['codDadosPessoal'].cep = codDadosPessoal?.cep;
    data['codDadosPessoal'].bairro = codDadosPessoal?.bairro;
    data['codDadosPessoal'].cidade = codDadosPessoal?.cidade;
    data['codDadosPessoal'].estado = codDadosPessoal?.estado;
    data['codDadosPessoal'].pais = codDadosPessoal?.pais;
    data['codDadosPessoal'].email = codDadosPessoal?.email;
    data['codDadosPessoal'].fistName = codDadosPessoal?.fistName;
    data['codDadosPessoal'].lastName = codDadosPessoal?.lastName;
    data['codDadosPessoal'].photo = codDadosPessoal?.photo;
    data['codDadosPessoal'].tipoAluno = codDadosPessoal?.tipoAluno;
    data['codDadosPessoal'].parentId = codDadosPessoal?.parentId;
    data['codDadosPessoal'].academia = codDadosPessoal?.academia;

    return data;
  }
}

class DadosPessoal {
  int? id;
  String? nome;
  String? cpf;
  String? telefone1;
  String? telefone2;
  String? logradouro;
  String? numero;
  String? cep;
  String? bairro;
  String? cidade;
  String? estado;
  String? pais;
  String? email;
  String? fistName;
  String? lastName;
  String? photo;
  String? tipoAluno;
  int? parentId;
  String? academia;

  DadosPessoal(
      {this.id,
      this.nome,
      this.cpf,
      this.telefone1,
      this.telefone2,
      this.logradouro,
      this.numero,
      this.cep,
      this.bairro,
      this.cidade,
      this.estado,
      this.pais,
      this.email,
      this.fistName,
      this.lastName,
      this.photo,
      this.tipoAluno,
      this.parentId,
      this.academia});

  DadosPessoal.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nome = json['nome'];
    cpf = json['cpf'];
    telefone1 = json['telefone1'];
    telefone2 = json['telefone2'];
    logradouro = json['logradouro'];
    numero = json['numero'];
    cep = json['cep'];
    bairro = json['bairro'];
    cidade = json['cidade'];
    estado = json['estado'];
    pais = json['pais'];
    email = json['email'];
    fistName = json['fistName'];
    lastName = json['lastName'];
    photo = json['photo'];
    tipoAluno = json['tipoAluno'];
    parentId = json['parentId'];
    academia = json['academia'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> codDadosPessoal = <String, dynamic>{};
    codDadosPessoal['id'] = id;
    codDadosPessoal['nome'] = nome;
    codDadosPessoal['cpf'] = cpf;
    codDadosPessoal['telefone1'] = telefone1;
    codDadosPessoal['telefone2'] = telefone2;
    codDadosPessoal['logradouro'] = logradouro;
    codDadosPessoal['numero'] = numero;
    codDadosPessoal['cep'] = cep;
    codDadosPessoal['bairro'] = bairro;
    codDadosPessoal['cidade'] = cidade;
    codDadosPessoal['estado'] = estado;
    codDadosPessoal['pais'] = pais;
    codDadosPessoal['email'] = email;
    codDadosPessoal['fistName'] = fistName;
    codDadosPessoal['lastName'] = lastName;
    codDadosPessoal['photo'] = photo;
    codDadosPessoal['tipoAluno'] = tipoAluno;
    codDadosPessoal['parentId'] = parentId;
    codDadosPessoal['academia'] = academia;
    return codDadosPessoal;
  }
}
