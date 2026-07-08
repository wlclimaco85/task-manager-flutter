import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show CustomAction, FieldConfigWindows, FieldType, FileConfig, SecurityCheck;
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
    final response = await NetworkCaller()
        .getRequest('${ApiLinks.baseUrl}/api/role/disponiveis');
    if (response.isSuccess && response.body != null) {
      final dynamic body = response.body;
      List lista = [];
      if (body is List) {
        lista = body;
      } else if (body is Map && body['data'] is List) {
        lista = body['data'] as List;
      }
      return lista.map((e) {
        final desc = e['description']?.toString();
        final key = e['key']?.toString() ?? e['name']?.toString();
        final label = (desc != null && desc.isNotEmpty)
            ? desc
            : (key != null && key.isNotEmpty)
                ? key
                : 'Role #${e['id']}';
        return {'value': e['id'].toString(), 'label': label};
      }).toList();
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

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Login>(
      telaNome: 'Login',
      hasPermission: hasPermission,
      fromJson: (json) => Login.fromJson(json),
      toJson: (a) => a.toJson(),
      extraParams: const {'skipTenantParceiro': 'true'},
      additionalFormData: {
        'trocarSenhaProximoLogin': true,
        // Aplicativo fixo desta tela: sempre APP_CONTABILIDADE (id=1).
        'aplicativo': {'id': 1},
        // Usuário sempre precisa trocar a senha no próximo login.
        'mustChangePassword': true,
        // Expira em 10 anos — efetivamente sem expiração prática.
        'passwordResetExpires':
            DateTime.now().add(const Duration(days: 3650)).toIso8601String(),
      },
      transformFormData: (formData) {
        // Token de reset recebe o mesmo valor da senha (sem criptografia).
        formData['passwordResetToken'] = formData['senha'];
        return formData;
      },
      fieldOverrides: const [
        // Dropdowns reais — os campos FK (empresa_id, parceiro_id, aplicativo_id)
        // e datas automáticas são ocultados automaticamente pelo _convert
        FieldConfigWindows(
          label: 'Tipo Login',
          fieldName: 'tipoLogin',
          isInForm: false,
          isInGrid: false,
        ),
        FieldConfigWindows(
          label: 'Trocar Senha',
          fieldName: 'trocarSenhaProximoLogin',
          isInForm: false,
          isInGrid: false,
        ),
        FieldConfigWindows(
          label: 'Ativo',
          fieldName: 'ativo',
          isInForm: false,
          isInGrid: false,
        ),
        FieldConfigWindows(
          label: 'Criado em',
          fieldName: 'dhCreatedAt',
          isInForm: false,
          isInGrid: false,
        ),
        FieldConfigWindows(
          label: 'Atualizado em',
          fieldName: 'dhUpdatedAt',
          isInForm: false,
          isInGrid: false,
        ),
        FieldConfigWindows(
          label: 'Foto',
          fieldName: 'foto',
          icon: Icons.photo_camera,
          fieldType: FieldType.file,
          fileConfig: FileConfig(
            allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
            maxFileSize: 2 * 1024 * 1024,
          ),
          isInForm: true,
          isInGrid: false,
          isFilterable: false,
        ),
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
        // Aplicativo fixo (sempre APP_CONTABILIDADE, id=1) via additionalFormData.
        FieldConfigWindows(
          label: 'Aplicativo',
          fieldName: 'aplicativo',
          isInForm: false,
          isInGrid: false,
        ),
        FieldConfigWindows(
          label: 'Must Change Password',
          fieldName: 'mustChangePassword',
          isInForm: false,
          isInGrid: false,
        ),
        FieldConfigWindows(
          label: 'Password Reset Token',
          fieldName: 'passwordResetToken',
          isInForm: false,
          isInGrid: false,
        ),
        FieldConfigWindows(
          label: 'Password Reset Expires',
          fieldName: 'passwordResetExpires',
          isInForm: false,
          isInGrid: false,
        ),
        FieldConfigWindows(
          label: 'Setores',
          fieldName: 'setores',
          isInForm: false,
          isInGrid: false,
        ),
        // trocarSenhaProximoLogin oculto da UI: valor true por padrão na entidade
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
