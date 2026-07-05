import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:task_manager_flutter/widgets/dashboard_area/placeholder/dashboard_gme_screen.dart';
import 'package:task_manager_flutter/widgets/dashboard_area/placeholder/dashboard_projetos_screen.dart';
import 'package:task_manager_flutter/widgets/dashboard_area/placeholder/dashboard_precificacao_screen.dart';
import 'package:task_manager_flutter/widgets/dashboard_area/placeholder/dashboard_service_screen.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  group('Dashboard GME Screen', () {
    testWidgets('renderiza título Dashboard GME', (tester) async {
      await tester.pumpWidget(_wrap(const DashboardGmeScreen()));
      expect(find.text('Dashboard GME'), findsOneWidget);
    });

    testWidgets('exibe loading indicator no início', (tester) async {
      await tester.pumpWidget(_wrap(const DashboardGmeScreen()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('Dashboard Projetos Screen', () {
    testWidgets('renderiza título Dashboard Projetos', (tester) async {
      await tester.pumpWidget(_wrap(const DashboardProjetosScreen()));
      expect(find.text('Dashboard Projetos'), findsOneWidget);
    });

    testWidgets('exibe loading indicator no início', (tester) async {
      await tester.pumpWidget(_wrap(const DashboardProjetosScreen()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('Dashboard Precificação Screen', () {
    testWidgets('renderiza título Dashboard Precificação', (tester) async {
      await tester.pumpWidget(_wrap(const DashboardPrecificacaoScreen()));
      expect(find.text('Dashboard Precificação'), findsOneWidget);
    });

    testWidgets('exibe loading indicator no início', (tester) async {
      await tester.pumpWidget(_wrap(const DashboardPrecificacaoScreen()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('Dashboard Service Screen', () {
    testWidgets('renderiza título Dashboard Service Desk', (tester) async {
      await tester.pumpWidget(_wrap(const DashboardServiceScreen()));
      expect(find.text('Dashboard Service'), findsOneWidget);
    });

    testWidgets('exibe loading indicator no início', (tester) async {
      await tester.pumpWidget(_wrap(const DashboardServiceScreen()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
