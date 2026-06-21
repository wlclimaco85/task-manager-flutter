import '../models/regua_cobranca_model.dart';
import '../utils/api_links.dart';
import 'network_caller.dart';

class ReguaCobrancaException implements Exception {
  const ReguaCobrancaException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ReguaCobrancaService {
  ReguaCobrancaService({NetworkCaller? caller})
      : _caller = caller ?? NetworkCaller();

  final NetworkCaller _caller;

  Future<List<ReguaCobranca>> listarReguas() async {
    final response = await _caller.getRequest(ApiLinks.reguasCobranca);
    final items =
        _requireList(response.isSuccess, response.statusCode, response.body);
    return items.map(ReguaCobranca.fromJson).toList();
  }

  Future<ReguaCobranca> salvarRegua(ReguaCobranca regua) async {
    final response = regua.id == null
        ? await _caller.postRequest(ApiLinks.reguasCobranca, regua.toJson())
        : await _caller.putRequest(
            ApiLinks.reguaCobranca(regua.id!), regua.toJson());
    final body =
        _requireMap(response.isSuccess, response.statusCode, response.body);
    return ReguaCobranca.fromJson(_unwrapMap(body));
  }

  Future<List<CobrancaRegua>> listarPendencias() =>
      _listarCobrancas('pendencias');
  Future<List<CobrancaRegua>> listarHistorico() =>
      _listarCobrancas('historico');
  Future<List<CobrancaRegua>> listarFila() => _listarCobrancas('fila');

  Future<PainelReguaCobranca> carregarPainel() async {
    final response =
        await _caller.getRequest('${ApiLinks.cobrancasRegua}/painel');
    final body =
        _requireMap(response.isSuccess, response.statusCode, response.body);
    return PainelReguaCobranca.fromJson(_unwrapMap(body));
  }

  Future<List<CobrancaRegua>> _listarCobrancas(String recurso) async {
    final response =
        await _caller.getRequest('${ApiLinks.cobrancasRegua}/$recurso');
    final items =
        _requireList(response.isSuccess, response.statusCode, response.body);
    return items.map(CobrancaRegua.fromJson).toList();
  }

  Future<ExecucaoReguaResultado> executar() async {
    final response = await _caller.postRequest(
      '${ApiLinks.cobrancasRegua}/executar',
      const <String, dynamic>{},
    );
    if (!response.isSuccess) {
      throw ReguaCobrancaException(
          _errorMessage(response.statusCode, response.body));
    }
    final body = response.body;
    if (body == null) {
      throw const ReguaCobrancaException('Resposta inesperada do servidor.');
    }
    return ExecucaoReguaResultado.fromJson(_unwrapMap(body));
  }

  Future<void> reprocessar(int acaoId) async {
    final response = await _caller.postRequest(
      '${ApiLinks.cobrancasRegua}/acoes/$acaoId/reprocessar',
      const <String, dynamic>{},
    );
    _requireMap(response.isSuccess, response.statusCode, response.body);
  }

  List<Map<String, dynamic>> _requireList(
      bool success, int status, Map<String, dynamic>? body) {
    if (!success) throw ReguaCobrancaException(_errorMessage(status, body));
    final raw = body?['data'] ?? body?['content'] ?? body?['items'];
    if (raw is! List) {
      throw const ReguaCobrancaException('Resposta inesperada do servidor.');
    }
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Map<String, dynamic> _requireMap(
      bool success, int status, Map<String, dynamic>? body) {
    if (!success || body == null) {
      throw ReguaCobrancaException(_errorMessage(status, body));
    }
    return body;
  }

  Map<String, dynamic> _unwrapMap(Map<String, dynamic> body) {
    final raw = body['data'];
    return raw is Map ? Map<String, dynamic>.from(raw) : body;
  }

  String _errorMessage(int status, Map<String, dynamic>? body) {
    final detail = body?['message'] ?? body?['mensagem'] ?? body?['error'];
    return detail?.toString() ?? 'Falha na regua de cobranca (HTTP $status).';
  }
}
