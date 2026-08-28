import 'package:flutter/material.dart';
import '../../../models/login_model.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_detail_form_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show SecurityCheck, FieldType, FieldConfigWindows, FileConfig;
import '../../../services/network_caller.dart';

class WebLoginDetailScreen extends StatelessWidget {
  final Login item;
  final SecurityCheck hasPermission;

  const WebLoginDetailScreen(
      {super.key, required this.item, required this.hasPermission});

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

  Future<List<Map<String, dynamic>>> _loadSetores() async {
    try {
      final response = await NetworkCaller().getRequest(ApiLinks.allSetores);
      final body = response.body;
      if (!response.isSuccess || body == null) return [];

      final data = body['data'];
      final dynamic raw = data is Map ? (data['dados'] ?? data['items']) : data;
      if (raw is! List) return [];

      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
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
      FieldConfigWindows(
        fieldName: 'setores',
        label: 'Setores',
        fieldType: FieldType.multiselect,
        isRequired: false,
        dropdownValueField: 'id',
        dropdownDisplayField: 'descricao',
        dropdownFutureBuilder: _loadSetores,
      ),
      // Bug de producao: "Foto" caia no default do formulario generico
      // (campo de texto) e mostrava a representacao bruta do valor salvo
      // (ex.: "{id: 0, nome: }"). FieldType.file agora tem implementacao
      // real (GenericDetailFormScreen._buildFileField) -- mesmo padrao ja
      // usado no dialogo de criar/editar do grid (login_grid_screen.dart).
      const FieldConfigWindows(
        fieldName: 'foto',
        label: 'Foto',
        icon: Icons.photo_camera,
        fieldType: FieldType.file,
        fileConfig: FileConfig(
          allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
          maxFileSize: 2 * 1024 * 1024,
        ),
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
          extraParams: {
            'loginId': loginId,
            'empresaId': empresaId,
            'parceiroId': parceiroId
          },
          // "Excluir" nesta aba DESVINCULA a role do login (não apaga a role).
          // Backend: DELETE /api/logins/{loginId}/roles/{roleId} (removerRole).
          // Usa endpoint com /boletobancos (extrai base do rolesDisponiveis)
          deleteEndpointOverride:
              '${ApiLinks.rolesDisponiveis.replaceAll('/api/role/disponiveis', '')}/api/logins/$loginId/roles/:id',
        ),
        RelatedGridTab(
          title: 'Setores',
          icon: Icons.business_center,
          telaNome: 'setor',
          extraParams: {
            'loginId': loginId,
            'empresaId': empresaId,
            'parceiroId': parceiroId
          },
          deleteEndpointOverride:
              '${ApiLinks.rolesDisponiveis.replaceAll('/api/role/disponiveis', '')}/api/login/$loginId/setores/:id',
        ),
        RelatedGridTab(
          title: 'Chamados',
          icon: Icons.support_agent,
          telaNome: 'chamado',
          extraParams: {
            'usuarioAberturaId': loginId,
            'empresaId': empresaId,
            'parceiroId': parceiroId
          },
        ),
      ],
    );
  }
}
