import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../customization/generic_grid_card.dart';
import '../../../models/conta_receber_model.dart';
import '../../../widgets/anexo_financeiro_widget.dart';
import '../../widgets/finance/billing_charge_dialog.dart';
import '../screens/baixa_dialog_receber.dart';
import '../screens/desfazer_baixa_dialog.dart';

class ContaReceberGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  final VoidCallback? onUserBannerTapped;
  // Fix card #453: filtro fixo de categoria financeira (tela Mensalidades).
  final int? categoriaFinanceiraIdFixa;
  final String? tituloOverride;

  const ContaReceberGridScreen({
    super.key,
    required this.hasPermission,
    this.onUserBannerTapped,
    this.categoriaFinanceiraIdFixa,
    this.tituloOverride,
  });

  @override
  Widget build(BuildContext context) {
    return GenericMobileGridScreen<ContaReceber>(
      title: tituloOverride ?? "Contas a Receber",
      fetchEndpoint: ApiLinks.allContasReceber,
      extraParams: categoriaFinanceiraIdFixa == null
          ? null
          : {'categoriaFinanceiraId': categoriaFinanceiraIdFixa.toString()},
      createEndpoint: ApiLinks.createContaReceber,
      updateEndpoint: ApiLinks.updateContaReceber(":id"),
      deleteEndpoint: ApiLinks.deleteContaReceber(":id"),
      fromJson: (json) => ContaReceber.fromJson(json),
      toJson: (obj) => obj.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: ContaReceber.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'audit.createdAt',
      customActions: () => [
        CustomAction<ContaReceber>(
          icon: Icons.receipt_long,
          label: 'Cobrar',
          onPressed: (context, object) => _showBillingDialog(context, object),
          isVisible: (object) => object.status == StatusConta.ABERTA,
        ),
        CustomAction<ContaReceber>(
          icon: Icons.price_check,
          label: 'Baixar',
          onPressed: (context, object) => _showBaixaDialog(context, object),
          isVisible: (object) =>
              object.status == StatusConta.ABERTA &&
              hasPermission('baixar'),
        ),
        CustomAction<ContaReceber>(
          icon: Icons.undo,
          label: 'Desfazer Baixa',
          isVisible: (obj) => obj.status == StatusConta.BAIXADA,
          onPressed: (context, object) {
            DesfazerBaixaDialog.show(
              context,
              tipo: 'receber',
              contaId: object.id!,
              dataBaixa: object.dataBaixa ?? DateTime.now(),
              valorBaixa: object.valorBaixa ?? object.valor,
              contaLabel: object.contaBaixa?.descricao ?? 'Conta não informada',
              formaPagamentoLabel:
                  object.formaPagamento?.nome ?? 'Forma não informada',
            );
          },
        ),
        CustomAction<ContaReceber>(
          icon: Icons.attach_file,
              label: 'Anexos',
          isVisible: (obj) => obj.id != null,
          onPressed: (context, object) => _showAnexos(context, object),
        ),
      ],
      useUserBannerAppBar: true,
      onUserBannerTapped: onUserBannerTapped,
      paginationConfig: const PaginationConfig(
        defaultRowsPerPage: 10,
        availableRowsPerPage: [10, 25, 50],
      ),
      enableSearch: true,
    );
  }

  void _showAnexos(BuildContext context, ContaReceber conta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (ctx, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: AnexoFinanceiroWidget(
            lancamentoId: conta.id!,
            lancamentoTipo: 'RECEBER',
            empresaId: conta.empresa.id,
          ),
        ),
      ),
    );
  }

  void _showBaixaDialog(BuildContext context, ContaReceber conta) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BaixaDialogReceber(conta: conta);
      },
    );
  }

  void _showBillingDialog(BuildContext context, ContaReceber conta) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BillingChargeDialog(conta: conta);
      },
    );
  }
}
