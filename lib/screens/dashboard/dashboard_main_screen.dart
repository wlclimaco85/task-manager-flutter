// lib/screens/dashboard/dashboard_main_screen.dart
// Dashboard V003: KPIs (4), gráfico 12 meses, top 3 parceiros, pull-to-refresh
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/utils/grid_colors.dart';
import 'package:task_manager_flutter/utils/api_links.dart';
import 'package:task_manager_flutter/services/network_caller.dart';
import 'package:task_manager_flutter/models/network_response.dart';
import 'dart:convert';

class DashboardMainScreen extends StatefulWidget {
  const DashboardMainScreen({super.key});

  @override
  State<DashboardMainScreen> createState() => _DashboardMainScreenState();
}

class _DashboardMainScreenState extends State<DashboardMainScreen> {
  bool isLoading = true;
  Map<String, dynamic>? kpiData;
  List<dynamic> trendData = [];
  List<dynamic> clientDistribution = [];
  List<dynamic> statusCounts = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  /// Busca todos os dados do dashboard em paralelo
  Future<void> _fetchDashboardData() async {
    setState(() => isLoading = true);

    try {
      // Busca KPIs
      final kpiResponse = await NetworkCaller().getRequest(ApiLinks.kpis);
      if (kpiResponse.isSuccess) {
        setState(() => kpiData = kpiResponse.body as Map<String, dynamic>?);
      }

      // Busca série de 12 meses (Finance Trend)
      final trendResponse = await NetworkCaller().getRequest(ApiLinks.trend);
      if (trendResponse.isSuccess) {
        final raw = trendResponse.body?['data'];
        if (raw is List) {
          setState(() => trendData = List<dynamic>.from(raw));
        } else if (trendResponse.body != null) {
          setState(() => trendData = [trendResponse.body]);
        } else {
          setState(() => trendData = []);
        }
      }

      // Busca top 3 parceiros (Client Distribution)
      final clientResponse = await NetworkCaller().getRequest(ApiLinks.clientDistribution);
      if (clientResponse.isSuccess) {
        final raw = clientResponse.body?['data'];
        if (raw is List) {
          setState(() => clientDistribution = List<dynamic>.from(raw).take(3).toList());
        } else {
          setState(() => clientDistribution = []);
        }
      }

      // Busca status counts
      final statusResponse = await NetworkCaller().getRequest(ApiLinks.statusCounts);
      if (statusResponse.isSuccess) {
        final raw = statusResponse.body?['data'];
        if (raw is List) {
          setState(() => statusCounts = List<dynamic>.from(raw));
        } else {
          setState(() => statusCounts = []);
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar dashboard: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Pull-to-refresh: recarrega todos os dados
  Future<void> _onRefresh() async {
    await _fetchDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    const Text(
                      'Carteira Financeira',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // KPIs (4 cards)
                    _buildKPIsRow(),
                    const SizedBox(height: 24),

                    // Gráfico 12 meses
                    _buildTrendSection(),
                    const SizedBox(height: 24),

                    // Top 3 parceiros
                    _buildClientDistributionSection(),
                    const SizedBox(height: 24),

                    // Status counts
                    _buildStatusCountsSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  /// 4 KPIs em grid 2x2
  Widget _buildKPIsRow() {
    if (kpiData == null) {
      return const SizedBox.shrink();
    }

    final receita = (kpiData!['receita'] ?? 0.0) as dynamic;
    final despesa = (kpiData!['despesa'] ?? 0.0) as dynamic;
    final saldo = (kpiData!['saldo'] ?? 0.0) as dynamic;
    final margem = (kpiData!['margem'] ?? 0.0) as dynamic;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildKPICard('Receita', _formatCurrency(receita), GridColors.success),
        _buildKPICard('Despesa', _formatCurrency(despesa), GridColors.error),
        _buildKPICard('Saldo', _formatCurrency(saldo), GridColors.primary),
        _buildKPICard('Margem', '${_formatPercent(margem)}%', GridColors.warning),
      ],
    );
  }

  /// Card individual de KPI
  Widget _buildKPICard(String label, String value, Color bgColor) {
    return Card(
      color: bgColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: bgColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: bgColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Seção de tendência (12 meses)
  Widget _buildTrendSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tendência - Últimos 12 Meses',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (trendData.isEmpty)
          const SizedBox(
            height: 200,
            child: Center(
              child: Text('Sem dados disponíveis'),
            ),
          )
        else
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'Gráfico: ${trendData.length} períodos',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Top 3 parceiros (Client Distribution)
  Widget _buildClientDistributionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top 3 Parceiros',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (clientDistribution.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Sem dados de parceiros'),
            ),
          )
        else
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: clientDistribution.length,
              itemBuilder: (context, index) {
                final item = clientDistribution[index];
                final nome = item['nome'] ?? item['parceiro'] ?? 'Parceiro ${index + 1}';
                final valor = item['valor'] ?? 0;

                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(nome),
                  trailing: Text(_formatCurrency(valor)),
                );
              },
            ),
          ),
      ],
    );
  }

  /// Status Counts (resumo)
  Widget _buildStatusCountsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumo de Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (statusCounts.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Sem dados de status'),
            ),
          )
        else
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: List.generate(statusCounts.length, (index) {
                  final item = statusCounts[index];
                  final status = item['status'] ?? 'Status ${index + 1}';
                  final count = item['count'] ?? 0;

                  return Card(
                    color: GridColors.primary.withOpacity(0.1),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            count.toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            status,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
      ],
    );
  }

  /// Formatadores
  String _formatCurrency(dynamic value) {
    if (value == null) return 'R\$ 0,00';
    final double doubleValue = (value is double) ? value : (value as int).toDouble();
    final formatted = doubleValue.toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ ${formatted.replaceAllMapped(RegExp(r',(\d{3})(?=,)'), (Match m) => '.${m.group(1)!}')}';
  }

  String _formatPercent(dynamic value) {
    if (value == null) return '0';
    final double doubleValue = (value is double) ? value : (value as int).toDouble();
    return doubleValue.toStringAsFixed(1);
  }
}
