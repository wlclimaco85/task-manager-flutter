import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/venda_model.dart';
import 'package:task_manager_flutter/data/services/vendas_caller.dart';
import 'package:task_manager_flutter/data/utils/fotos_util.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';

// Define theme colors
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

  Future<void> _fetchProducts() async {
    setState(() {
      isLoading = true;
    });
    try {
      final data = await VendasCaller().fetchCotacoes();
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
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Catálogo de Grãos'),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: () async {
              await _fetchProducts();
            },
          ),
        ],
      ),
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
                              onBuy: () => showBuyPopup(context, product),
                              onNegotiate: () =>
                                  showNegotiationPopup(context, product),
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
          backgroundColor: lightGreenBackground, // Cor do fundo
          title: Text(
            'Renegociar - ${product.descricao ?? "Sem descrição"}',
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
                decoration: InputDecoration(
                  labelText: 'Nova quantidade',
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
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
                decoration: InputDecoration(
                  labelText: 'Novo valor por saco',
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
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
                backgroundColor: buttonBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: darkGreenBorder, width: 2),
                ),
              ),
              onPressed: () async {
                final int qtdSacos =
                    int.tryParse(qtdController.text.trim()) ?? 0;
                final double vlrSacos =
                    double.tryParse(valorController.text.trim()) ?? 0.0;

                final bool response = await renegotiate(
                  vendaId: product.id!,
                  compradorId:
                      5, // ID do comprador (ajuste conforme necessário)
                  vendedorId: product.parceiro?.id ?? 0,
                  qtdSacos: qtdSacos,
                  vlrSacos: vlrSacos,
                  qtdDisponivel: product.qtdSacos!,
                );

                Navigator.of(context).pop();

                if (response) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Renegociação realizada com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _fetchProducts(); // Atualiza os produtos
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
    // Exibe o loader
    showDialog(
      context: context,
      barrierDismissible:
          false, // Impede que o usuário feche o diálogo manualmente
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Validações iniciais
      if (qtdSacos > qtdDisponivel) {
        Navigator.of(context).pop(); // Fecha o loader
        showSnackBar(
          message:
              "A quantidade de sacos solicitada ($qtdSacos) excede o disponível ($qtdDisponivel).",
          isError: true,
        );
        return false;
      }

      if (vlrSacos <= 0) {
        Navigator.of(context).pop(); // Fecha o loader
        showSnackBar(
          message: "O valor por saco deve ser maior que zero.",
          isError: true,
        );
        return false;
      }

      // Corpo da requisição
      Map<String, dynamic> requestBody = {
        "vendaId": vendaId,
        "compradorId": compradorId,
        "vendedorId": vendedorId,
        "qtdSacos": qtdSacos,
        "vlrSacos": vlrSacos,
      };

      // Faz a chamada à API
      final NetworkResponse response = await NetworkCaller()
          .postRequest(ApiLinks.insertNegociacao, requestBody);

      Navigator.of(context).pop(); // Fecha o loader

      // Verifica o resultado da requisição
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
      Navigator.of(context).pop(); // Fecha o loader
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

  const ProductCard({
    Key? key,
    required this.product,
    required this.onDetails,
    required this.onBuy,
    required this.onNegotiate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageBase64 = decodeBase64Image(getImagepadrao());
    final image = imageBase64.isNotEmpty
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
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: image,
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.descricao ?? 'Sem descrição',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Quantidade: ${product.qtdSacos} sacos'),
                  Text('Valor por saco: R\$${product.vlrSacos}'),
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Tooltip(
                message: "Detalhes",
                child: IconButton(
                  icon: const Icon(Icons.info, color: Colors.blue),
                  onPressed: onDetails,
                ),
              ),
              Tooltip(
                message: "Negociar",
                child: IconButton(
                  icon: const Icon(Icons.handshake, color: Colors.green),
                  onPressed: onNegotiate,
                ),
              ),
              Tooltip(
                message: "Comprar",
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart, color: Colors.orange),
                  onPressed: onBuy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
/*
  void showNegotiationPopup(BuildContext context, Produto product) {
    final TextEditingController qtdController = TextEditingController();
    final TextEditingController valorController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: lightGreenBackground, // Cor do fundo
          title: Text(
            'Renegociar - ${product.descricao ?? "Sem descrição"}',
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
                decoration: InputDecoration(
                  labelText: 'Nova quantidade',
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
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
                decoration: InputDecoration(
                  labelText: 'Novo valor por saco',
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
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
                backgroundColor: buttonBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: darkGreenBorder, width: 2),
                ),
              ),
              onPressed: () async {
                final int qtdSacos =
                    int.tryParse(qtdController.text.trim()) ?? 0;
                final double vlrSacos =
                    double.tryParse(valorController.text.trim()) ?? 0.0;

                final bool response = await renegotiate(
                  vendaId: product.id!,
                  compradorId:
                      5, // ID do comprador (ajuste conforme necessário)
                  vendedorId: product.parceiro?.id ?? 0,
                  qtdSacos: qtdSacos,
                  vlrSacos: vlrSacos,
                  qtdDisponivel: product.qtdSacos!,
                );

                Navigator.of(context).pop();

                if (response) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Renegociação realizada com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _fetchProducts(); // Atualiza os produtos
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
  } */
}
