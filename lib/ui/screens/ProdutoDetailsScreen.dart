import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/task_model.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/ui/widgets/status_change_botom_sheet.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:task_manager_flutter/data/models/noticias_model.dart';
import 'package:task_manager_flutter/ui/screens/NewsDetailScreen.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';
import 'package:task_manager_flutter/ui/screens/update_profile.dart';

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
  late Future<Map<String, dynamic>> _futureProduto;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _futureProduto = _fetchProdutoDetails();
  }

  Future<Map<String, dynamic>> _fetchProdutoDetails() async {
    final response = await NetworkCaller().getRequests(
      ApiLinks.fecthProdutosById + '${widget.produtoId}',
      context,
    );

    if (response.statusCode == 200 && response.body != null) {
      return response.body!;
    } else {
      throw Exception('Falha ao carregar detalhes do produto');
    }
  }

  void _refresh() {
    setState(() {
      _futureProduto = _fetchProdutoDetails();
    });
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
        title: const Text('Detalhes do Produto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Container(
        color: lightGreenBackground,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _futureProduto,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            }

            final account = snapshot.data!['data']['account'][0];
            final listFotos = account['listFotos'] as List;

            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Carrossel de Fotos
                        SizedBox(
                          height: 200,
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
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                            listFotos[index]['foto']),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
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
                                              ? Colors.white
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
                        const SizedBox(height: 20),

                        // Informações do Produto
                        _buildInfoItem('Descrição', account['descricao']),
                        _buildInfoItem('Quantidade de Sacos',
                            account['qtdSacos'].toString()),
                        _buildInfoItem(
                            'Valor por Saco', 'R\$ ${account['vlrSacos']}'),
                        _buildInfoItem(
                            'Data de Retirada', account['dtRetirada']),
                        _buildInfoItem('Safra', account['safra']),
                        _buildInfoItem('Semente', account['semente']),
                        _buildInfoItem('Tipo de Grão', account['tipoGrao']),

                        // Informações do Parceiro
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Parceiro:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        _buildInfoItem('Nome', account['parceiro']['nome']),
                        _buildInfoItem('CPF', account['parceiro']['cpf']),
                        _buildInfoItem('Email', account['parceiro']['email']),

                        // Classificações
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Classificações:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...account['classificacao']
                            .map<Widget>((classificacao) => _buildInfoItem(
                                classificacao['descricao'],
                                classificacao['valor'].toString()))
                            .toList(),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
