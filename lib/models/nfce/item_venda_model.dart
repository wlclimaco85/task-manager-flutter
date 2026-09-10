class ItemVendaModel {
  final int produtoId;
  final String nomeProduto;
  final String? codigoProduto;
  final double precoUnitario;
  int quantidade;
  double desconto;

  ItemVendaModel({
    required this.produtoId,
    required this.nomeProduto,
    this.codigoProduto,
    required this.precoUnitario,
    this.quantidade = 1,
    this.desconto = 0,
  });

  double get subtotal => (precoUnitario * quantidade) - desconto;

  Map<String, dynamic> toJson() => {
        'produtoId': produtoId,
        'quantidade': quantidade,
        'precoUnitario': precoUnitario,
        'desconto': desconto,
      };
}

class PagamentoModel {
  final String formaPagamento; // DINHEIRO, CARTAO_CREDITO, CARTAO_DEBITO, PIX, OUTRO
  double valor;

  PagamentoModel({required this.formaPagamento, required this.valor});

  Map<String, dynamic> toJson() => {
        'formaPagamento': formaPagamento,
        'valor': valor,
      };
}
