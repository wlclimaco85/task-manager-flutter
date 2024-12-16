import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/venda_model.dart';
import 'package:task_manager_flutter/data/services/vendas_caller.dart';
import 'dart:convert';
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

  void _fetchProducts() {
    setState(() {
      isLoading = true;
    });
    VendasCaller().fetchCotacoes().then((data) {
      setState(() {
        allProducts = data;
        isLoading = false;
      });
    });
  }

  void applyFilters() {
    setState(() {
      filteredProducts = allProducts.where((product) {
        final stateMatch = selectedState == "Estado" ||
            (product.parceiro?.endereco?.estado.toString() ?? '') ==
                selectedState;
        final cityMatch = selectedCity == "Estado" ||
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
          // Filtros
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
          // Lista de Produtos
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(child: Text('Nenhum produto encontrado'))
                : ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return ProductCard(
                        product: product,
                        onDetails: () => showProductDetails(context, product),
                        onBuy: () => showBuyPopup(context, product),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void showProductDetails(BuildContext context, dynamic product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(product.descricao ?? "SEM DESCRIÇÂO"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Estado: ${product?.parceiro?.endereco?.estado ?? "Não informado"}'),
            Text(
                'Cidade:  ${product?.parceiro.endereco?.cidade ?? "Não informado"}'),
            Text('Quantidade de sacos: ${product.qtdSacos}'),
            Text('Valor por saco: R\$${product.vlrSacos}'),
            const Text('Classificação:'),
            ...product?.classificacao.map<Widget>((c) {
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

  void showBuyPopup(BuildContext context, dynamic product) {
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
            Text('Quantidade de sacos: ${product.qtdSacos}'),
            Text('Valor por saco: R\$${product.vlrSacos}'),
            Text('Data de retirada: Informe o vendedor'),
            Text('Classificação:'),
            ...product.classificacao.map<Widget>((c) {
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
              // Aqui você pode implementar a funcionalidade de impressão de contrato
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
  final dynamic product;
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
    //final imageBase64 = showBase64ImageDefald(product['listFotos'][0]['foto']);
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
            children: [
              TextButton(
                onPressed: onDetails,
                child: const Text('Detalhes'),
              ),
              ElevatedButton(
                onPressed: onBuy,
                child: const Text('Abrir Negociação'),
              ),
              ElevatedButton(
                onPressed: onBuy,
                child: const Text('Comprar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
