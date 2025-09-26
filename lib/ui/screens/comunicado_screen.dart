import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/comunicados_model.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';

class ComunicadoScreen extends StatefulWidget {
  final String screenStatus;
  final String apiLink;
  final bool showAllSummeryCard;
  final bool floatingActionButton;

  const ComunicadoScreen({
    super.key,
    required this.screenStatus,
    required this.apiLink,
    this.showAllSummeryCard = false,
    this.floatingActionButton = true,
  });

  @override
  State<ComunicadoScreen> createState() => _ComunicadoScreenState();
}

class ComunicadoModel {
  String? status;
  String? token;
  List<Comunicado>? data;

  ComunicadoModel({this.status, this.token, this.data});

  ComunicadoModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    token = json['token'];

    // Verifica se 'data' é uma lista de listas
    if (json['data'] != null) {
      /*  data = [];
    // Itera sobre cada lista no 'data'
    for (var list in json['data']) {
      // Adiciona à lista de 'data' uma lista de Map<String, dynamic>
      data.add(List<Map<String, dynamic>>.from(list.map((item) => Map<String, dynamic>.from(item))));
    } */
      //  List<Data> dataList = Data.fromJsonList2(json['data']['noticiasDTO']);
      List<Comunicado> dataList =
          Comunicado.fromJsonList(json['data']['dados']);
      data =
          dataList; //json['data'] != null ? Data.fromJson(json['data']) : null;
    } else {
      data = null;
    }

    //data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  /* Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }*/

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;
    if (this.data != null) {
      // Mapeia cada item da lista 'data' para o formato JSON
      data['data'] = this.data!.map((item) => item.toJson()).toList();
    }
    return data;
  }
}

class _ComunicadoScreenState extends State<ComunicadoScreen> {
  List<Comunicado> newsList = [];
  bool isLoading = false;
  bool _isRefreshing = false;
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchNews();
    _controller.addListener(_onScroll);
  }

  Future<void> _fetchNews({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() => _isRefreshing = true);
    } else {
      setState(() => isLoading = true);
    }

    try {
      final NetworkResponse response =
          await NetworkCaller().getRequest(ApiLinks.allComunicados);

      if (response.statusCode == 200 && response.body != null) {
        final model = ComunicadoModel.fromJson(response.body!);
        if (model.data != null) {
          setState(() {
            if (isRefresh) newsList.clear();
            newsList.addAll(model.data!);
          });
        }
      } else {
        _showErrorSnackBar('Falha ao carregar comunicados');
      }
    } catch (e) {
      _showErrorSnackBar('Erro: $e');
    } finally {
      setState(() {
        isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: GridColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onScroll() {
    if (_controller.position.pixels == _controller.position.maxScrollExtent &&
        !isLoading &&
        newsList.isNotEmpty) {
      _fetchNews();
    }
  }

  Future<void> _refreshNews() async {
    await _fetchNews(isRefresh: true);
  }

  Widget _buildNewsItem(Comunicado news, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GridColors.card.withOpacity(0.9),
              GridColors.primaryLight.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com título e indicador de status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      news.titulo ?? 'Sem título',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: GridColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusIndicator(news.autor),
                ],
              ),

              const SizedBox(height: 12),

              // Conteúdo
              Text(
                news.conteudo ?? 'Conteúdo não disponível',
                style: TextStyle(
                  fontSize: 14,
                  color: GridColors.textSecondary.withOpacity(0.8),
                  height: 1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Footer com informações
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(
                          color: GridColors.divider.withOpacity(0.3))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Por: ${news.autor ?? 'Autor desconhecido'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: GridColors.textSecondary.withOpacity(0.6),
                          ),
                        ),
                        if (news.dhCreatedAt != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm')
                                .format(news.dhCreatedAt!.toLocal()),
                            style: TextStyle(
                              fontSize: 10,
                              color: GridColors.textSecondary.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Botão de ação
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios,
                          size: 16, color: GridColors.primary),
                      onPressed: () => _showNewsDetail(news),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String? status) {
    Color indicatorColor;
    String statusText;

    switch (status?.toLowerCase()) {
      case 'urgente':
        indicatorColor = GridColors.error;
        statusText = 'URGENTE';
        break;
      case 'importante':
        indicatorColor = GridColors.warning;
        statusText = 'IMPORTANTE';
        break;
      default:
        indicatorColor = GridColors.success;
        statusText = 'NORMAL';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: indicatorColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: indicatorColor,
        ),
      ),
    );
  }

  void _showNewsDetail(Comunicado news) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: GridColors.card,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header do modal
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GridColors.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.announcement, color: GridColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      news.titulo ?? 'Comunicado',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: GridColors.textSecondary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: GridColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Conteúdo
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      news.conteudo ?? 'Conteúdo não disponível',
                      style: TextStyle(
                        fontSize: 16,
                        color: GridColors.textSecondary.withOpacity(0.8),
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Informações adicionais
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: GridColors.filterBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                              'Autor:', news.autor ?? 'Não informado'),
                          _buildInfoRow(
                              'Data:',
                              news.dhCreatedAt != null
                                  ? DateFormat('dd/MM/yyyy HH:mm')
                                      .format(news.dhCreatedAt!.toLocal())
                                  : 'Não informada'),
                          _buildInfoRow('Status:', news.autor ?? 'Normal'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: GridColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: GridColors.textSecondary.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.announcement,
              size: 64, color: GridColors.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Nenhum comunicado disponível',
            style: TextStyle(
              fontSize: 18,
              color: GridColors.textSecondary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Novos comunicados aparecerão aqui',
            style: TextStyle(
              fontSize: 14,
              color: GridColors.textSecondary.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: UserBannerAppBar(
        screenTitle: "Comunicados",
        isLoading: isLoading,
        onRefresh: _refreshNews,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNews,
        backgroundColor: GridColors.card,
        color: GridColors.primary,
        child: CustomScrollView(
          controller: _controller,
          slivers: [
            // Header
            SliverAppBar(
              expandedHeight: 100,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        GridColors.primary.withOpacity(0.8),
                        GridColors.secondary.withOpacity(0.6),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Comunicados Institucionais',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: GridColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              pinned: true,
              backgroundColor: GridColors.primary,
            ),

            // Lista de comunicados
            if (newsList.isEmpty && !isLoading)
              SliverFillRemaining(child: _buildEmptyState())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == newsList.length) {
                      return isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : const SizedBox.shrink();
                    }
                    return _buildNewsItem(newsList[index], index);
                  },
                  childCount: newsList.length + (isLoading ? 1 : 0),
                ),
              ),
          ],
        ),
      ),

      // Botão flutuante para recarregar
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshNews,
        backgroundColor: GridColors.primary,
        child: Icon(Icons.refresh, color: GridColors.textPrimary),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
