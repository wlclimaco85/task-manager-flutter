import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/auth_utility.dart';
import '../utils/api_links.dart';
import '../utils/grid_colors.dart';
import '../utils/tenant_context.dart';

/// H4: Dialog que exibe detalhes de um produto via GET /api/produto/{id}/detalhes
class ProdutoDetalhesDialog extends StatefulWidget {
  final Map<String, dynamic> produto;

  const ProdutoDetalhesDialog({super.key, required this.produto});

  @override
  State<ProdutoDetalhesDialog> createState() => _ProdutoDetalhesDialogState();
}

class _ProdutoDetalhesDialogState extends State<ProdutoDetalhesDialog> {
  bool _loading = true;
  Map<String, dynamic>? _detalhes;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarDetalhes();
  }

  Future<void> _carregarDetalhes() async {
    final id = widget.produto['id']?.toString() ?? '';
    if (id.isEmpty) {
      setState(() {
        _loading = false;
        _erro = 'Produto sem ID';
      });
      return;
    }

    try {
      final url = TenantContext.applyToUrl(
          '${ApiLinks.baseUrl}/api/produto/$id/detalhes');
      final token = AuthUtility.userInfo?.token;
      final resp = await http.get(
        Uri.parse(url),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        setState(() {
          _detalhes =
              body is Map<String, dynamic> ? body : (body['data'] ?? {});
          _loading = false;
        });
      } else {
        // Fallback: usa os dados já carregados na grid
        setState(() {
          _detalhes = Map<String, dynamic>.from(widget.produto);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _detalhes = Map<String, dynamic>.from(widget.produto);
          _loading = false;
          _erro = 'Usando dados locais';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nome = widget.produto['nome']?.toString() ??
        widget.produto['xProd']?.toString() ??
        'Produto';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabeçalho
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: GridColors.secondary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Corpo
            Flexible(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_erro != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                _erro!,
                                style: const TextStyle(
                                    color: Colors.orange, fontSize: 12),
                              ),
                            ),
                          _buildInfoGrid(),
                        ],
                      ),
                    ),
            ),
            // Rodapé
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGrid() {
    final d = _detalhes ?? {};
    final campos = <_CampoDetalhe>[
      _CampoDetalhe(
          'Código', d['codigo']?.toString() ?? d['codProd']?.toString()),
      _CampoDetalhe('Nome', d['nome']?.toString() ?? d['xProd']?.toString()),
      _CampoDetalhe('Descrição', d['descricao']?.toString()),
      _CampoDetalhe(
          'Preço Venda', _formatarMoeda(d['preco'] ?? d['precoVenda'])),
      _CampoDetalhe('Custo', _formatarMoeda(d['custo'] ?? d['precoCusto'])),
      _CampoDetalhe('Estoque', d['estoque']?.toString()),
      _CampoDetalhe('Estoque Mínimo', d['estoqueMinimo']?.toString()),
      _CampoDetalhe('Vendas no Mês', d['vendasMes']?.toString()),
      _CampoDetalhe(
          'Unidade', d['unidade']?.toString() ?? d['uCom']?.toString()),
      _CampoDetalhe('Categoria', _extrairNome(d['categoria'])),
      _CampoDetalhe(
          'Ativo',
          d['ativo'] == true
              ? 'Sim'
              : d['ativo'] == false
                  ? 'Não'
                  : null),
    ].where((c) => c.valor != null && c.valor!.isNotEmpty).toList();

    return Column(
      children: campos.map((c) => _buildLinha(c.label, c.valor!)).toList(),
    );
  }

  Widget _buildLinha(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _formatarMoeda(dynamic valor) {
    if (valor == null) return '';
    final v = double.tryParse(valor.toString()) ?? 0.0;
    return 'R\$ ${v.toStringAsFixed(2)}';
  }

  String? _extrairNome(dynamic campo) {
    if (campo == null) return null;
    if (campo is Map) return campo['nome']?.toString();
    return campo.toString();
  }
}

class _CampoDetalhe {
  final String label;
  final String? valor;
  const _CampoDetalhe(this.label, this.valor);
}
