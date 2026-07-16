import 'dart:io';

import '../models/tela_model.dart';
import '../models/network_response.dart';
import '../utils/api_links.dart';
import 'network_caller.dart';
import '../utils/app_logger.dart';

class TelaService {
  /// Carrega a lista dinâmica de telas disponíveis do backend via /api/telas
  /// Lança exceção em caso de erro para permitir que o caller diferencie
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
    } catch (e, st) {
      if (e is FormatException) {
        L.e('TelaService.listarTelas: JSON parsing failed', error: e, stackTrace: st);
      } else if (e is SocketException) {
        L.e('TelaService.listarTelas: Network error', error: e, stackTrace: st);
      } else {
        L.e('TelaService.listarTelas: Unknown error', error: e, stackTrace: st);
      }
      // Rethrow para que caller possa diferenciar erro vs sucesso vazio
      rethrow;
    }
  }
}
