import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/venda_model.dart';
import 'package:task_manager_flutter/data/services/vendas_caller.dart';
import 'package:task_manager_flutter/data/utils/fotos_util.dart';

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

  void _fetchProducts() async {
    setState(() {
      isLoading = true;
    });
    try {
      final data = await VendasCaller().fetchCotacoes();
      setState(() {
        allProducts = data;
        filteredProducts = data; // Inicializa com todos os produtos
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar produtos: $e')),
      );
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
        title: const Text('Catálogo de Grãos'),
      ),
      body: Column(
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
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void showProductDetails(BuildContext context, Produto product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
            onPressed: () {
              print('Contrato impresso para o produto ${product.descricao}');
            },
            child: const Text('Imprimir Contrato'),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Produto product;
  final VoidCallback onDetails;
  final VoidCallback onBuy;

  const ProductCard({
    Key? key,
    required this.product,
    required this.onDetails,
    required this.onBuy,
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
                  onPressed: onBuy,
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
}
//aqui e o errado