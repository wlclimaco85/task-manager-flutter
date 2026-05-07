import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../customization/generic_grid_card.dart';
import '../../../models/conta_receber_model.dart';
import '../screens/baixa_dialog_receber.dart';
import '../screens/desfazer_baixa_dialog.dart';

class ContaReceberGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const ContaReceberGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericMobileGridScreen<ContaReceber>(
      title: "Contas a Receber",
      fetchEndpoint: ApiLinks.allContasReceber,
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
          icon: Icons.payment,
          label: 'Baixar',
          onPressed: (context, object) => _showBaixaDialog(context, object),
          isVisible: (object) => object.status == StatusConta.ABERTA,
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
      ],
      useUserBannerAppBar: true,
      paginationConfig: const PaginationConfig(
        defaultRowsPerPage: 10,
        availableRowsPerPage: [10, 25, 50],
      ),
      enableSearch: true,
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
}
