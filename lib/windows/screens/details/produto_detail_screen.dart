import 'package:flutter/material.dart';
import '../../../widgets/generic_detail_form_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show SecurityCheck;
import '../../../widgets/produto_notas_tab.dart';

class WindowsProdutoDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  final SecurityCheck hasPermission;

  const WindowsProdutoDetailScreen({
    super.key,
    required this.item,
    required this.hasPermission,
  });

  @override
  Widget build(BuildContext context) {
    final produtoId = item['id'] as int? ?? 0;

    return GenericDetailFormScreen(
      item: item,
      telaNome: 'produto',
      hasPermission: hasPermission,
      relatedTabs: [
        RelatedGridTab(
          title: 'Estoque',
          icon: Icons.inventory_2,
          customWidget: produtoId > 0
              ? ProdutoEstoqueTab(produtoId: produtoId)
              : const Center(child: Text('ID do produto nao disponivel')),
        ),
        RelatedGridTab(
          title: 'Notas de Compras',
          icon: Icons.shopping_cart,
          customWidget: produtoId > 0
              ? ProdutoNotasTab(
                  produtoId: produtoId,
                  tipoOperacao: TipoOperacaoNota.entrada,
                )
              : const Center(child: Text('ID do produto nao disponivel')),
        ),
        RelatedGridTab(
          title: 'Notas de Saídas',
          icon: Icons.local_shipping,
          customWidget: produtoId > 0
              ? ProdutoNotasTab(
                  produtoId: produtoId,
                  tipoOperacao: TipoOperacaoNota.saida,
                )
              : const Center(child: Text('ID do produto nao disponivel')),
        ),
      ],
    );
  }
}
