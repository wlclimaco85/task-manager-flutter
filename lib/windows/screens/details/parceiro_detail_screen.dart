import 'package:flutter/material.dart';
import '../../../models/auth_utility.dart';
import '../../../services/network_caller.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_detail_form_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show SecurityCheck, FieldConfigWindows, FieldType;
import '../../../web/screens/login_grid_screen.dart' show WebLoginGridScreen;
import '../../../web/screens/comunicado_componente_screen.dart'
    show WebComunicadoGridComponentesScreen;
import '../certificado_empresa_screen.dart';
import '../ged_arquivos_screen.dart';
import 'modulo_cobranca_screen.dart';

class WindowsParceiroDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final SecurityCheck hasPermission;

  const WindowsParceiroDetailScreen({
    super.key,
    required this.item,
    required this.hasPermission,
  });

  @override
  State<WindowsParceiroDetailScreen> createState() =>
      _WindowsParceiroDetailScreenState();
}

class _WindowsParceiroDetailScreenState
    extends State<WindowsParceiroDetailScreen> {
  late Map<String, dynamic> _item;

  // Bug de producao (card modulo_servicos vazio ao reabrir): GenericDetailFormScreen
  // le _item UMA UNICA VEZ (guardado por _initialized) para preencher os chips do
  // multiselect. _preCarregarModulos() e assincrono e antes preenchia _item bem depois
  // desse init ja ter rodado, entao o valor buscado do backend chegava tarde demais e
  // o campo ficava "Selecione..." pra sempre, mesmo com o dado certo salvo no backend.
  // Trava a construcao do form ate o fetch terminar, garantindo que _item ja chega
  // completo na primeira (e unica) inicializacao do GenericDetailFormScreen.
  bool _modulosCarregados = false;

  @override
  void initState() {
    super.initState();
    _item = Map<String, dynamic>.from(widget.item);
    _preCarregarModulos();
  }

  static bool _podeEditarModulosServico() {
    final email =
        (AuthUtility.userInfo?.login?.email ?? '').toLowerCase().trim();
    return email == 'wlclimaco@gmail.com';
  }

  static Future<List<Map<String, dynamic>>> _loadModulosServico() async {
    final r = await NetworkCaller()
        .getRequest('${ApiLinks.allModuloServico}?tamanho=200');
    if (!r.isSuccess || r.body == null) return [];
    final raw = r.body!['data']?['dados'] ??
        r.body!['data'] ??
        r.body!['content'] ??
        r.body;
    if (raw is! List) return [];
    return raw
        .map<Map<String, dynamic>>((e) {
          final label = e['descricao']?.toString() ??
              e['nome']?.toString() ??
              e['id']?.toString() ??
              '';
          return {'value': e['id']?.toString() ?? '', 'label': label};
        })
        .where((m) => m['value']!.isNotEmpty)
        .toList();
  }

  Future<void> _preCarregarModulos() async {
    final parceiroId = _item['id'];
    if (parceiroId == null) {
      if (mounted) setState(() => _modulosCarregados = true);
      return;
    }
    try {
      final r = await NetworkCaller().getRequest(
        '${ApiLinks.baseUrl}/api/parceiro-modulo?parceiroId=$parceiroId',
      );
      if (!r.isSuccess || r.body == null) return;
      final body = r.body;
      final raw =
          body is List ? body : (body?['data'] ?? body?['content'] ?? []);
      if (raw is! List) return;
      final ids = raw
          .map((e) => e['id']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .join(', ');
      _item['modulo_servicos'] = ids;
    } finally {
      if (mounted) setState(() => _modulosCarregados = true);
    }
  }

  static Map<String, dynamic> _limparPayloadParceiro(
      Map<String, dynamic> formData) {
    final status = formData['status'];
    if (status is Map) {
      formData['status'] =
          status['id']?.toString() ?? status['value']?.toString();
    }
    final regime = formData['regime'] ?? formData['regime_tributario'];
    final regimeId = _extractId(regime);
    if (regimeId != null) {
      formData['regime'] = {'id': regimeId};
      formData.remove('regime_tributario');
    }
    final tipos = formData['tiposParceiro'] ?? formData['tipo_parceiros'];
    if (tipos is List) {
      formData['tiposParceiro'] = tipos
          .map(_extractId)
          .whereType<String>()
          .map((id) => {'id': id})
          .toList();
      formData.remove('tipo_parceiros');
    }
    formData.remove('modulo_servicos');
    return formData;
  }

  static String? _extractId(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      final raw = value['id'] ?? value['value'];
      return raw?.toString();
    }
    final raw = value.toString().trim();
    return raw.isEmpty ? null : raw;
  }

  static Future<void> _salvarModulos(
      Map<String, dynamic> formData, Map<String, dynamic>? item) async {
    final parceiroId = formData['id'];
    if (parceiroId == null) return;
    final raw = formData['modulo_servicos'];
    final selected = raw is List
        ? raw
        : raw
            .toString()
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
    final modulos = selected
        .map((v) {
          if (v is Map) return int.tryParse(v['id']?.toString() ?? '');
          return int.tryParse(v.toString());
        })
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
    if (!_modulosCarregados) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final podeEditarModulos = _podeEditarModulosServico();
    final id = _item['id']?.toString() ?? '';
    final parceiroId = _item['id'] as int? ?? 0;
    final parceiroNome = _item['nome']?.toString() ??
        _item['razaoSocial']?.toString() ??
        'Parceiro';
    final empresaId =
        (_item['empresa'] is Map ? _item['empresa']['id'] : _item['empresa'])
                ?.toString() ??
            '';
    final empresaIdInt = int.tryParse(empresaId);
    final empresaNome = _item['empresa'] is Map
        ? (_item['empresa']['nome']?.toString() ??
            _item['empresa']['razaoSocial']?.toString() ??
            '')
        : '';

    return GenericDetailFormScreen(
      item: _item,
      telaNome: 'parceiro',
      hasPermission: widget.hasPermission,
      transformFormData: _limparPayloadParceiro,
      onAfterSave: podeEditarModulos ? _salvarModulos : null,
      fieldOverrides: [
        FieldConfigWindows(
          label: 'Modulo Servicos',
          fieldName: 'modulo_servicos',
          fieldType: FieldType.multiselect,
          dropdownFutureBuilder: _loadModulosServico,
          dropdownValueField: 'value',
          dropdownDisplayField: 'label',
          isInForm: true,
          isVisibleByDefault: false,
          enabled: podeEditarModulos,
          isFilterable: false,
        ),
      ],
      relatedTabs: [
        RelatedGridTab(
          title: 'Logins',
          icon: Icons.person,
          telaNome: 'login',
          extraParams: {'parcId': id, 'empresaId': empresaId},
          additionalFormData: WebLoginGridScreen.additionalFormData,
          // Fix card #427 (reincidencia): faltavam os overrides de Foto
          // (FieldType.file) e Roles (multiselect) que a tela direta ja
          // usa via fieldOverrides(). Sem eles o form aqui dentro de
          // Parceiro renderiza Foto como texto simples e usa a config
          // padrao (do banco) para os demais campos, causando ordem/tipo
          // diferentes e falha 400 ao salvar.
          fieldOverrides: [
            ...WebLoginGridScreen.fieldOverrides(),
            FieldConfigWindows(
              label: 'Empresa (Nome)',
              fieldName: 'empresa',
              displayFieldName: 'empresa.nome',
              icon: Icons.business,
              fieldType: FieldType.dropdown,
              dropdownOptions: empresaId.isNotEmpty
                  ? [
                      {
                        'id': empresaId,
                        'label': empresaNome.isNotEmpty
                            ? empresaNome
                            : 'Empresa #$empresaId'
                      }
                    ]
                  : [],
              dropdownValueField: 'id',
              dropdownDisplayField: 'label',
              dropdownSelectedValue: empresaId.isNotEmpty ? empresaId : null,
              isInForm: true,
              isFilterable: false,
              enabled: false,
            ),
            FieldConfigWindows(
              label: 'Parceiro',
              fieldName: 'parceiro',
              displayFieldName: 'parceiro.nome',
              icon: Icons.person_outline,
              fieldType: FieldType.dropdown,
              dropdownOptions: parceiroId > 0
                  ? [
                      {'value': parceiroId.toString(), 'label': parceiroNome}
                    ]
                  : [],
              dropdownValueField: 'value',
              dropdownDisplayField: 'label',
              dropdownSelectedValue:
                  parceiroId > 0 ? parceiroId.toString() : null,
              isInForm: true,
              isFilterable: false,
              enabled: false,
            ),
          ],
        ),
        RelatedGridTab(
          title: 'Contas a Pagar',
          icon: Icons.money_off,
          telaNome: 'conta_pagar',
          extraParams: {'parceiro': id, 'empresaId': empresaId},
        ),
        RelatedGridTab(
          title: 'Contas a Receber',
          icon: Icons.attach_money,
          telaNome: 'conta_receber',
          extraParams: {'parceiroId': id, 'empresaId': empresaId},
        ),
        RelatedGridTab(
          title: 'Chamados',
          icon: Icons.support_agent,
          telaNome: 'chamado',
          extraParams: {'parceiroId': id, 'empresaId': empresaId},
        ),
        RelatedGridTab(
          title: 'Comunicados',
          icon: Icons.campaign,
          telaNome: 'comunicado',
          extraParams: {'empId': empresaId, 'parceiroId': id},
          transformFormData:
              WebComunicadoGridComponentesScreen.transformFormData,
        ),
        RelatedGridTab(
          title: 'Certificado Digital',
          icon: Icons.security,
          customWidget: parceiroId > 0
              ? CertificadoEmpresaScreen(
                  parceiroId: parceiroId,
                  empresaNome: parceiroNome,
                )
              : const Center(child: Text('ID do parceiro nao disponivel')),
        ),
        RelatedGridTab(
          title: 'Series NF-e',
          icon: Icons.format_list_numbered,
          telaNome: 'nfe_serie',
          extraParams: {'parcId': id, 'empresaId': empresaId},
        ),
        RelatedGridTab(
          title: 'Cobranca de Modulos',
          icon: Icons.attach_money,
          customWidget: parceiroId > 0
              ? WindowsModuloCobrancaScreen(
                  parceiroId: parceiroId,
                  parceiroNome: parceiroNome,
                )
              : const Center(child: Text('ID do parceiro nao disponivel')),
        ),
        RelatedGridTab(
          title: 'GED',
          icon: Icons.folder_open,
          customWidget: parceiroId > 0
              ? GedArquivosScreen(
                  moduloOrigem: 'parceiro',
                  idOrigem: parceiroId,
                  nomeOrigem: parceiroNome,
                  empresaId: empresaIdInt,
                )
              : const Center(child: Text('ID do parceiro nao disponivel')),
        ),
      ],
    );
  }
}
