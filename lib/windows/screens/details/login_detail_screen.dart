import 'package:flutter/material.dart';
import '../../../models/login_model.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_detail_form_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show SecurityCheck, FieldType, FieldConfigWindows, FileConfig;
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
      // Bug de producao: o campo "Setores" auto-detectado pelo backend
      // (TelaGeneratorServiceImpl, via join table login_setor) aparecia como
      // multiselect editavel dentro da aba Cadastro, mas PUT/POST
      // /api/login nunca leem 'setores' do payload (LoginController so
      // processa email/senha/nome/cpfCnpj/tipoLogin/empresa/parceiro/
      // aplicativo/roles/ativo) -- qualquer edicao feita ali era descartada
      // silenciosamente, dando a impressao de "salvou" (200 OK) e sumindo ao
      // recarregar. A aba dedicada "Setores" abaixo (RelatedGridTab) e quem
      // gerencia essa associacao de verdade, via
      // POST/DELETE /api/login/{id}/setores -- por isso o campo duplicado
      // da aba Cadastro fica oculto aqui.
      const FieldConfigWindows(
        fieldName: 'setores',
        label: 'Setores',
        isInForm: false,
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
