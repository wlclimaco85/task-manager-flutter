import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../services/network_caller.dart';
import '../../../widgets/generic_detail_form_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show SecurityCheck, FieldConfigWindows, FieldType;
import '../certificado_empresa_screen.dart';
import '../login_grid_screen.dart' show WebLoginGridScreen;

class WebEmpresaDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  final SecurityCheck hasPermission;

  const WebEmpresaDetailScreen({super.key, required this.item, required this.hasPermission});

  static Future<List<Map<String, dynamic>>> _loadTiposParceiro() async {
    final r = await NetworkCaller().getRequest(ApiLinks.allTipoParceiro);
    if (!r.isSuccess || r.body == null) return [];
    final raw = r.body!['data']?['dados'] ?? r.body!['data'] ?? r.body!['content'] ?? r.body;
    if (raw is! List) return [];
    return raw.map<Map<String, dynamic>>((e) {
      final label = e['descricao']?.toString() ?? e['nome']?.toString() ?? e['id']?.toString() ?? '';
      return {'value': e['id']?.toString() ?? '', 'label': label};
    }).where((m) => m['value']!.isNotEmpty).toList();
  }

  static Future<List<Map<String, dynamic>>> _loadModulosServico() async {
    final r = await NetworkCaller().getRequest(ApiLinks.allModuloServico);
    if (!r.isSuccess || r.body == null) return [];
    final raw = r.body!['data']?['dados'] ?? r.body!['data'] ?? r.body!['content'] ?? r.body;
    if (raw is! List) return [];
    return raw.map<Map<String, dynamic>>((e) {
      final label = e['descricao']?.toString() ?? e['nome']?.toString() ?? e['id']?.toString() ?? '';
      return {'value': e['id']?.toString() ?? '', 'label': label};
    }).where((m) => m['value']!.isNotEmpty).toList();
  }

  // ── Módulos do PARCEIRO (campo "Modulo Servicos" — card za49Y7Eq) ────────
  // O campo é orfao hoje: a entidade Parceiro nao tem "modulosServico", e o
  // backend (FAIL_ON_UNKNOWN_PROPERTIES=false) ignora silenciosamente esse
  // campo no save. O vinculo real e via tabela M:N (ParceiroModuloController,
  // /api/parceiro-modulo) — pre-popula e persiste por fora do save principal.

  // Baseline dos módulos confirmados pelo prefetch, por parceiroId. O POST
  // /api/parceiro-modulo é um REPLACE destrutivo no backend (DELETE todos +
  // INSERT de novo, zerando 'valor' de módulos não reenviados em 'valores')
  // — só dispara quando o conjunto de módulos REALMENTE muda em relação ao
  // que foi confirmado carregado, nunca "porque o usuário salvou o form"
  // (ex.: editou só o campo Ambiente). Sem baseline confirmada (prefetch
  // falhou ou nunca rodou) o save é pulado: melhor não persistir nada do que
  // apagar vínculos reais com base num campo que o form não confirmou ter
  // carregado certo.
  static final Map<int, Set<int>> _modulosBaselineConfirmada = {};

  static Future<Map<String, dynamic>> _prefetchModulosDoParceiro(
      Map<String, dynamic> item) async {
    final parceiroId = _asInt(item['id']);
    if (parceiroId == null) return {};
    final r = await NetworkCaller()
        .getRequest('${ApiLinks.parceiroModulo}?parceiroId=$parceiroId');
    if (!r.isSuccess || r.body == null) return {};
    // NetworkResponse._toMap envolve resposta de array bruto em {'data': [...]}
    final raw = r.body!['data'];
    if (raw is! List) return {};
    final modulos = raw.whereType<Map>().toList();
    _modulosBaselineConfirmada[parceiroId] =
        modulos.map((m) => _asInt(m['id'])).whereType<int>().toSet();
    return {'modulosServico': modulos};
  }

  static Future<void> _salvarModulosDoParceiro(
      Map<String, dynamic> formData, Map<String, dynamic>? item) async {
    // So funciona em EDICAO (item != null): no CREATE o backend ainda nao
    // devolveu o id do novo parceiro pro formData neste ponto. Quem criar um
    // parceiro e quiser modulos precisa reabrir o registro pra editar.
    final parceiroId = _asInt(item?['id']);
    if (parceiroId == null) return;

    final baseline = _modulosBaselineConfirmada[parceiroId];
    if (baseline == null) return;

    final raw = formData['modulosServico'];
    final moduloIds = <int>[];
    if (raw is List) {
      for (final e in raw) {
        final id = e is Map ? _asInt(e['id']) : _asInt(e);
        if (id != null) moduloIds.add(id);
      }
    }
    final novoSet = moduloIds.toSet();
    if (novoSet.length == baseline.length && novoSet.containsAll(baseline)) {
      return;
    }

    await NetworkCaller().postRequest(
      ApiLinks.parceiroModulo,
      {'parceiroId': parceiroId, 'moduloIds': moduloIds},
    );
    _modulosBaselineConfirmada[parceiroId] = novoSet;
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  @override
  Widget build(BuildContext context) {
    final id = item['id']?.toString() ?? '';
    final empresaId = item['id'] as int? ?? 0;
    final empresaNome = item['nome']?.toString() ?? item['razaoSocial']?.toString() ?? 'Empresa';

    return GenericDetailFormScreen(
      item: item,
      telaNome: 'empresa',
      hasPermission: hasPermission,
      fieldOverrides: const [
        // fileAttachment: dropdown FK que envia "" quando vazio → 500 no backend
        // Ocultado do formulário — upload de arquivo tem tela própria
        FieldConfigWindows(
          label: 'File Attachments',
          fieldName: 'fileAttachment',
          isInForm: false,
          isVisibleByDefault: false,
          enabled: false,
        ),
        // Ambiente: inteiro 1=Produção / 2=Homologação — exibir label
        FieldConfigWindows(
          label: 'Ambiente',
          fieldName: 'ambiente',
          icon: Icons.cloud_outlined,
          fieldType: FieldType.dropdown,
          dropdownOptions: [
            {'value': '1', 'label': 'Produção'},
            {'value': '2', 'label': 'Homologação'},
          ],
          dropdownValueField: 'value',
          dropdownDisplayField: 'label',
          isInForm: true,
        ),
      ],
      relatedTabs: [
        RelatedGridTab(
          title: 'Parceiros',
          icon: Icons.people,
          telaNome: 'parceiro',
          extraParams: {'empresa': id},
          prefetchExtraFields: _prefetchModulosDoParceiro,
          onAfterSave: _salvarModulosDoParceiro,
          fieldOverrides: [
            // Ambiente NFS-e do parceiro: enum PRODUCAO/HOMOLOGACAO
            const FieldConfigWindows(
              label: 'Ambiente',
              fieldName: 'ambiente',
              icon: Icons.cloud_outlined,
              fieldType: FieldType.dropdown,
              dropdownOptions: [
                {'value': 'PRODUCAO', 'label': 'Produção'},
                {'value': 'HOMOLOGACAO', 'label': 'Homologação'},
              ],
              dropdownValueField: 'value',
              dropdownDisplayField: 'label',
              isInForm: true,
            ),
            // Tipos de parceiro (multiselect M:N)
            FieldConfigWindows(
              label: 'Tipo Parceiros',
              fieldName: 'tiposParceiro',
              icon: Icons.category_outlined,
              fieldType: FieldType.multiselect,
              dropdownFutureBuilder: _loadTiposParceiro,
              dropdownValueField: 'value',
              dropdownDisplayField: 'label',
              isInForm: true,
              isFilterable: false,
            ),
            // Módulos de serviço contratados (multiselect M:N via parceiro_modulo)
            FieldConfigWindows(
              label: 'Modulo Servicos',
              fieldName: 'modulosServico',
              icon: Icons.settings_outlined,
              fieldType: FieldType.multiselect,
              dropdownFutureBuilder: _loadModulosServico,
              dropdownValueField: 'value',
              dropdownDisplayField: 'label',
              isInForm: true,
              isFilterable: false,
            ),
          ],
        ),
        RelatedGridTab(
          title: 'Logins',
          icon: Icons.person,
          telaNome: 'login',
          extraParams: {'empId': id},
          // "Excluir" nesta aba INATIVA o login (soft-delete), não apaga.
          // Backend: DELETE /api/logins/{id}/inativar (inativarLogin).
          deleteEndpointOverride: '${ApiLinks.baseUrl}/api/logins/:id/inativar',
          fieldOverrides: const [
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
          ],
        ),
        RelatedGridTab(
          title: 'Contas a Pagar',
          icon: Icons.money_off,
          telaNome: 'conta_pagar',
          extraParams: {'empresa': id},
        ),
        RelatedGridTab(
          title: 'Contas a Receber',
          icon: Icons.attach_money,
          telaNome: 'conta_receber',
          extraParams: {'empresaId': id},
        ),
        RelatedGridTab(
          title: 'Chamados',
          icon: Icons.support_agent,
          telaNome: 'chamado',
          extraParams: {'empresaId': id},
        ),
        RelatedGridTab(
          title: 'Comunicados',
          icon: Icons.campaign,
          telaNome: 'comunicado',
          extraParams: {'empId': id},
        ),
        RelatedGridTab(
          title: 'Certificado Digital',
          icon: Icons.security,
          customWidget: empresaId > 0
              ? CertificadoEmpresaScreen(
                  empresaId: empresaId,
                  empresaNome: empresaNome,
                )
              : const Center(child: Text('ID da empresa não disponível')),
        ),
        RelatedGridTab(
          title: 'Séries NF-e',
          icon: Icons.format_list_numbered,
          telaNome: 'nfe_serie',
          extraParams: {'empId': id},
        ),
      ],
    );
  }
}
