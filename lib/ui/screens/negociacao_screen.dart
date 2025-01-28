import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/services/vendas_caller.dart';
import 'package:task_manager_flutter/data/utils/fotos_util.dart';
import 'package:task_manager_flutter/ui/screens/update_profile.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';

// Define theme colors
const Color lightGreenBackground = Color.fromARGB(255, 231, 247, 233);
const Color darkGreenBorder = Color.fromARGB(255, 1, 247, 14);
const Color buttonBackground = Color.fromARGB(255, 128, 202, 132);

class NegociacaoCatalogPage extends StatefulWidget {
  final String title;
  final String apiUrl;
  final IconData actionIcon;
  final String actionTooltip;

  const NegociacaoCatalogPage({
    Key? key,
    required this.title,
    required this.apiUrl,
    required this.actionIcon,
    required this.actionTooltip,
  }) : super(key: key);

  @override
  _NegociacaoCatalogPageState createState() => _NegociacaoCatalogPageState();
}

class _NegociacaoCatalogPageState extends State<NegociacaoCatalogPage> {
  List<dynamic> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
    });
    try {
      final data = await VendasCaller().fetchItensANegocias(context);
      setState(() {
        products = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar produtos: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UserBannerAppBar(
          screenTitle: "Vendas",
          onRefresh: fetchProducts,
          isLoading: isLoading,
          onTapped: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const UpdateProfileScreen()));
          }),
      body: Container(
        color: lightGreenBackground,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : products.isEmpty
                ? const Center(child: Text('Nenhum produto encontrado'))
                : ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        actionIcon: widget.actionIcon,
                        actionTooltip: widget.actionTooltip,
                        onAction: () => showActionPopup(context, product),
                      );
                    },
                  ),
      ),
    );
  }

  void showActionPopup(BuildContext context, dynamic product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: lightGreenBackground,
        title: Text(
          product.descricao ?? 'Sem descrição',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: ${product.tipo ?? 'Não especificado'}'),
            Text('Quantidade de sacos: ${product.qtdSacos ?? 0}'),
            Text('Valor por saco: R\$${product.vlrSacos ?? 0.0}'),
            Text(
                'Data de retirada: ${product.dtRetirada ?? 'Não especificado'}'),
            const SizedBox(height: 8),
            const Text('Negociações:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...List.generate((product.negociacoes as List).length, (i) {
              final negotiation = product.negociacoes[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Comprador ID: ${negotiation.compradorId}'),
                  Text('Quantidade: ${negotiation.qtdSacos}'),
                  Text('Valor por saco: R\$${negotiation.vlrSacos}'),
                  Text('Status: ${negotiation.status}'),
                  const SizedBox(height: 8),
                ],
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ação realizada com sucesso')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: darkGreenBorder, width: 2),
              ),
            ),
            child: const Text('Confirmar Ação'),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final dynamic product;
  final IconData actionIcon;
  final String actionTooltip;
  final VoidCallback onAction;

  const ProductCard({
    Key? key,
    required this.product,
    required this.actionIcon,
    required this.actionTooltip,
    required this.onAction,
  }) : super(key: key);

  Future<void> fetchProducts(BuildContext context) async {
    try {
      final data = await VendasCaller().fetchItensANegocias(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar produtos: $e')),
      );
    } finally {}
  }

  Future<Map<String, dynamic>?> finalizarNegociacao(
    BuildContext context,
    int vendaId,
    int quantidade,
    double vlrSaco,
    String lote,
    Function onLoad,
  ) async {
    try {
      // Chamada para a API com tratamento de erros mais detalhado
      final response =
          await VendasCaller().confirmarNegociacao(context, vendaId);

      // Verificar se a resposta é válida e se a negociação foi concluída com sucesso
      if (response != null) {
        // Mostrar Snackbar de sucesso e fechar o diálogo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Negociação aceita com sucesso!'),
          ),
        );

        // Fechar o diálogo
        Navigator.pop(context);
      } else {
        // Mostrar Snackbar de erro com mensagem mais específica
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao finalizar negociação ??'),
          ),
        );
      }
    } catch (e) {
      // Tratar outras exceções que possam ocorrer
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: $e')),
      );
    } finally {
      // Chamar a função onLoad para atualizar a interface, se necessário
      onLoad(context);
    }
  }

  Future<Map<String, dynamic>?> recusarNegociacao(
    BuildContext context,
    int vendaId,
    int quantidade,
    double vlrSaco,
    String lote,
    Function onLoad,
  ) async {
    try {
      // Chamada para a API com tratamento de erros mais detalhado
      final response = await VendasCaller().confirmarRecusar(context, vendaId);

      // Verificar se a resposta é válida e se a negociação foi concluída com sucesso
      if (response != null) {
        // Mostrar Snackbar de sucesso e fechar o diálogo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sua Negociação foi recusada!'),
          ),
        );

        // Fechar o diálogo
        Navigator.pop(context);
      } else {
        // Mostrar Snackbar de erro com mensagem mais específica
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao recusar negociação ??'),
          ),
        );
      }
    } catch (e) {
      // Tratar outras exceções que possam ocorrer
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: $e')),
      );
    } finally {
      // Chamar a função onLoad para atualizar a interface, se necessário
      onLoad(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageBase64 = product.foto != null
        ? decodeBase64Image(product.foto)
        : decodeBase64Image(getImagepadrao());

    // final imageBase64 = decodeBase64Image(getImagepadrao());
    final Widget image = imageBase64.isNotEmpty
        ? Image.memory(
            imageBase64,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          )
        : const Icon(Icons.image, size: 100);

    return Card(
      margin: const EdgeInsets.all(10),
      color: lightGreenBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: darkGreenBorder, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(flex: 2, child: image),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.tipo ?? 'Sem descrição',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Lote: ${product.id}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Quantidade: ${product.qtdSacos} sacos'),
                      Text('Data Retirada: ${product.dtRetirada}'),
                      Text('Descrição: ${product.descricao}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Negociações:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...List.generate((product.negociacoes as List).length, (i) {
              final negotiation = product.negociacoes[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                color: const Color.fromARGB(255, 214, 239, 222),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: BorderSide(color: darkGreenBorder, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Comprador ID
                      SizedBox(
                        width: double.infinity, // Garante que a borda seja fixa
                        child: Text(
                          'Comprador ID: ${negotiation.compradorId}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      // Quantidade
                      SizedBox(
                        width: double.infinity, // Garante que a borda seja fixa
                        child: Text(
                          'Quantidade: ${negotiation.qtdSacos}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      // Valor por saco
                      SizedBox(
                        width: double.infinity, // Garante que a borda seja fixa
                        child: Text(
                          'Valor por saco: R\$${negotiation.vlrSacos}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      // Status
                      SizedBox(
                        width: double.infinity, // Garante que a borda seja fixa
                        child: Text(
                          'Status: ${getStatusText(negotiation.status)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (negotiation.tipo == 'P' ||
                          negotiation.tipo == 'C') ...[
                        // Botões para Proposta ou Contra Proposta
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check,
                                      color: Colors.green),
                                  tooltip: 'Aceitar',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          backgroundColor: const Color.fromARGB(
                                              255,
                                              231,
                                              247,
                                              233), // Verde claro
                                          title: const Text(
                                              'Confirmar Negociação'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const Text(
                                                      'Quantidade:',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Text(
                                                        '${negotiation.qtdSacos} sacos'),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const Text(
                                                      'Valor:',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Text(
                                                        'R\$ ${negotiation.vlrSacos!.toString()}'),
                                                  ], //'valor: ${negotiation.vlrSacos}''quantidade : ${negotiation.qtdSacos}'
                                                ),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors
                                                    .red, // Botão Cancelar em vermelho
                                              ),
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Cancelar'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color.fromARGB(255, 1,
                                                        95, 15), // Verde escuro
                                              ),
                                              onPressed: () async {
                                                final response =
                                                    await finalizarNegociacao(
                                                        context,
                                                        negotiation.id!,
                                                        negotiation.qtdSacos!,
                                                        negotiation.vlrSacos!,
                                                        negotiation.id!
                                                            .toString(),
                                                        fetchProducts);

                                                if (response != null &&
                                                    response['status'] == 'A') {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Negociação aceita com sucesso!'),
                                                    ),
                                                  );
                                                  Navigator.pop(context);
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Erro ao finalizar negociação.'),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: const Text('Confirmar'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                                const Text(
                                  'Aceitar',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black),
                                ),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.red),
                                  tooltip: 'Recusar',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          backgroundColor: const Color.fromARGB(
                                              255,
                                              231,
                                              247,
                                              233), // Verde claro
                                          title: const Text(
                                              'Confirmar Negociação'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const Text(
                                                      'Quantidade:',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Text(
                                                        '${negotiation.qtdSacos} sacos'),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const Text(
                                                      'Valor:',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Text(
                                                        'R\$ ${negotiation.vlrSacos!.toString()}'),
                                                  ], //'valor: ${negotiation.vlrSacos}''quantidade : ${negotiation.qtdSacos}'
                                                ),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors
                                                    .red, // Botão Cancelar em vermelho
                                              ),
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Cancelar'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color.fromARGB(255, 1,
                                                        95, 15), // Verde escuro
                                              ),
                                              onPressed: () async {
                                                final response =
                                                    await recusarNegociacao(
                                                        context,
                                                        negotiation.id!,
                                                        negotiation.qtdSacos!,
                                                        negotiation.vlrSacos!,
                                                        negotiation.id!
                                                            .toString(),
                                                        fetchProducts);

                                                if (response != null &&
                                                    response['status'] == 'A') {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Negociação aceita com sucesso!'),
                                                    ),
                                                  );
                                                  Navigator.pop(context);
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Erro ao finalizar negociação.'),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: const Text('Confirmar'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                                const Text(
                                  'Recusar',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black),
                                ),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.handshake,
                                      color: Colors.green),
                                  tooltip: 'Fazer Contra Proposta',
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Contraproposta enviada'),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            )
                          ],
                        ),
                      ] else if (negotiation.tipo == 'A') ...[
                        // Botões para Aceita
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                await handleSignContract(context, negotiation);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 1, 95, 15),
                              ),
                              child: const Text('Assinar Contrato'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await handleWithdraw(context, negotiation);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Desistir'),
                            ),
                          ],
                        )
                      ] else if (negotiation.tipo == 'X') ...[
                        // Nenhum botão para Recusada
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

// Função para mapear status para texto
  String getStatusText(String status) {
    switch (status) {
      case 'A':
        return 'Aguardando';
      case 'F':
        return 'Finalizado';
      case 'P':
        return 'Pendente';
      default:
        return 'Desconhecido';
    }
  }

  Future<void> handleAccept(BuildContext context, dynamic negotiation) async {
    final response = await finalizarNegociacao(
      context,
      negotiation.id!,
      negotiation.qtdSacos!,
      negotiation.vlrSacos!,
      negotiation.id!.toString(),
      fetchProducts,
    );
    if (response != null && response['status'] == 'A') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Negociação aceita com sucesso!')),
      );
    }
  }

  Future<void> handleReject(BuildContext context, dynamic negotiation) async {
    final response = await recusarNegociacao(
      context,
      negotiation.id!,
      negotiation.qtdSacos!,
      negotiation.vlrSacos!,
      negotiation.id!.toString(),
      fetchProducts,
    );
    if (response != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Negociação recusada com sucesso!')),
      );
    }
  }

  Future<void> handleSignContract(
      BuildContext context, dynamic negotiation) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contrato assinado com sucesso!')),
    );
  }

  Future<void> handleWithdraw(BuildContext context, dynamic negotiation) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Você desistiu da negociação.')),
    );
  }

  void main() {
    runApp(MaterialApp(
      theme: ThemeData(primarySwatch: Colors.green),
      home: const NegociacaoCatalogPage(
        title: 'Produtos do Vendedor',
        apiUrl:
            'http://192.168.146.1:8088/boletobancos/api/produtos/vendedor/4',
        actionIcon: Icons.edit,
        actionTooltip: 'Editar Produto',
      ),
    ));
  }
}
