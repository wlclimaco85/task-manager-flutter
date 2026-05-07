import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../customization/generic_grid_card.dart';
import '../../../models/conta_pagar_model.dart';
import '../screens/baixa_dialog.dart';
import '../screens/desfazer_baixa_dialog.dart';

class ContaPagarGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const ContaPagarGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericMobileGridScreen<ContaPagar>(
      title: "Contas a Pagar",
      fetchEndpoint: ApiLinks.allContasPagar,
      createEndpoint: ApiLinks.createContaPagar,
      updateEndpoint: ApiLinks.updateContaPagar(":id"),
      deleteEndpoint: ApiLinks.deleteContaPagar(":id"),
      fromJson: (json) => ContaPagar.fromJson(json),
      toJson: (obj) => obj.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: ContaPagar.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'audit.createdAt',
      customActions: () => [
        CustomAction<ContaPagar>(
          icon: Icons.payment,
          label: 'Baixar',
          onPressed: (context, object) => _showBaixaDialog(context, object),
          isVisible: (object) => object.status == StatusConta.ABERTA,
        ),
        CustomAction<ContaPagar>(
          icon: Icons.undo,
          label: 'Desfazer Baixa',
          isVisible: (obj) => obj.status == StatusConta.BAIXADA,
          onPressed: (context, object) {
            DesfazerBaixaDialog.show(
              context,
              tipo: 'pagar',
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

  void _showBaixaDialog(BuildContext context, ContaPagar conta) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BaixaDialog(conta: conta);
      },
    );
  }
}
