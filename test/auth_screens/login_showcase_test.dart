import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/auth_screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen renderiza header horizontal, boxes e carrossel no desktop',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
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

    // Header horizontal no topo
    expect(find.text('ABRAÇO CONTABILIDADE'), findsOneWidget);
    expect(find.text('Acessar'), findsOneWidget);
    expect(find.text('Esqueceu a senha?'), findsOneWidget);
    expect(find.text('Solicitar acesso'), findsOneWidget);

    // Módulos / boxes de funcionalidades no topo
    expect(find.text('Módulos & Recursos Integrados'), findsOneWidget);
    expect(find.text('Chat & Atendimento'), findsOneWidget);
    expect(find.text('GED & Documentos'), findsOneWidget);

    // Carrossel lateral de últimas notícias
    expect(find.text('Últimas Notícias & Avisos'), findsOneWidget);

    // Desmonta para cancelar o timer do carrossel
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
