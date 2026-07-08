import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show CustomAction, FieldConfigWindows, FieldType, FileConfig, SecurityCheck;
import '../../../customization/dynamic_grid_windows_screen.dart'
    hide SecurityCheck;
import '../../../models/login_model.dart';
import '../../../utils/api_links.dart';
import '../../../services/network_caller.dart';
import '../../web/screens/details/login_detail_screen.dart';
import '../../web/screens/role_dialog.dart';

class WebLoginGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WebLoginGridScreen({super.key, required this.hasPermission});

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
      telaNome: 'login',
      hasPermission: hasPermission,
      fromJson: (json) => Login.fromJson(json),
      toJson: (a) => a.toJson(),
      additionalFormData: const {
        'trocarSenhaProximoLogin': true,
        // Aplicativo fixo desta tela: sempre APP_CONTABILIDADE (id=1).
        'aplicativo': {'id': 1},
      },
      // mustChangePassword / passwordResetToken / passwordResetExpires são
      // derivados pelo backend a cada troca de senha (ver LoginController) —
      // não precisam mais ser calculados/enviados pelo Flutter.
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
          dropdownFutureBuilder: WebLoginGridScreen.loadRoles,
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
      detailScreenBuilder: (item) => WebLoginDetailScreen(
        item: item,
        hasPermission: hasPermission,
      ),
    );
  }

  void _showBaixaDialog(BuildContext context, Login conta) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return WebRoleDialog(loginId: conta.id ?? 0);
      },
    );
  }
}
