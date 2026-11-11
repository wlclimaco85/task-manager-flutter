import 'package:flutter/material.dart';

import '../../widgets/dashboard_construtor_view.dart';
import '../../widgets/dashboards_personalizados_view.dart';

/// Dashboards no Mobile: a mesma tela de Web/Windows, em coluna vertical.
class MobileDashboardsPersonalizadosScreen extends StatelessWidget {
  const MobileDashboardsPersonalizadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboards')),
      body: const SafeArea(child: DashboardsPersonalizadosView()),
    );
  }
}

/// Construtor de Dashboards no Mobile (MASTER).
class MobileDashboardConstrutorScreen extends StatelessWidget {
  const MobileDashboardConstrutorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Construtor de Dashboards')),
      body: const SafeArea(child: DashboardConstrutorView()),
    );
  }
}
