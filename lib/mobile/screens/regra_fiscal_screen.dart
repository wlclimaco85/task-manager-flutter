import 'package:flutter/material.dart';
import '../../web/screens/regra_fiscal_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileRegraFiscalScreen extends StatelessWidget {
  final bool Function(String)? hasPermission;

  const MobileRegraFiscalScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Regras Fiscais',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.RegraFiscalScreen(hasPermission: hasPermission ?? ((_) => true)),
      ),
    );
  }
}
