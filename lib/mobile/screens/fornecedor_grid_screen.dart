import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Fornecedores — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileFornecedorGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileFornecedorGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_fornecedor'),
      telaNome: 'fornecedor',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_fornecedor',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}
