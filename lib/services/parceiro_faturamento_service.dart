import '../models/network_response.dart';
import '../utils/api_links.dart';
import '../utils/dropdown_helpers.dart';
import '../utils/parceiro_faturamento_utils.dart';
import '../widgets/searchable_dropdown.dart';
import 'network_caller.dart';

class ParceiroFaturamentoService {
  static String observacaoPadrao(String servico, DateTime hoje) {
    return ParceiroFaturamentoUtils.observacaoPadrao(servico, hoje);
  }

  static Future<PaginaDropdown> buscarServicos({
    String? busca,
    required int pagina,
  }) {
    return DropdownHelpers.produtosContabeisBusca(
      busca: busca,
      pagina: pagina,
      tamanho: 20,
      isServico: true,
    );
  }

  static Future<List<Map<String, dynamic>>> buscarSeries(String busca) async {
    final query = busca.trim();
    final url = '${ApiLinks.allNfseSerie}?pagina=0&tamanho=200'
        '${query.isEmpty ? '' : '&serie=${Uri.encodeQueryComponent(query)}'}';
    final response = await NetworkCaller().getRequest(url);
    if (!response.isSuccess || response.body == null) return [];
    final series = _extrairLista(response.body);
    if (query.isEmpty) return series;
    final termo = query.toLowerCase();
    return series.where((item) {
      final serie = item['serie']?.toString().toLowerCase() ?? '';
      final descricao = item['descricao']?.toString().toLowerCase() ?? '';
      return serie.contains(termo) || descricao.contains(termo);
    }).toList();
  }

  static Future<NetworkResponse> faturar({
    required List<int> parceiroIds,
    required bool todos,
    required int produtoId,
    required int serieId,
    required String observacao,
  }) {
    return NetworkCaller().postRequest(
      '${ApiLinks.baseUrl}/api/parceiros/faturamento-nfse',
      ParceiroFaturamentoUtils.buildPayload(
        parceiroIds: parceiroIds,
        todos: todos,
        produtoId: produtoId,
        serieId: serieId,
        observacao: observacao,
      ),
    );
  }

  static List<Map<String, dynamic>> _extrairLista(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (value is Map) {
      for (final key in ['data', 'dados', 'content', 'items']) {
        if (value[key] != null) {
          final items = _extrairLista(value[key]);
          if (items.isNotEmpty) return items;
        }
      }
    }
    return [];
  }
}
