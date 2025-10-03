import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/comunicados_model.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';

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

// ==============================================
// MOBILE GRID SCREEN - CARD BASED
// ==============================================
class GridColors {
  static const Color primary = Color(0xFF93070A);
  static const Color primaryDark = Color(0xFF6A0507);
  static const Color primaryLight = Color(0xFFB84042);
  static const Color secondary = Color(0xFF005826);
  static const Color secondaryLight = Color(0xFF2E7D32);
  static const Color secondaryDark = Color(0xFF003D1A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF000000);
  static const Color link = Color(0xFFFF0000);
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFF93070A);
  static const Color buttonBackground = Color(0xFF93070A);
  static const Color buttonText = Color(0xFFFFFFFF);
  static const Color background = Color(0xFF005826);
  static const Color card = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFA000);
  static const Color success = Color(0xFF2E7D32);
  static const Color info = Color(0xFF1976D2);
  static const Color divider = Color(0xFFBDBDBD);
  static const Color filterBackground = Color(0xFFEFEFEF);
  static const Color hover = Color(0x1A000000);
  static const Color selectedRow = Color(0xFFE3F2FD);
  static const Color dialogBackground = Color(0xFFFFFFFF);
  static const Color shadow = Color(0x26000000);
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GridColors.card,
              GridColors.primaryLight.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _showNewsDetail(news),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com título e status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        news.titulo ?? 'Sem título',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatusIndicator(news.autor),
                  ],
                ),

                const SizedBox(height: 12),

                // Conteúdo
                Text(
                  news.conteudo ?? 'Conteúdo não disponível',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                // Footer com metadados
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey[300]!)),
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
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (news.dhCreatedAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd/MM/yyyy • HH:mm')
                                  .format(news.dhCreatedAt!.toLocal()),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: GridColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header do modal
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: GridColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.announcement, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      news.titulo ?? 'Comunicado',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Conteúdo
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      news.conteudo ?? 'Conteúdo não disponível',
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Informações adicionais
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                              'Autor:', news.autor ?? 'Não informado'),
                          _buildInfoRow(
                              'Data:',
                              news.dhCreatedAt != null
                                  ? DateFormat('dd/MM/yyyy às HH:mm')
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
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
          Icon(
            Icons.announcement_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum comunicado disponível',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Novos comunicados aparecerão aqui',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: UserBannerAppBar(
        screenTitle: "Comunicados",
        isLoading: isLoading,
        onRefresh: _refreshNews,
        showFilterButton: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNews,
        backgroundColor: Colors.white,
        color: GridColors.primary,
        child: newsList.isEmpty && !isLoading
            ? _buildEmptyState()
            : ListView.builder(
                controller: _controller,
                itemCount: newsList.length + (isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == newsList.length) {
                    return isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : const SizedBox.shrink();
                  }
                  return _buildNewsItem(newsList[index], index);
                },
              ),
      ),
      floatingActionButton: widget.floatingActionButton
          ? FloatingActionButton(
              onPressed: _refreshNews,
              backgroundColor: GridColors.primary,
              child: const Icon(Icons.refresh, color: Colors.white),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
