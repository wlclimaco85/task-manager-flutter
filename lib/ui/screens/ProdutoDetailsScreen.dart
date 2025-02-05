import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:task_manager_flutter/data/services/vendas_caller.dart';
import 'package:task_manager_flutter/data/models/venda_model.dart';

// Define cores
const Color lightGreenBackground = Color.fromARGB(255, 231, 247, 233);
const Color mediumGreenBackground = Color.fromARGB(255, 200, 230, 200);
const Color darkGreenBorder = Color.fromARGB(255, 1, 247, 14);

// Tela de Detalhes
class ProdutoDetailsScreen extends StatefulWidget {
  final int produtoId;

  const ProdutoDetailsScreen({super.key, required this.produtoId});

  @override
  State<ProdutoDetailsScreen> createState() => _ProdutoDetailsScreenState();
}

class _ProdutoDetailsScreenState extends State<ProdutoDetailsScreen> {
  Future<List<Produto>> _futureProduto = Future.value([]);
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProdutoDetails();
  }

  Future<void> _fetchProdutoDetails() async {
    setState(() {
      isLoading = true; // Show loading indicator
    });
    try {
      final produto =
          await VendasCaller().fetchProdutoDetails(context, widget.produtoId);
      setState(() {
        _futureProduto = Future.value(produto); // Assign the Produto object
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar produto: $e')),
      );
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator
      });
    }
  }

  void _refresh() {
    _fetchProdutoDetails(); // Call the same function for refresh
  }

  void _previousPage() {
    _pageController.previousPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _nextPage() {
    _pageController.nextPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mediumGreenBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Detalhes do Produto',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _refresh,
          ),
        ],
      ),
      backgroundColor: lightGreenBackground,
      body: FutureBuilder<List<Produto>>(
        future: _futureProduto,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(darkGreenBorder),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final account =
              snapshot.data == null ? Produto() : snapshot.data!.first;
          final listFotos = account.listFotos as List;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: mediumGreenBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: darkGreenBorder, width: 2),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carrossel de Fotos
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: darkGreenBorder, width: 2),
                    ),
                    child: SizedBox(
                      height: 250,
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: listFotos.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentPage = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              final imageData = listFotos[index]!
                                  .foto; // Get the base64 string

                              // Check if imageData is a valid base64 string
                              try {
                                Uint8List bytes = base64.decode(
                                    imageData); // Decode the base64 string

                                return Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: MemoryImage(
                                          bytes), // Use MemoryImage to display the image
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              } catch (e) {
                                // Handle invalid base64 data, e.g., display a placeholder or error message
                                print('Error decoding base64 image: $e');
                                return Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey, // Placeholder color
                                  ),
                                  child: const Center(
                                      child: Icon(Icons.error,
                                          color: Colors
                                              .white)), // Placeholder icon
                                );
                              }
                            },
                          ),
                          Positioned(
                            bottom: 10,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios),
                                  onPressed: _previousPage,
                                ),
                                ...List.generate(
                                  listFotos.length,
                                  (index) => Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _currentPage == index
                                          ? darkGreenBorder
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios),
                                  onPressed: _nextPage,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Informações do Produto
                  _buildSectionTitle('Informações do Produto'),
                  _buildInfoItem('Descrição', account.descricao),
                  _buildInfoItem(
                      'Quantidade de Sacos', account.qtdSacos.toString()),
                  _buildInfoItem('Valor por Saco', 'R\$ ${account.vlrSacos}'),
                  _buildInfoItem('Data de Retirada', account.dataRetirada),
                  _buildInfoItem('Safra', account.safra),
                  _buildInfoItem('Semente', account.semente),
                  _buildInfoItem('Tipo de Grão', account.tipoGrao),

                  // Informações do Parceiro
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Vendedor:',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ),
                  _buildInfoItem('Nome', account.parceiro!.nome),
                  _buildInfoItem(
                      'Endereço',
                      '${account.parceiro!.endereco!.bairro}, '
                          '${account.parceiro!.endereco!.cidade}/${account.parceiro!.endereco!.estado}'),

                  // Classificações
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Classificações:',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ),
                  ...account.classificacao!
                      .map<Widget>((classificacao) => _buildInfoItem(
                          classificacao.descricao!,
                          classificacao.valor!.toString()))
                      .toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String? value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lightGreenBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: darkGreenBorder, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
