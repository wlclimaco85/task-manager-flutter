import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show CustomAction, FieldConfigWindows, FieldType, SecurityCheck;
import '../../../customization/dynamic_grid_windows_screen.dart'
    hide SecurityCheck;
import '../../../models/login_model.dart';
import '../../../utils/api_links.dart';
import '../../../services/network_caller.dart';
import 'details/login_detail_screen.dart';
import 'role_dialog.dart';

class WindowsLoginGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WindowsLoginGridScreen({super.key, required this.hasPermission});

  static Future<List<Map<String, dynamic>>> loadRoles() async {
    final response = await NetworkCaller().getRequest('${ApiLinks.baseUrl}/api/role');
    if (response.isSuccess && response.body != null) {
      final body = response.body!;
      List lista = [];
      if (body['data'] is Map && body['data']['dados'] is List) {
        lista = body['data']['dados'] as List;
      } else if (body['data'] is List) {
        lista = body['data'] as List;
      } else if (body is List) {
        lista = body as List;
      }
      return lista
          .map((e) {
                final desc = e['description']?.toString();
                final key  = e['key']?.toString() ?? e['name']?.toString();
                final label = (desc != null && desc.isNotEmpty)
                    ? desc
                    : (key != null && key.isNotEmpty)
                        ? key
                        : 'Role #${e['id']}';
                return {'value': e['id'].toString(), 'label': label};
              })
          .toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> _loadEmpresas() async {
    final response = await NetworkCaller().getRequest(ApiLinks.allEmpresas);
    if (response.isSuccess && response.body != null) {
      final lista = response.body!['data']['dados'] as List;
      return lista
          .map((e) => {'id': e['id'].toString(), 'label': e['nome'].toString()})
          .toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> _loadParceiros() async {
    final response = await NetworkCaller().getRequest(ApiLinks.allParceiros);
    if (response.isSuccess && response.body != null) {
      final lista = response.body!['data']['dados'] as List;
      return lista
          .map((e) => {'id': e['id'].toString(), 'label': e['nome'].toString()})
          .toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> _loadAplicativos() async {
    final response = await NetworkCaller().getRequest('${ApiLinks.baseUrl}/api/aplicativo');
    if (response.isSuccess && response.body != null) {
      final lista = response.body!['data']['dados'] as List;
      return lista
          .map((e) => {'id': e['id'].toString(), 'label': e['nome'].toString()})
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Login>(
      telaNome: 'Login',
      hasPermission: hasPermission,
      fromJson: (json) => Login.fromJson(json),
      toJson: (a) => a.toJson(),
      extraParams: const {'skipTenantParceiro': 'true'},
      fieldOverrides: const [
        // Dropdowns reais — os campos FK (empresa_id, parceiro_id, aplicativo_id)
        // e datas automáticas são ocultados automaticamente pelo _convert
        FieldConfigWindows(
          label: 'Roles',
          fieldName: 'roles',
          icon: Icons.security,
          fieldType: FieldType.multiselect,
          dropdownFutureBuilder: WindowsLoginGridScreen.loadRoles,
          dropdownValueField: 'value',
          dropdownDisplayField: 'label',
          isInForm: true,
          isFilterable: false,
        ),
        FieldConfigWindows(
          label: 'Empresa',
          fieldName: 'empresa',
          displayFieldName: 'empresa.nome',
          icon: Icons.business,
          fieldType: FieldType.dropdown,
          dropdownFutureBuilder: _loadEmpresas,
          dropdownValueField: 'id',
          dropdownDisplayField: 'label',
          isInForm: true,
          isFilterable: true,
        ),
        FieldConfigWindows(
          label: 'Parceiro',
          fieldName: 'parceiro',
          displayFieldName: 'parceiro.nome',
          icon: Icons.person_outline,
          fieldType: FieldType.dropdown,
          dropdownFutureBuilder: _loadParceiros,
          dropdownValueField: 'id',
          dropdownDisplayField: 'label',
          isInForm: true,
          isFilterable: true,
        ),
        FieldConfigWindows(
          label: 'Aplicativo',
          fieldName: 'aplicativo',
          displayFieldName: 'aplicativo.nome',
          icon: Icons.apps,
          fieldType: FieldType.dropdown,
          dropdownFutureBuilder: _loadAplicativos,
          dropdownValueField: 'id',
          dropdownDisplayField: 'label',
          isInForm: true,
          isFilterable: true,
          isRequired: true,
        ),
        const FieldConfigWindows(
          label: 'Trocar senha no próximo login',
          fieldName: 'trocarSenhaProximoLogin',
          icon: Icons.lock_reset,
          fieldType: FieldType.boolean,
          isInForm: true,
          isFilterable: false,
        ),
      ],
      customActions: () => [
        CustomAction<Login>(
          icon: Icons.admin_panel_settings,
          label: 'Permissões',
          onPressed: (context, object) => _showBaixaDialog(context, object),
          isVisible: (chamado) => true,
        ),
      ],
      detailScreenBuilder: (item) => WindowsLoginDetailScreen(
        item: item,
        hasPermission: hasPermission,
      ),
    );
  }

  void _showBaixaDialog(BuildContext context, Login conta) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RoleDialog(loginId: conta.id ?? 0);
      },
    );
  }
}
