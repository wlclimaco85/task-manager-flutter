import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Define theme colors
const Color lightGreenBackground = Color.fromARGB(255, 231, 247, 233);
const Color darkGreenBorder = Color.fromARGB(255, 1, 247, 14);
const Color buttonBackground = Color.fromARGB(255, 128, 202, 132);

class ProductCatalogPage extends StatefulWidget {
  final String title;
  final String apiUrl;
  final IconData actionIcon;
  final String actionTooltip;

  const ProductCatalogPage({
    Key? key,
    required this.title,
    required this.apiUrl,
    required this.actionIcon,
    required this.actionTooltip,
  }) : super(key: key);

  @override
  _ProductCatalogPageState createState() => _ProductCatalogPageState();
}

class _ProductCatalogPageState extends State<ProductCatalogPage> {
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
      final response = await http.get(Uri.parse(widget.apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          products = data['data']['account'];
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar produtos: $error')),
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
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: fetchProducts,
          ),
        ],
      ),
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
          product['descricao'] ?? 'Sem descrição',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: ${product['tipo'] ?? 'Não especificado'}'),
            Text('Quantidade de sacos: ${product['qtdSacos'] ?? 0}'),
            Text('Valor por saco: R\$${product['vlrSacos'] ?? 0.0}'),
            Text(
                'Data de retirada: ${product['dtRetirada'] ?? 'Não especificado'}'),
            const SizedBox(height: 8),
            const Text('Negociações:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...List.generate((product['negociacoes'] as List).length, (i) {
              final negotiation = product['negociacoes'][i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Comprador ID: ${negotiation['compradorId']}'),
                  Text('Quantidade: ${negotiation['qtdSacos']}'),
                  Text('Valor por saco: R\$${negotiation['vlrSacos']}'),
                  Text('Status: ${negotiation['status']}'),
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

  @override
  Widget build(BuildContext context) {
    final String imageBase64 = product['foto'] ?? '';
    final Widget image = imageBase64.isNotEmpty
        ? Image.memory(
            base64Decode(imageBase64),
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
                    product['descricao'] ?? 'Sem descrição',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Quantidade: ${product['qtdSacos']} sacos'),
                  Text('Valor por saco: R\$${product['vlrSacos']}'),
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Tooltip(
                message: actionTooltip,
                child: IconButton(
                  icon: Icon(actionIcon, color: Colors.green),
                  onPressed: onAction,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    theme: ThemeData(primarySwatch: Colors.green),
    home: const ProductCatalogPage(
      title: 'Produtos do Vendedor',
      apiUrl: 'http://192.168.146.1:8088/boletobancos/api/produtos/vendedor/4',
      actionIcon: Icons.edit,
      actionTooltip: 'Editar Produto',
    ),
  ));
}
