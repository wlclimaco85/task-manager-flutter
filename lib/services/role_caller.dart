import 'package:task_manager_flutter/models/role_model.dart'; // Ajuste o caminho conforme necessário
import 'package:task_manager_flutter/utils/api_links.dart'; // Onde definiremos as URLs
import 'package:task_manager_flutter/models/network_response.dart';
import 'package:task_manager_flutter/services/network_caller.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';
class RoleCaller {
  Future<List<Role>> getRoles() async {
    List<Role>? roles = [];
    RolesModel model;
    try {
      final NetworkResponse response = await NetworkCaller().getRequest(
        ApiLinks.getAllRoles,
      );

      if (response.statusCode == 200 && response.body != null) {
        model = RolesModel.fromJson(response.body!);
        roles.addAll(model.roles ?? []);
      } else {
        throw Exception('Falha ao carregar roles: ${response.statusCode}');
      }
    } catch (e) {
      L.d('Erro: $e');
      throw Exception('Erro ao carregar roles: $e');
    }
    return roles;
  }

  Future<bool> associateRoleToLogin(int loginId, int roleId) async {
    try {
      final NetworkResponse response = await NetworkCaller().postRequest(
        ApiLinks.associateRoleToLogin(loginId, roleId),
        {"roleid": roleId},
        // Como é uma associação, não enviamos body, mas se a API exigir, ajuste aqui.
        // No exemplo, o endpoint é POST e não tem body.
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      L.d('Erro: $e');
      return false;
    }
  }

  Future<bool> removeRoleFromLogin(int loginId, int roleId) async {
    try {
      final NetworkResponse response = await NetworkCaller().deleteRequest(
        ApiLinks.removeRoleFromLogin(loginId, roleId),
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      L.d('Erro: $e');
      return false;
    }
  }

  /// Busca roles disponíveis filtradas por módulos contratados
  /// da empresa/parceiro informado.
  ///
  /// @param empresaId ID da empresa (prioridade baixa)
  /// @param parceiroId ID do parceiro (prioridade alta)
  /// @return List<Role> contendo apenas roles compatíveis
  Future<List<Role>> getRolesDisponiveis({
    int? empresaId,
    int? parceiroId,
  }) async {
    List<Role> roles = [];
    try {
      String url = ApiLinks.rolesDisponiveis;

      // Monta query string
      List<String> params = [];
      if (empresaId != null) params.add('empresaId=$empresaId');
      if (parceiroId != null) params.add('parceiroId=$parceiroId');
      if (params.isNotEmpty) url += '?' + params.join('&');

      final NetworkResponse response = await NetworkCaller().getRequest(url);

      if (response.statusCode == 200 && response.body != null) {
        // Resposta é List<Role> direto, não envolvida em "data"
        final body = response.body;
        List<dynamic> data = body is List ? body as List<dynamic> : [body];
        roles = data
            .map((r) => Role.fromJson(r as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 403) {
        // Anti-IDOR: usuário não tem acesso ao tenant informado
        throw Exception('Sem acesso ao tenant (403)');
      } else {
        throw Exception('Falha ao carregar roles: ${response.statusCode}');
      }
    } catch (e) {
      L.d('Erro ao buscar roles disponíveis: $e');
      // Fallback: não bloqueia, retorna vazio
      return [];
    }
    return roles;
  }
}
