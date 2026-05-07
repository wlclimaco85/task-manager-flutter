import 'package:flutter/material.dart';
import '../../../widgets/generic_detail_form_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show SecurityCheck;
import '../certificado_empresa_screen.dart';

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
        // ── Certificado Digital ──────────────────────────────────────────
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
        // ── Séries NF-e ──────────────────────────────────────────────────
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
