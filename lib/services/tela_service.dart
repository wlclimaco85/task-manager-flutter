import '../models/tela_model.dart';
import '../models/network_response.dart';
import '../utils/api_links.dart';
import 'network_caller.dart';
import '../utils/app_logger.dart';

class TelaService {
  /// Carrega a lista dinâmica de telas disponíveis do backend via /api/telas
  /// Retorna uma lista de Tela ou lista vazia em caso de erro
  static Future<List<Tela>> listarTelas() async {
    try {
      final NetworkResponse response = await NetworkCaller().getRequest(
        '${ApiLinks.baseUrl}/api/telas',
      );

      if (response.isSuccess && response.body != null) {
        // Extrai dados do envelope de resposta: {data: {dados: [...]}}
        final dados = response.body!['data']?['dados'] ?? response.body!['data'] ?? [];

        if (dados is List) {
          return dados
              .map((json) => Tela.fromJson(Map<String, dynamic>.from(json)))
              .toList();
        }
      }
    } catch (e) {
      L.e('TelaService.listarTelas: $e');
    }

    return [];
  }
}
