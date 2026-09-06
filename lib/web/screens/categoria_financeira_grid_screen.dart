import 'package:flutter/material.dart';
import '../../../models/categoria_financeira_model.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_tree_screen.dart';

class WebCategoriaFinanceiraGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebCategoriaFinanceiraGridScreen({
    super.key,
    required this.hasPermission,
  });

  @override
  Widget build(BuildContext context) {
    return GenericTreeScreen<CategoriaFinanceira>(
      title: 'Categorias Financeiras',
      fetchEndpoint: ApiLinks.allCategoriasFinanceiras,
      createEndpoint: ApiLinks.createCategoriaFinanceira,
      updateEndpoint: ApiLinks.updateCategoriaFinanceira(':id'),
      deleteEndpoint: ApiLinks.deleteCategoriaFinanceira(':id'),
      fromJson: (json) => CategoriaFinanceira.fromJson(json),
      toJson: (item) => item.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: CategoriaFinanceira.fieldConfigs,
      idFieldName: 'id',
      parentIdFieldName: 'parentId',
    );
  }
}
