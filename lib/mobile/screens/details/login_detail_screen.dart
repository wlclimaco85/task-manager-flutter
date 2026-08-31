import 'package:flutter/material.dart';
import '../../../models/login_model.dart';
import '../../../utils/api_links.dart';
import '../../../utils/login_session_sync.dart';
import '../../../widgets/generic_detail_form_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show SecurityCheck, FieldType, FieldConfigWindows, FileConfig;
import '../../../widgets/login_empresas_acesso_detail.dart';
import '../../../services/network_caller.dart';

int? _loginAcessoAsInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  if (value is Map) return _loginAcessoAsInt(value['id'] ?? value['value']);
  return null;
}

bool _loginAcessoHasParceiro(dynamic value) => _loginAcessoAsInt(value) != null;

class MobileLoginDetailScreen extends StatelessWidget {
  final Login item;
  final SecurityCheck hasPermission;

  const MobileLoginDetailScreen({
    super.key,
    required this.item,
    required this.hasPermission,
  });

  /// Carrega roles disponíveis filtradas por parceiroId/empresaId
  Future<List<Map<String, dynamic>>> _loadRolesDisponiveis(
    String? parceiroId,
    String? empresaId,
  ) async {
    try {
      // Constrói URL correta usando ApiLinks.rolesDisponiveis (com /boletobancos)
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

    // fieldOverride para dropdown de Roles filtrado por parceiro
    // Usa dropdownFutureBuilder para carregar via GET /api/role/disponiveis?parceiroId={parceiroId}
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
      onAfterSave: sincronizarSessaoLoginAtualAposSalvar,
      relatedTabs: [
        RelatedGridTab(
          title: 'Empresas com acesso',
          icon: Icons.business,
          customWidgetBuilder: (currentItem) => LoginEmpresasAcessoDetail(
            loginId: _loginAcessoAsInt(currentItem['id']),
            loginTemParceiro: _loginAcessoHasParceiro(
              currentItem['parceiro'] ??
                  currentItem['parceiroId'] ??
                  currentItem['parcId'],
            ),
          ),
        ),
        RelatedGridTab(
          title: 'Roles',
          icon: Icons.security,
          telaNome: 'role',
          extraParams: {
            'loginId': loginId,
            'empresaId': empresaId,
            'parceiroId': parceiroId
          },
          // Endpoint com /boletobancos (extrai base do rolesDisponiveis)
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
          // Endpoint com /boletobancos
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
