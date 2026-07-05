import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';

class DashboardGmeScreen extends StatefulWidget {
  const DashboardGmeScreen({super.key});

  @override
  State<DashboardGmeScreen> createState() => _DashboardGmeScreenState();
}

class _DashboardGmeScreenState extends State<DashboardGmeScreen> {
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
      final resp =
          await TenantContext.get('${ApiLinks.baseUrl}/dashboard/gme');
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
      appBar: AppBar(title: const Text('Dashboard GME')),
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
          'Equipamentos',
          _dados['totalEquipamentos']?.toString() ?? '0',
          Icons.build_circle,
          GridColors.secondary,
        ),
        _buildKpiCard(
          'Ordens de Serviço',
          _dados['totalOrdens']?.toString() ?? '0',
          Icons.assignment,
          GridColors.primary,
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
