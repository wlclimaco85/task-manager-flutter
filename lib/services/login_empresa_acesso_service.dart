import '../models/auth_utility.dart';
import '../models/empresa_acesso_model.dart';
import '../models/network_response.dart';
import '../utils/api_links.dart';
import 'network_caller.dart';

class LoginEmpresaAcessoService {
  final NetworkCaller _networkCaller;

  LoginEmpresaAcessoService({NetworkCaller? networkCaller})
      : _networkCaller = networkCaller ?? NetworkCaller();

  Future<List<EmpresaAcesso>> listarMeusAcessos() async {
    final response =
        await _networkCaller.getRequest(ApiLinks.loginEmpresasAcesso);
    final acessos = _parseList(response);
    AuthUtility.empresasAcesso = acessos;
    return acessos;
  }

  Future<bool> trocarEmpresaAtiva(int empresaId) async {
    final response = await _networkCaller.putRequest(
      ApiLinks.loginEmpresaAtiva,
      {'empresaId': empresaId},
    );
    if (!response.isSuccess || response.body == null) return false;
    final acesso = EmpresaAcesso.fromJson(
      Map<String, dynamic>.from(response.body as Map),
    );
    await AuthUtility.atualizarEmpresaAtiva(acesso.toEmpresa());
    await listarMeusAcessos();
    return true;
  }

  Future<bool> solicitarAcesso(int empresaId) async {
    final response = await _networkCaller.postRequest(
      ApiLinks.loginEmpresasAcessoSolicitar,
      {'empresaId': empresaId},
    );
    if (response.isSuccess) {
      await listarMeusAcessos();
    }
    return response.isSuccess;
  }

  Future<List<EmpresaAcesso>> listarPendentes({int? empresaId}) async {
    final url = empresaId == null
        ? ApiLinks.loginEmpresaAcessoPendentes
        : '${ApiLinks.loginEmpresaAcessoPendentes}?empresaId=$empresaId';
    return _parseList(await _networkCaller.getRequest(url));
  }

  Future<bool> aprovar(int acessoId) async {
    final response = await _networkCaller.putRequest(
      ApiLinks.loginEmpresaAcessoAprovar(acessoId),
      {},
    );
    return response.isSuccess;
  }

  Future<bool> negar(int acessoId) async {
    final response = await _networkCaller.putRequest(
      ApiLinks.loginEmpresaAcessoNegar(acessoId),
      {},
    );
    return response.isSuccess;
  }

  List<EmpresaAcesso> _parseList(NetworkResponse response) {
    if (!response.isSuccess || response.body == null) return [];
    final body = response.body;
    final raw = body is List
        ? body
        : body is Map<String, dynamic>
            ? (body['data'] is Map
                ? (body['data'] as Map)['dados']
                : body['data'])
            : null;
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => EmpresaAcesso.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
