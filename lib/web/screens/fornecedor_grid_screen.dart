import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../utils/api_links.dart';

class WebFornecedorGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WebFornecedorGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'fornecedor',
      hasPermission: hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
      fetchEndpointOverride: ApiLinks.allFornecedores,
      createEndpointOverride: ApiLinks.createFornecedor,
      updateEndpointOverride: ApiLinks.updateFornecedor(''),
      deleteEndpointOverride: ApiLinks.deleteFornecedor(''),
    );
  }
}
