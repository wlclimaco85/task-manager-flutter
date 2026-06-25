import 'package:flutter/material.dart';

import '../../customization/dynamic_grid_dynamic_screen.dart';
import '../../customization/generic_grid/grid_models.dart';
import '../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../utils/api_links.dart';

class LoginGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  final VoidCallback? onUserBannerTapped;

  const LoginGridScreen({
    super.key,
    required this.hasPermission,
    this.onUserBannerTapped,
  });

  static Future<List<Map<String, dynamic>>> _loadRoles() async {
    final response =
        await NetworkCaller().getRequest('${ApiLinks.baseUrl}/api/role');
    if (!response.isSuccess || response.body == null) return [];
    final lista = _extractList(response);
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

  static Future<List<Map<String, dynamic>>> _loadEmpresas() async {
    final response = await NetworkCaller().getRequest(ApiLinks.allEmpresas);
    return _extractList(response)
        .map((e) => {'id': e['id'].toString(), 'label': e['nome'].toString()})
        .toList();
  }

  static Future<List<Map<String, dynamic>>> _loadParceiros() async {
    final response = await NetworkCaller().getRequest(ApiLinks.allParceiros);
    return _extractList(response)
        .map((e) => {'id': e['id'].toString(), 'label': e['nome'].toString()})
        .toList();
  }

  static Future<List<Map<String, dynamic>>> _loadAplicativos() async {
    final response =
        await NetworkCaller().getRequest('${ApiLinks.baseUrl}/api/aplicativo');
    return _extractList(response)
        .map((e) => {'id': e['id'].toString(), 'label': e['nome'].toString()})
        .toList();
  }

  static List<Map<String, dynamic>> _extractList(NetworkResponse response) {
    if (!response.isSuccess || response.body == null) return [];
    return _extractFrom(response.body);
  }

  static List<Map<String, dynamic>> _extractFrom(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      for (final key in ['data', 'dados', 'items', 'content', 'account']) {
        final nested = map[key];
        if (nested != null) {
          final extracted = _extractFrom(nested);
          if (extracted.isNotEmpty) return extracted;
        }
      }
      return [map];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      telaNome: 'login',
      hasPermission: hasPermission,
      onUserBannerTapped: onUserBannerTapped,
      fieldOverrides: [
        FieldConfig(
          label: 'Roles',
          fieldName: 'roles',
          icon: Icons.security,
          fieldType: FieldType.multiselect,
          dropdownFutureBuilder: _loadRoles,
          dropdownValueField: 'value',
          dropdownDisplayField: 'label',
          isInForm: true,
          isFilterable: false,
        ),
        FieldConfig(
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
        FieldConfig(
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
        FieldConfig(
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
        FieldConfig(
          label: 'Trocar senha no próximo login',
          fieldName: 'trocarSenhaProximoLogin',
          icon: Icons.lock_reset,
          fieldType: FieldType.boolean,
          isInForm: true,
          isFilterable: false,
        ),
      ],
    );
  }
}
