import 'package:flutter/material.dart';
import '../../../widgets/generic_detail_form_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show SecurityCheck, FieldConfigWindows, FieldType;
import 'package:task_manager_flutter/web/screens/certificado_empresa_screen.dart';
import '../ged_arquivos_screen.dart';
import '../login_grid_screen.dart' show WebLoginGridScreen;
import '../comunicado_componente_screen.dart'
    show WebComunicadoGridComponentesScreen;
import 'modulo_cobranca_screen.dart';

class WebParceiroDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  final SecurityCheck hasPermission;

  const WebParceiroDetailScreen(
      {super.key, required this.item, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    final id = item['id']?.toString() ?? '';
    final parceiroId = item['id'] as int? ?? 0;
    final parceiroNome = item['nome']?.toString() ??
        item['razaoSocial']?.toString() ??
        'Parceiro';
    final empresaId =
        (item['empresa'] is Map ? item['empresa']['id'] : item['empresa'])
                ?.toString() ??
            '';
    final empresaIdInt = int.tryParse(empresaId);
    final empresaNome = item['empresa'] is Map
        ? (item['empresa']['nome']?.toString() ??
            item['empresa']['razaoSocial']?.toString() ??
            '')
        : '';

    return GenericDetailFormScreen(
      item: item,
      telaNome: 'parceiro',
      hasPermission: hasPermission,
      relatedTabs: [
        RelatedGridTab(
          title: 'Logins',
          icon: Icons.person,
          telaNome: 'login',
          extraParams: {'parcId': id, 'empresaId': empresaId},
          additionalFormData: WebLoginGridScreen.additionalFormData,
          // Fix card #427 (reincidencia): faltavam os overrides de Foto
          // (FieldType.file) e Roles (multiselect) que a tela direta
          // WebLoginGridScreen ja usa via fieldOverrides(). Sem eles o
          // form aqui dentro de Parceiro renderiza Foto como texto simples
          // e usa a config padrao (do banco) para os demais campos,
          // causando ordem/tipo diferentes e falha 400 ao salvar.
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
                      {'id': empresaId, 'label': empresaNome.isNotEmpty ? empresaNome : 'Empresa #$empresaId'}
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
          transformFormData: WebComunicadoGridComponentesScreen.transformFormData,
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
          extraParams: {'parcId': id, 'empresaId': empresaId},
        ),
        // ── Cobrança de Módulos ───────────────────────────────────────
        RelatedGridTab(
          title: 'Cobrança de Módulos',
          icon: Icons.attach_money,
          customWidget: parceiroId > 0
              ? ModuloCobrancaScreen(
                  parceiroId: parceiroId,
                  parceiroNome: parceiroNome,
                )
              : const Center(child: Text('ID do parceiro não disponível')),
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
                  empresaId: empresaIdInt,
                )
              : const Center(child: Text('ID do parceiro não disponível')),
        ),
      ],
    );
  }
}
