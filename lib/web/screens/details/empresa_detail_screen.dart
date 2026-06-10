import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_detail_form_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show SecurityCheck, FieldConfigWindows, FieldType;
import '../certificado_empresa_screen.dart';
import '../login_grid_screen.dart' show WebLoginGridScreen;

class WebEmpresaDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  final SecurityCheck hasPermission;

  const WebEmpresaDetailScreen({super.key, required this.item, required this.hasPermission});

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
