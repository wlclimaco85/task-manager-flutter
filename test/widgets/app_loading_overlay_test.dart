import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/app_loading_overlay.dart';

void main() {
  testWidgets('AppLoadingOverlay renders title and custom message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppLoadingOverlay(
            title: 'Acessando o Sistema',
            message: 'Carregando módulos e permissões...',
          ),
        ),
      ),
    );

    expect(find.text('Acessando o Sistema'), findsOneWidget);
    expect(find.text('Carregando módulos e permissões...'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('AppLoadingOverlay in fullScreen mode renders correctly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppLoadingOverlay(
          isFullScreen: true,
          title: 'Carregando Sistema',
          message: 'Preparando Calendário...',
        ),
      ),
    );

    expect(find.text('Carregando Sistema'), findsOneWidget);
    expect(find.text('Preparando Calendário...'), findsOneWidget);
  });
}
