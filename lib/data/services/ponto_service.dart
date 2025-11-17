import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import '../models/ponto_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

class PontoService {
  /// Ajuste aqui o endereço do seu backend
  static final String baseUrl = '${ApiLinks.baseUrl}/api/pontos';
  Future<PontoModel?> registrarPonto({
    required int parceiroId,
    required TipoRegistro tipo,
    String? observacao,
  }) async {
    final uri = Uri.parse("$baseUrl/registrar").replace(queryParameters: {
      "parceiroId": parceiroId.toString(),
      "tipo": tipo.apiValue,
      if (observacao != null && observacao.isNotEmpty) "observacao": observacao,
    });

    final response = await http.post(uri);

    if (response.statusCode == 200) {
      final body = json.decode(utf8.decode(response.bodyBytes));
      return PontoModel.fromJson(body);
    }

    return null;
  }

  Future<List<PontoModel>> listarPorDia({
    required int parceiroId,
    required DateTime data,
  }) async {
    final dataStr = data.toIso8601String().split("T")[0]; // yyyy-MM-dd
    final uri = Uri.parse("$baseUrl/listar/$parceiroId?data=$dataStr");

    final response = await http.get(uri);

    if (response.statusCode != 200) return [];

    final List body = json.decode(utf8.decode(response.bodyBytes));
    return body.map((e) => PontoModel.fromJson(e)).toList();
  }

  Future<double> calcularBancoHoras({
    required int parceiroId,
    required DateTime mesReferencia,
  }) async {
    final mesStr = mesReferencia.toIso8601String().split("T")[0];
    final uri =
        Uri.parse("$baseUrl/banco-horas/$parceiroId?mesReferencia=$mesStr");

    final response = await http.get(uri);

    if (response.statusCode != 200) return 0;

    return double.tryParse(response.body) ?? 0;
  }

  Future<Uint8List?> gerarRelatorioPdf({
    required int parceiroId,
    required DateTime inicio,
    required DateTime fim,
  }) async {
    final inicioStr = inicio.toIso8601String().split("T")[0];
    final fimStr = fim.toIso8601String().split("T")[0];

    final uri =
        Uri.parse("$baseUrl/pdf/$parceiroId?inicio=$inicioStr&fim=$fimStr");

    final response = await http.get(uri);

    if (response.statusCode != 200) return null;

    return response.bodyBytes;
  }
}
