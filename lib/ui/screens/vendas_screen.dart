import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/venda_model.dart';
import 'package:task_manager_flutter/data/services/vendas_caller.dart';
import 'package:task_manager_flutter/data/utils/fotos_util.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/ui/screens/update_profile.dart';
import 'package:task_manager_flutter/ui/screens/checkoutscreen.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';
import 'dart:typed_data';
import 'dart:convert';

const Color lightGreenBackground = Color.fromARGB(255, 231, 247, 233);
const Color darkGreenBorder = Color.fromARGB(255, 1, 247, 14);
const Color buttonBackground = Color.fromARGB(255, 128, 202, 132);

class ProductCatalog extends StatefulWidget {
  const ProductCatalog({Key? key}) : super(key: key);

  @override
  _ProductCatalogState createState() => _ProductCatalogState();
}

class _ProductCatalogState extends State<ProductCatalog> {
  List<Produto> allProducts = [];
  List<dynamic> filteredProducts = [];
  bool isLoading = true;

  String selectedState = "Estado";
  String selectedCity = "Cidade";

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> onTransporte(BuildContext context, Produto product) async {
    final Map<String, dynamic> requestBody = {
      "idProduto": 13,
      "qtdSacos": 10,
    };

    try {
      final NetworkResponse response = await NetworkCaller()
          .postRequest(ApiLinks.insertCotacaoFrete, requestBody);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Solicitação enviada com sucesso!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao enviar solicitação: ${response.statusCode}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao enviar solicitação: $e")),
      );
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      isLoading = true;
    });
    try {
      final data = await VendasCaller().fetchCotacoes(context);
      setState(() {
        allProducts = data;
        filteredProducts = data;
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

  void applyFilters() {
    setState(() {
      filteredProducts = allProducts.where((product) {
        final stateMatch = selectedState == "Estado" ||
            (product.parceiro?.endereco?.estado?.toString() ?? '') ==
                selectedState;
        final cityMatch = selectedCity == "Cidade" ||
            (product.parceiro?.endereco?.cidade?.toString() ?? '') ==
                selectedCity;

        return stateMatch && cityMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final states = allProducts
        .map<String>((p) =>
            p.parceiro?.endereco?.estado?.toString() ?? 'Não especificado')
        .toSet()
        .toList();
    states.insert(0, "Estado");

    final cities = allProducts
        .map<String>((p) =>
            p.parceiro?.endereco?.cidade?.toString() ?? 'Não especificado')
        .toSet()
        .toList();
    cities.insert(0, "Cidade");

    return Scaffold(
      appBar: UserBannerAppBar(
          screenTitle: "Catálogo de Grãos",
          isLoading: isLoading,
          onRefresh: _fetchProducts,
          onTapped: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const UpdateProfileScreen()));
          }),
      body: Container(
        color: lightGreenBackground,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedState,
                      onChanged: (value) {
                        setState(() {
                          selectedState = value!;
                          applyFilters();
                        });
                      },
                      items: states.map<DropdownMenuItem<String>>((state) {
                        return DropdownMenuItem<String>(
                          value: state,
                          child: Text(state),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedCity,
                      onChanged: (value) {
                        setState(() {
                          selectedCity = value!;
                          applyFilters();
                        });
                      },
                      items: cities.map<DropdownMenuItem<String>>((city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(city),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredProducts.isEmpty
                      ? const Center(child: Text('Nenhum produto encontrado'))
                      : ListView.builder(
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return ProductCard(
                              product: product,
                              onDetails: () =>
                                  showProductDetails(context, product),
                              onBuy: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CheckoutScreen(
                                    productName: 'Arroz em Casca',
                                    productValue: product.vlrSacos ?? 0.0,
                                    productQnt: product.qtdSacos ?? 0,
                                    idVenda: product.id ?? 0,
                                  ),
                                ),
                              ),
                              onNegotiate: () =>
                                  showNegotiationPopup(context, product),
                              onTransporte: () =>
                                  onTransporte(context, product),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void showProductDetails(BuildContext context, Produto product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: lightGreenBackground,
        title: Text(product.descricao ?? "SEM DESCRIÇÂO"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Safra: ${product.safra ?? "Não informado"}'),
            Text('Semente: ${product.semente ?? "Não informado"}'),
            Text('Tipo do Grão: ${product.tipoGrao ?? "Não informado"}'),
            Text(
                'Data de Retirada: ${product.dataRetirada ?? "Não informado"}'),
            Text(
                'Tipo de Negociação: ${product.tipoNegociacao ?? "Não informado"}'),
            Text(
                'Estado: ${product.parceiro?.endereco?.estado ?? "Não informado"}'),
            Text(
                'Cidade: ${product.parceiro?.endereco?.cidade ?? "Não informado"}'),
            Text('Quantidade de sacos: ${product.qtdSacos ?? 0}'),
            Text('Valor por saco: R\$${product.vlrSacos ?? 0.0}'),
            const Text('Classificação:'),
            ...product.classificacao!.map<Widget>((c) {
              return Text('${c.descricao}: ${c.valor}');
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void showBuyPopup(BuildContext context, Produto product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: lightGreenBackground,
        title: Text('Comprar - ${product.descricao}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Estado: ${product.parceiro?.endereco?.estado ?? "Não informado"}'),
            Text(
                'Cidade: ${product.parceiro?.endereco?.cidade ?? "Não informado"}'),
            Text('Quantidade de sacos: ${product.qtdSacos ?? 0}'),
            Text('Valor por saco: R\$${product.vlrSacos ?? 0.0}'),
            const Text('Classificação:'),
            ...product.classificacao!.map<Widget>((c) {
              return Text('${c.descricao}: ${c.valor}');
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final response = await renegotiate(
                vendaId: product.id!,
                vendedorId: product.parceiro!.id!,
                compradorId: 5, // Substitua com ID do comprador
                qtdSacos: product.qtdSacos! ?? 0,
                vlrSacos: product.vlrSacos ?? 0.0,
                qtdDisponivel: product.qtdSacos!,
              );
              Navigator.of(context).pop();
              if (response) {
                _fetchProducts(); // Refresh automático após sucesso
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Erro ao Comprar'),
                  ),
                );
              }
            },
            child: const Text('Comprar'),
          ),
        ],
      ),
    );
  }

  void showNegotiationPopup(BuildContext context, Produto product) {
    final TextEditingController qtdController = TextEditingController();
    final TextEditingController valorController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: lightGreenBackground,
          title: Text(
            'Negociar Arroz em Casca LOTE - ${product.id ?? "Sem descrição"}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Quantidade atual: ${product.qtdSacos ?? 0}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: qtdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nova quantidade',
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: darkGreenBorder, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: darkGreenBorder, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Valor atual por saco: R\$${product.vlrSacos ?? 0.0}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: valorController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Novo valor por saco',
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: darkGreenBorder, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: darkGreenBorder, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Cor do botão
                minimumSize:
                    const Size(150, 50), // Largura e altura mínimas do botão
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12), // Margens internas
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final int qtdSacos =
                    int.tryParse(qtdController.text.trim()) ?? 0;
                final double vlrSacos =
                    double.tryParse(valorController.text.trim()) ?? 0.0;

                final bool response = await renegotiate(
                  vendaId: product.id!,
                  compradorId: 5,
                  vendedorId: product.parceiro?.id ?? 0,
                  qtdSacos: qtdSacos,
                  vlrSacos: vlrSacos,
                  qtdDisponivel: product.qtdSacos!,
                );

                Navigator.of(context).pop();

                if (response) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Proposta enviada com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _fetchProducts();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao renegociar.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Enviar Proposta'),
            ),
          ],
        );
      },
    );
  }

  void showSnackBar({required String message, required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white), // Texto sempre branco
        ),
        backgroundColor: isError
            ? Colors.red
            : Colors.green, // Vermelho para erro, verde para sucesso
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool> renegotiate({
    required int vendaId,
    required int compradorId,
    required int vendedorId,
    required int qtdSacos,
    required double vlrSacos,
    required int qtdDisponivel,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (qtdSacos > qtdDisponivel) {
        Navigator.of(context).pop();
        showSnackBar(
          message:
              "A quantidade de sacos solicitada ($qtdSacos) excede o disponível ($qtdDisponivel).",
          isError: true,
        );
        return false;
      }

      if (vlrSacos <= 0) {
        Navigator.of(context).pop();
        showSnackBar(
          message: "O valor por saco deve ser maior que zero.",
          isError: true,
        );
        return false;
      }

      Map<String, dynamic> requestBody = {
        "vendaId": vendaId,
        "compradorId": compradorId,
        "vendedorId": vendedorId,
        "qtdSacos": qtdSacos,
        "vlrSacos": vlrSacos,
      };

      final NetworkResponse response = await NetworkCaller()
          .postRequest(ApiLinks.insertNegociacao, requestBody);

      Navigator.of(context).pop();

      if (response.isSuccess) {
        showSnackBar(
          message: "Proposta enviada com sucesso!",
          isError: false,
        );
        return true;
      } else {
        showSnackBar(
          message: "Erro ao enviar proposta.",
          isError: true,
        );
        return false;
      }
    } catch (e) {
      Navigator.of(context).pop();
      showSnackBar(
        message: "Erro: ${e.toString()}",
        isError: true,
      );
      return false;
    }
  }
}

class ProductCard extends StatelessWidget {
  final Produto product;
  final VoidCallback onDetails;
  final VoidCallback onBuy;
  final VoidCallback onNegotiate;
  final VoidCallback onTransporte;

  const ProductCard({
    Key? key,
    required this.product,
    required this.onDetails,
    required this.onBuy,
    required this.onNegotiate,
    required this.onTransporte,
  }) : super(key: key);

  Widget getFirstImageOrDefault(String photosBase64) {
    if (photosBase64.isNotEmpty) {
      try {
        final Uint8List imageBytes = base64Decode(photosBase64);
        return Image.memory(
          imageBytes,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        );
      } catch (e) {
        debugPrint('Erro ao decodificar a imagem: $e');
      }
    }

    return const Icon(Icons.image, size: 100);
  }

  List<String> getValidImageList(Produto product) {
    if (product?.listFotos != null &&
        product!.listFotos!.isNotEmpty &&
        product.listFotos!.first.foto != null) {
      return [product.listFotos!.first.foto!];
    }
    return [getImagepadrao()];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      color: lightGreenBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: darkGreenBorder, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: getFirstImageOrDefault(getValidImageList(product).first),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Arroz em Casca - Lote : ' + product.id.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                          'Estado: ${product.parceiro?.endereco?.estado ?? "Não informado"}'),
                      Text(
                          'Cidade: ${product.parceiro?.endereco?.cidade ?? "Não informado"}'),
                      Text('Quantidade: ${product.qtdSacos} sacos'),
                      Text('Valor por saco: R\$${product.vlrSacos}'),
                      Text('Safra: ${product.safra ?? "Não informado"}'),
                      Text('Semente: ${product.semente ?? "Não informado"}'),
                      Text(
                          'Tipo do Grão: ${product.tipoGrao ?? "Não informado"}'),
                      Text(
                          'Data de Retirada: ${product.dataRetirada ?? "Não informado"}'),
                      Text(
                          'Tipo de Negociação: ${product.tipoNegociacao ?? "Não informado"}'),
                      const Text('Classificação:'),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: product.classificacao!.map<Widget>((c) {
                          return Container(
                            margin: const EdgeInsets.only(left: 16, top: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.circle,
                                    size: 8, color: Colors.black),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('${c.descricao}: ${c.valor}',
                                      style: const TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.grey),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.info, color: Colors.blue),
                      onPressed: onDetails,
                    ),
                    const Text(
                      "Detalhes",
                      style: TextStyle(fontSize: 12, color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.handshake, color: Colors.green),
                      onPressed: onNegotiate,
                    ),
                    const Text(
                      "Negociar",
                      style: TextStyle(fontSize: 12, color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.shopping_cart, color: Colors.orange),
                      onPressed: onBuy,
                    ),
                    const Text(
                      "Comprar",
                      style: TextStyle(fontSize: 12, color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.local_shipping,
                          color: Colors.purple),
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("Cotação de Transporte"),
                              content: const Text(
                                  "Vamos enviar suas informações para nossa transportadora parceira e o mais breve possível será enviado o valor do frete."),
                              actions: [
                                TextButton(
                                  child: const Text("Cancelar"),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                ElevatedButton(
                                  child: const Text("Confirmar"),
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    const Text(
                      "Cotar Transporte",
                      style: TextStyle(fontSize: 12, color: Colors.black),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
