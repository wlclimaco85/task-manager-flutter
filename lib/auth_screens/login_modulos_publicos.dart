import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../utils/api_links.dart';
import '../utils/app_logger.dart';

/// Modulo da vitrine do login, vindo do catalogo do Painel do Dono.
class ModuloPublico {
  final String nome;
  final String descricao;
  const ModuloPublico(this.nome, this.descricao);

  IconData get icone {
    final n = nome.toLowerCase();
    if (n.contains('nfc') || n.contains('fnc')) return Icons.point_of_sale_outlined;
    if (n.contains('nfs')) return Icons.description_outlined;
    if (n.contains('fiscal') || n.contains('nf-e') || n.contains('nfe')) return Icons.receipt_long_outlined;
    if (n.contains('transporte')) return Icons.local_shipping_outlined;
    if (n.contains('estoque')) return Icons.inventory_2_outlined;
    if (n.contains('financeiro')) return Icons.insights_outlined;
    if (n.contains('comercial') || n.contains('gme')) return Icons.storefront_outlined;
    if (n.contains('pessoal')) return Icons.groups_outlined;
    if (n.contains('precifica')) return Icons.sell_outlined;
    if (n.contains('service')) return Icons.headset_mic_outlined;
    if (n.contains('projeto')) return Icons.account_tree_outlined;
    return Icons.extension_outlined;
  }
}

/// So os modulos cadastrados e ativos no Painel do Dono (o backend filtra). Sem resposta, lista vazia:
/// nunca mostrar modulo fixo no codigo.
Future<List<ModuloPublico>> carregarModulosPublicos({http.Client? client}) async {
  try {
    final url = Uri.parse('${ApiLinks.baseUrl}/api/public/modulos');
    final res = await (client == null ? http.get(url) : client.get(url)).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      AppLogger.i.warn('Vitrine de modulos do login: HTTP ${res.statusCode}');
      return const [];
    }
    final nomes = <String>{};
    final modulos = <ModuloPublico>[];
    for (final m in (jsonDecode(utf8.decode(res.bodyBytes)) as List).whereType<Map>()) {
      final nome = '${m['nome'] ?? ''}'.trim();
      // nome repetido no catalogo aparece uma vez so
      if (nome.isNotEmpty && nomes.add(nome.toLowerCase())) {
        modulos.add(ModuloPublico(nome, '${m['descricao'] ?? ''}'.trim()));
      }
    }
    return modulos;
  } catch (e) {
    AppLogger.i.warn('Vitrine de modulos do login indisponivel: $e');
    return const [];
  }
}
