import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/auth_screens/login_screen.dart';
import 'package:task_manager_flutter/utils/grid_texts.dart';

void main() {
  testWidgets('LoginScreen exibe botao Download Windows no rodape e na barra lateral',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Botao de download do Windows na lateral
    expect(find.byKey(const Key('login_sidebar_download_windows')), findsOneWidget);

    // Botao de download do Windows no rodape
    expect(find.byKey(const Key('login_footer_download_windows')), findsOneWidget);

    // Texto de download windows aparece na tela
    expect(find.text(GridTexts.downloadWindows), findsAtLeastNWidgets(1));

    // Botao da Play Store tambem continua presente
    expect(find.text('Baixar App na Play Store'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
