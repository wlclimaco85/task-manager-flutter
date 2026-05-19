import 'package:flutter/material.dart';
import '../../../widgets/generic_detail_form_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show SecurityCheck, FieldConfigWindows, FieldType;
import 'package:task_manager_flutter/web/screens/certificado_empresa_screen.dart';
import '../ged_arquivos_screen.dart';

class WebParceiroDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  final SecurityCheck hasPermission;

  const WebParceiroDetailScreen({super.key, required this.item, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    final id = item['id']?.toString() ?? '';
    final parceiroId = item['id'] as int? ?? 0;
    final parceiroNome = item['nome']?.toString() ?? item['razaoSocial']?.toString() ?? 'Parceiro';
    final empresaId = (item['empresa'] is Map ? item['empresa']['id'] : item['empresa'])?.toString() ?? '';

    // Dados da sessão — disponível para uso futuro (ex: pré-popular tipoLogin)
    // final sessao = AuthUtility.userInfo?.login;

    return GenericDetailFormScreen(
      item: item,
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
        // ── GED — documentos do parceiro (H5-21) ─────────────────────────
        RelatedGridTab(
          title: 'GED',
          icon: Icons.folder_open,
          customWidget: parceiroId > 0
              ? GedArquivosScreen(
                  moduloOrigem: 'parceiro',
                  idOrigem: parceiroId,
                  nomeOrigem: parceiroNome,
                )
              : const Center(child: Text('ID do parceiro não disponível')),
        ),
      ],
    );
  }
}
