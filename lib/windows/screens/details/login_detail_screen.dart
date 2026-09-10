import 'package:flutter/material.dart';
import '../../../models/login_model.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_detail_form_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show SecurityCheck, FieldType, FieldConfigWindows;
import '../../../services/network_caller.dart';

class WindowsLoginDetailScreen extends StatelessWidget {
  final Login item;
  final SecurityCheck hasPermission;

  const WindowsLoginDetailScreen({super.key, required this.item, required this.hasPermission});

  /// Carrega roles disponíveis filtradas por parceiroId/empresaId
  Future<List<Map<String, dynamic>>> _loadRolesDisponiveis(
    String? parceiroId,
    String? empresaId,
  ) async {
    try {
      String endpoint = ApiLinks.rolesDisponiveis;
      List<String> params = [];
      if (parceiroId?.isNotEmpty == true) {
        params.add('parceiroId=$parceiroId');
      }
      if (empresaId?.isNotEmpty == true) {
        params.add('empresaId=$empresaId');
      }
      if (params.isNotEmpty) {
        endpoint += '?' + params.join('&');
      }

      final response = await NetworkCaller().getRequest(endpoint);
      if (response.isSuccess && response.body is List) {
        return (response.body as List)
            .map((r) => r is Map<String, dynamic> ? r : <String, dynamic>{})
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginId = item.id?.toString() ?? '';
    final empresaId = item.empresa?.id?.toString() ?? '';
    final parceiroId = item.parceiro?.id?.toString() ?? '';

    final fieldOverrides = [
      FieldConfigWindows(
        fieldName: 'roles',
        label: 'Roles',
        fieldType: FieldType.multiselect,
        isRequired: false,
        dropdownValueField: 'id',
        dropdownDisplayField: 'description',
        dropdownFutureBuilder: () =>
            _loadRolesDisponiveis(parceiroId, empresaId),
      ),
    ];

    return GenericDetailFormScreen(
      item: item.toJson(),
      telaNome: 'login',
      hasPermission: hasPermission,
      fieldOverrides: fieldOverrides,
      relatedTabs: [
        RelatedGridTab(
          title: 'Roles',
          icon: Icons.security,
          telaNome: 'role',
          extraParams: {'loginId': loginId, 'empresaId': empresaId, 'parceiroId': parceiroId},
          // Usa endpoint com /boletobancos (extrai base do rolesDisponiveis)
          deleteEndpointOverride:
              '${ApiLinks.rolesDisponiveis.replaceAll('/api/role/disponiveis', '')}/api/logins/$loginId/roles/:id',
        ),
        RelatedGridTab(
          title: 'Setores',
          icon: Icons.business_center,
          telaNome: 'setor',
          extraParams: {'loginId': loginId, 'empresaId': empresaId, 'parceiroId': parceiroId},
          deleteEndpointOverride:
              '${ApiLinks.rolesDisponiveis.replaceAll('/api/role/disponiveis', '')}/api/login/$loginId/setores/:id',
        ),
        RelatedGridTab(
          title: 'Chamados',
          icon: Icons.support_agent,
          telaNome: 'chamado',
          extraParams: {'usuarioAberturaId': loginId, 'empresaId': empresaId, 'parceiroId': parceiroId},
        ),
      ],
    );
  }
}
