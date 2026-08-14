import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_detail_form_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show SecurityCheck, FieldConfigWindows, FieldType;
import '../certificado_empresa_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _item = Map<String, dynamic>.from(widget.item);
  }

  @override
  Widget build(BuildContext context) {
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
