import '../models/network_response.dart';
import '../services/network_caller.dart';
import '../utils/api_links.dart';
import '../utils/app_logger.dart';

/// Service para a ferramenta Query Builder.
/// Comunica com o backend em /api/ferramentas/query-builder/.
class QueryBuilderCaller {
  // ── Schemas ────────────────────────────────────────────────────────────

  /// Lista os schemas disponíveis no banco.
  static Future<List<dynamic>> listarSchemas() async {
    try {
      final NetworkResponse response =
          await NetworkCaller().getRequest(ApiLinks.queryBuilderSchemas);
      if (response.isSuccess && response.body != null) {
        return _extrairLista(response.body!);
      }
    } catch (e, st) {
      AppLogger.i.error('Erro ao listar schemas: $e', st);
    }
    return [];
  }

  // ── Tabelas ────────────────────────────────────────────────────────────

  /// Lista as tabelas do banco.
  static Future<List<dynamic>> listarTabelas() async {
    try {
      final NetworkResponse response =
          await NetworkCaller().getRequest(ApiLinks.queryBuilderTabelas);
      if (response.isSuccess && response.body != null) {
        return _extrairLista(response.body!);
      }
    } catch (e, st) {
      AppLogger.i.error('Erro ao listar tabelas: $e', st);
    }
    return [];
  }

  // ── Colunas ────────────────────────────────────────────────────────────

  /// Lista as colunas de [tabela] no [schema].
  static Future<List<dynamic>> listarColunas(
      String schema, String tabela) async {
    try {
      final url = ApiLinks.queryBuilderColunas(
          Uri.encodeComponent(schema), Uri.encodeComponent(tabela));
      final NetworkResponse response = await NetworkCaller().getRequest(url);
      if (response.isSuccess && response.body != null) {
        return _extrairLista(response.body!);
      }
    } catch (e, st) {
      AppLogger.i.error('Erro ao listar colunas: $e', st);
    }
    return [];
  }

  // ── Executar Query ─────────────────────────────────────────────────────

  /// Executa uma [sql] no banco, com paginação opcional.
  static Future<Map<String, dynamic>> executarQuery(
    String sql, {
    int pagina = 1,
    int tamanhoPagina = 50,
  }) async {
    try {
      final body = {
        'sql': sql,
        'pagina': pagina,
        'tamanhoPagina': tamanhoPagina,
      };
      final NetworkResponse response = await NetworkCaller()
          .postRequest(ApiLinks.queryBuilderExecutar, body);
      if (response.isSuccess && response.body != null) {
        return Map<String, dynamic>.from(response.body!);
      }
    } catch (e, st) {
      AppLogger.i.error('Erro ao executar query: $e', st);
    }
    return {};
  }

  // ── Atualizar Registro ─────────────────────────────────────────────────

  /// Atualiza um registro na [tabela].[schema] identificado por [pkColumn]=[pkValue].
  static Future<Map<String, dynamic>> atualizarRegistro(
    String tabela,
    String schema,
    String pkColumn,
    dynamic pkValue,
    Map<String, dynamic> colunas,
  ) async {
    try {
      final body = {
        'tabela': tabela,
        'schema': schema,
        'pkColumn': pkColumn,
        'pkValue': pkValue,
        'colunas': colunas,
      };
      final NetworkResponse response = await NetworkCaller()
          .postRequest(ApiLinks.queryBuilderAtualizar, body);
      if (response.isSuccess && response.body != null) {
        return Map<String, dynamic>.from(response.body!);
      }
    } catch (e, st) {
      AppLogger.i.error('Erro ao atualizar registro: $e', st);
    }
    return {};
  }

  // ── Queries Salvas ─────────────────────────────────────────────────────

  /// Lista todas as queries salvas.
  static Future<List<dynamic>> listarQueriesSalvas() async {
    try {
      final NetworkResponse response =
          await NetworkCaller().getRequest(ApiLinks.queryBuilderQueries);
      if (response.isSuccess && response.body != null) {
        return _extrairLista(response.body!);
      }
    } catch (e, st) {
      AppLogger.i.error('Erro ao listar queries salvas: $e', st);
    }
    return [];
  }

  /// Salva (ou atualiza) uma query. Se conter [id], faz PUT; caso contrário, POST.
  static Future<Map<String, dynamic>> salvarQuery(
      Map<String, dynamic> query) async {
    try {
      final NetworkResponse response = await NetworkCaller()
          .postRequest(ApiLinks.queryBuilderQueries, query);
      if (response.isSuccess && response.body != null) {
        return Map<String, dynamic>.from(response.body!);
      }
    } catch (e, st) {
      AppLogger.i.error('Erro ao salvar query: $e', st);
    }
    return {};
  }

  /// Deleta uma query pelo [id].
  static Future<bool> deletarQuery(int id) async {
    try {
      final NetworkResponse response =
          await NetworkCaller().deleteRequest(ApiLinks.queryBuilderQuery(id));
      return response.isSuccess;
    } catch (e, st) {
      AppLogger.i.error('Erro ao deletar query: $e', st);
      return false;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  /// Extrai uma lista do body de resposta, que pode vir como {data: [...]}
  /// ou diretamente como lista (convertida pelo NetworkResponse).
  static List<dynamic> _extrairLista(Map<String, dynamic> body) {
    if (body.containsKey('data') && body['data'] is List) {
      return body['data'] as List<dynamic>;
    }
    // Alguns endpoints podem retornar a lista diretamente
    // (NetworkResponse já faz o wrapping).
    return [];
  }
}
