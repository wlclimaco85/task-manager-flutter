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
}
