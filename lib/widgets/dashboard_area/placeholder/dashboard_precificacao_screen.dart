import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';

class DashboardPrecificacaoScreen extends StatefulWidget {
  const DashboardPrecificacaoScreen({super.key});

  @override
  State<DashboardPrecificacaoScreen> createState() =>
      _DashboardPrecificacaoScreenState();
}

class _DashboardPrecificacaoScreenState
    extends State<DashboardPrecificacaoScreen> {
  bool _carregando = true;
  String? _erro;
  Map<String, dynamic> _dados = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final resp = await TenantContext.get(
          '${ApiLinks.baseUrl}/dashboard/precificacao');
      if (!mounted) return;
      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
        final body = jsonDecode(utf8.decode(resp.bodyBytes));
        if (body is Map && body['data'] is Map) {
          setState(() {
            _dados = Map<String, dynamic>.from(body['data'] as Map);
            _carregando = false;
          });
          return;
        }
      }
      setState(() {
        _erro = 'Falha ao carregar dados';
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro = 'Erro: $e';
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Precificação')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_erro!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _carregar,
                          child: const Text('Tentar novamente')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildKpiRow(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildKpiRow() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildKpiCard(
          'Total Precificações',
          _dados['totalPrecificacoes']?.toString() ?? '0',
          Icons.request_quote,
          GridColors.primary,
        ),
        _buildKpiCard(
          'Em Elaboração',
          _dados['emElaboracao']?.toString() ?? '0',
          Icons.edit_note,
          Colors.orange,
        ),
        _buildKpiCard(
          'Aprovadas',
          _dados['aprovadas']?.toString() ?? '0',
          Icons.verified,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildKpiCard(String titulo, String valor, IconData icone, Color cor) {
    return SizedBox(
      width: 200,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone, color: cor, size: 32),
              const SizedBox(height: 12),
              Text(
                valor,
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: cor),
              ),
              const SizedBox(height: 4),
              Text(titulo,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }
}
