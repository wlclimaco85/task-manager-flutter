import 'package:flutter/material.dart';
import '../../../models/parceiro_model.dart';
import '../../../widgets/generic_detail_form_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show SecurityCheck, FieldConfigWindows, FieldType;
import '../certificado_empresa_screen.dart';

class WindowsParceiroDetailScreen extends StatelessWidget {
  final Parceiro item;
  final SecurityCheck hasPermission;

  const WindowsParceiroDetailScreen({super.key, required this.item, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    final id = item.id?.toString() ?? '';
    final parceiroId = item.id ?? 0;
    final parceiroNome = item.nome ?? item.razaoSocial ?? 'Parceiro';
    final empresaId = (item.empresa?.id)?.toString() ?? '';

    // Dados da sessão — disponível para uso futuro
    // final sessao = AuthUtility.userInfo?.login;

    return GenericDetailFormScreen(
      item: item.toJson(),
      telaNome: 'parceiro',
      hasPermission: hasPermission,
      relatedTabs: [
        // ── Logins — esconde tipoLogin e aplicativo, pré-popula parceiro ──
        RelatedGridTab(
          title: 'Logins',
          icon: Icons.person,
          telaNome: 'login',
          extraParams: {'parcId': id},
          fieldOverrides: [
            // Esconde tipoLogin — vem da sessão
            const FieldConfigWindows(
              label: 'Tipo Login',
              fieldName: 'tipoLogin',
              isInForm: false,
              isVisibleByDefault: false,
              enabled: false,
            ),
            // Esconde aplicativo — vem da sessão
            const FieldConfigWindows(
              label: 'Aplicativo',
              fieldName: 'aplicativo',
              isInForm: false,
              isVisibleByDefault: false,
              enabled: false,
            ),
            // Parceiro: disabled mas pré-populado com o parceiro atual
            FieldConfigWindows(
              label: 'Parceiro',
              fieldName: 'parceiro',
              displayFieldName: 'parceiro.nome',
              icon: Icons.person_outline,
              fieldType: FieldType.dropdown,
              dropdownOptions: parceiroId > 0
                  ? [{'value': parceiroId.toString(), 'label': parceiroNome}]
                  : [],
              dropdownValueField: 'value',
              dropdownDisplayField: 'label',
              dropdownSelectedValue: parceiroId > 0 ? parceiroId.toString() : null,
              isInForm: true,
              isFilterable: false,
              enabled: false, // disabled — valor fixo
            ),
          ],
        ),
        RelatedGridTab(
          title: 'Contas a Pagar',
          icon: Icons.money_off,
          telaNome: 'conta_pagar',
          extraParams: {'parceiro': id},
        ),
        RelatedGridTab(
          title: 'Contas a Receber',
          icon: Icons.attach_money,
          telaNome: 'conta_receber',
          extraParams: {'parceiroId': id},
        ),
        RelatedGridTab(
          title: 'Chamados',
          icon: Icons.support_agent,
          telaNome: 'chamado',
          extraParams: {'parceiroId': id},
        ),
        RelatedGridTab(
          title: 'Comunicados',
          icon: Icons.campaign,
          telaNome: 'comunicado',
          extraParams: {'empId': empresaId},
        ),
        // ── Certificado Digital do Parceiro ──────────────────────────────
        RelatedGridTab(
          title: 'Certificado Digital',
          icon: Icons.security,
          customWidget: parceiroId > 0
              ? CertificadoEmpresaScreen(
                  parceiroId: parceiroId,
                  empresaNome: parceiroNome,
                )
              : const Center(child: Text('ID do parceiro não disponível')),
        ),
        // ── Séries NF-e do Parceiro ──────────────────────────────────────
        RelatedGridTab(
          title: 'Séries NF-e',
          icon: Icons.format_list_numbered,
          telaNome: 'nfe_serie',
          extraParams: {'parcId': id},
        ),
      ],
    );
  }
}
