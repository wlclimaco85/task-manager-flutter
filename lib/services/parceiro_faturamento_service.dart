import '../models/network_response.dart';
import '../utils/api_links.dart';
import '../utils/dropdown_helpers.dart';
import '../utils/parceiro_faturamento_utils.dart';
import '../utils/tenant_context.dart';
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
    final params = <String>[
      'pagina=0',
      'tamanho=200',
      if (TenantContext.empresaId != null) 'empId=${TenantContext.empresaId}',
      if (TenantContext.parceiroId != null) 'parceiroId=${TenantContext.parceiroId}',
      if (query.isNotEmpty) 'serie=${Uri.encodeQueryComponent(query)}',
    ];

    final queryString = params.join('&');
    final urlNfse = '${ApiLinks.allNfseSerie}?$queryString';
    final urlNfe = '${ApiLinks.allNfeSerie}?$queryString';

    final resNfse = await NetworkCaller().getRequest(urlNfse);
    final resNfe = await NetworkCaller().getRequest(urlNfe);

    final seriesNfse = (resNfse.isSuccess && resNfse.body != null)
        ? _extrairLista(resNfse.body)
        : <Map<String, dynamic>>[];
    final seriesNfe = (resNfe.isSuccess && resNfe.body != null)
        ? _extrairLista(resNfe.body)
        : <Map<String, dynamic>>[];

    // Filtrar séries de NFe que sejam do tipo 'NFS-e' (ou sem tipo especificado)
    final seriesNfeFiltradas = seriesNfe.where((item) {
      final tipo = item['tipo']?.toString().toUpperCase();
      return tipo == null || tipo.isEmpty || tipo == 'NFS-E' || tipo == 'NFSE';
    }).toList();

    // Combinar evitando duplicatas de id
    final idsVistos = <String>{};
    final combinadas = <Map<String, dynamic>>[];

    for (final item in [...seriesNfse, ...seriesNfeFiltradas]) {
      final idKey = '${item['id']}_${item['serie']}';
      if (!idsVistos.contains(idKey)) {
        idsVistos.add(idKey);
        combinadas.add(item);
      }
    }

    // Montar rotulo de exibicao 'display' com formato "serie - descricao [Empresa: ... / Parceiro: ...]"
    for (final item in combinadas) {
      final s = item['serie']?.toString().trim() ?? '';
      final d = item['descricao']?.toString().trim() ?? '';
      String label = d.isNotEmpty ? '$s - $d' : s;

      final emp = item['empresa']?['nome'] ?? item['empresa']?['razaoSocial'] ?? item['empresaNome'];
      final parc = item['parceiro']?['nome'] ?? item['parceiro']?['razaoSocial'] ?? item['parceiroNome'];

      final det = <String>[];
      if (emp != null && emp.toString().isNotEmpty) det.add('Empresa: $emp');
      if (parc != null && parc.toString().isNotEmpty) det.add('Parceiro: $parc');

      if (det.isNotEmpty) {
        label += ' (${det.join(' / ')})';
      }

      item['display'] = label;
    }

    if (query.isEmpty) return combinadas;
    final termo = query.toLowerCase();
    return combinadas.where((item) {
      final display = item['display']?.toString().toLowerCase() ?? '';
      final serie = item['serie']?.toString().toLowerCase() ?? '';
      final descricao = item['descricao']?.toString().toLowerCase() ?? '';
      return display.contains(termo) || serie.contains(termo) || descricao.contains(termo);
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
