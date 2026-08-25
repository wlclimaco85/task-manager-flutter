import 'package:flutter/material.dart';
import '../../../services/network_caller.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_detail_form_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show SecurityCheck, FieldConfigWindows, FieldType;
import '../certificado_empresa_screen.dart';
import '../alvara_grid_screen.dart' show WindowsAlvaraGridScreen;
import '../login_grid_screen.dart' show WindowsLoginGridScreen;
import '../../../web/screens/comunicado_componente_screen.dart'
    show WebComunicadoGridComponentesScreen;
import 'empresa_modulos_tab.dart';

class WindowsEmpresaDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final SecurityCheck hasPermission;

  const WindowsEmpresaDetailScreen({
    super.key,
    required this.item,
    required this.hasPermission,
  });

  @override
  State<WindowsEmpresaDetailScreen> createState() =>
      _WindowsEmpresaDetailScreenState();
}

class _WindowsEmpresaDetailScreenState
    extends State<WindowsEmpresaDetailScreen> {
  late Map<String, dynamic> _item;

  // Mesmo padrao usado em web/empresa_detail_screen.dart e nas telas de
  // Parceiro (web+windows): trava a construcao do form ate o pre-fetch
  // terminar, para nao deixar a UI "piscar" com dado desatualizado e para
  // nao mascarar falha de rede como campo "vazio de verdade". O campo
  // 'modulosServico' e isInForm:false (nao vira multiselect no form -- os
  // modulos de servico da Empresa sao editados via aba "Modulos de
  // Cobranca" / EmpresaModulosTab, que ja tem seu proprio gate/catch
  // independente), entao este pre-fetch nao corrige nenhum bug real hoje;
  // mantido so por paridade/consistencia com o arquivo web equivalente.
  bool _modulosCarregados = false;
  String? _modulosErro;

  @override
  void initState() {
    super.initState();
    _item = Map<String, dynamic>.from(widget.item);
    _preCarregarModulos();
  }

  Future<void> _preCarregarModulos() async {
    final id = _item['id'];
    if (id == null) {
      if (mounted) setState(() => _modulosCarregados = true);
      return;
    }
    try {
      final r = await NetworkCaller().getRequest(
        '${ApiLinks.baseUrl}/api/empresa-modulo?empresaId=$id',
      );
      if (!r.isSuccess || r.body == null) {
        _modulosErro =
            'Nao foi possivel carregar Modulo Servicos (HTTP ${r.statusCode}).';
        return;
      }
      final raw = r.body is List
          ? r.body
          : (r.body?['data'] ?? r.body?['content'] ?? []);
      if (raw is! List) {
        _modulosErro = 'Resposta invalida ao carregar Modulo Servicos.';
        return;
      }
      final ids = raw
          .map((e) => e['id']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      _item['modulosServico'] = ids;
    } catch (e) {
      _modulosErro = 'Erro ao carregar Modulo Servicos: $e';
    } finally {
      if (mounted) setState(() => _modulosCarregados = true);
      if (_modulosErro != null) _avisarErroModulos();
    }
  }

  void _avisarErroModulos() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _modulosErro == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$_modulosErro Os modulos exibidos podem estar desatualizados.',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 6),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_modulosCarregados) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final id = _item['id']?.toString() ?? '';
    final empresaId = _item['id'] as int? ?? 0;
    final empresaNome = _item['nome']?.toString() ??
        _item['razaoSocial']?.toString() ??
        'Empresa';

    return GenericDetailFormScreen(
      item: _item,
      telaNome: 'empresa',
      hasPermission: widget.hasPermission,
      fieldOverrides: [
        const FieldConfigWindows(
          label: 'File Attachments',
          fieldName: 'fileAttachment',
          isInForm: false,
          isVisibleByDefault: false,
          enabled: false,
        ),
        const FieldConfigWindows(
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
        const FieldConfigWindows(
          label: 'Modulo Servicos',
          fieldName: 'modulosServico',
          isInForm: false,
          isVisibleByDefault: false,
          enabled: false,
          isFilterable: false,
        ),
      ],
      relatedTabs: [
        RelatedGridTab(
          title: 'Parceiros',
          icon: Icons.people,
          telaNome: 'parceiro',
          extraParams: {'empresa': id},
        ),
        RelatedGridTab(
          title: 'Logins',
          icon: Icons.person,
          telaNome: 'login',
          extraParams: {'empId': id},
          deleteEndpointOverride: '${ApiLinks.baseUrl}/api/logins/:id/inativar',
          additionalFormData: WindowsLoginGridScreen.additionalFormData,
          fieldOverrides: WindowsLoginGridScreen.fieldOverrides(),
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
          transformFormData:
              WebComunicadoGridComponentesScreen.transformFormData,
        ),
        RelatedGridTab(
          title: 'Certificado Digital',
          icon: Icons.security,
          customWidget: empresaId > 0
              ? CertificadoEmpresaScreen(
                  empresaId: empresaId,
                  empresaNome: empresaNome,
                )
              : const Center(child: Text('ID da empresa nao disponivel')),
        ),
        RelatedGridTab(
          title: 'Series NF-e',
          icon: Icons.format_list_numbered,
          telaNome: 'nfe_serie',
          extraParams: {'empId': id},
        ),
        RelatedGridTab(
          title: 'Alvaras',
          icon: Icons.verified_user,
          customWidget: empresaId > 0
              ? WindowsAlvaraGridScreen(
                  hasPermission: widget.hasPermission,
                  extraParams: {'empresa': id},
                  additionalFormData: {'empresa': id},
                  showAppBar: false,
                )
              : const Center(child: Text('ID da empresa nao disponivel')),
        ),
        RelatedGridTab(
          title: 'Modulos de Cobranca',
          icon: Icons.settings,
          customWidget: EmpresaModulosTab(
            empresaId: empresaId,
            onModulosChanged: (_) {},
          ),
        ),
      ],
    );
  }
}
