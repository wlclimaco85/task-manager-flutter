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

  static Future<Map<String, dynamic>> _prePopularModulos(Map<String, dynamic> itemMap) async {
    final parceiroId = itemMap['id'];
    if (parceiroId == null) return itemMap;
    final r = await NetworkCaller().getRequest(
      '${ApiLinks.baseUrl}/api/parceiro-modulo?parceiroId=$parceiroId',
    );
    if (!r.isSuccess || r.body == null) return itemMap;
    final body = r.body;
    final raw = body is List ? body : (body?['data'] ?? body?['content'] ?? []);
    if (raw is! List) return itemMap;
    final ids = raw.map((e) => e['id']?.toString() ?? '').where((s) => s.isNotEmpty).join(', ');
    return {...itemMap, 'modulosServico': ids};
  }

  /// Persiste os módulos selecionados após salvar o parceiro.
  /// Envia formato {parceiroId, modulos:[{id, valor}]} para o backend gerar
  /// ContaReceber automaticamente em módulos novos com valor > 0.
  static Future<void> _salvarModulos(Map<String, dynamic> formData, Map<String, dynamic>? item) async {
    final parceiroId = formData['id'];
    if (parceiroId == null) return;
    final raw = formData['modulosServico'] as String? ?? '';
    final modulos = raw
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .map((id) => {'id': id, 'valor': 0})
        .toList();
    await NetworkCaller().postRequest(
      '${ApiLinks.baseUrl}/api/parceiro-modulo',
      {'parceiroId': parceiroId, 'modulos': modulos},
    );
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
          prefetchExtraFields: _prePopularModulos,
          onAfterSave: _salvarModulos,
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
