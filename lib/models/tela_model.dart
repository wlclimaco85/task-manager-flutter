/// Modelo simples para representar uma Tela retornada por /api/telas
class Tela {
  final int id;
  final String nome;
  final String descricao;

  Tela({
    required this.id,
    required this.nome,
    required this.descricao,
  });

  factory Tela.fromJson(Map<String, dynamic> json) {
    return Tela(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      nome: json['nome']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? json['titulo']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'descricao': descricao,
  };

  @override
  String toString() => 'Tela(id: $id, nome: $nome, descricao: $descricao)';
}
