import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/auth_screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen renderiza header horizontal, vitrine de modulos e flash news',
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

    // Header horizontal no topo
    expect(find.text('ABRAÇO CONTABILIDADE'), findsOneWidget);
    expect(find.text('Acessar'), findsOneWidget);
    expect(find.text('Esqueceu a senha?'), findsOneWidget);
    expect(find.text('Solicitar acesso'), findsOneWidget);

    // Módulos inclusos (Imagem 2)
    expect(find.text('Já vem no sistema'), findsOneWidget);
    expect(find.text('Chat com o escritório'), findsOneWidget);
    expect(find.text('GED e documentos'), findsOneWidget);
    expect(find.text('Calendário financeiro'), findsOneWidget);

    // Banner de preços (Imagem 2)
    expect(find.text('Módulo contratado'), findsOneWidget);
    expect(find.text('Pacote completo'), findsOneWidget);

    // Módulos opcionais (Imagem 2)
    expect(find.text('Módulos que podem ser contratados'), findsOneWidget);
    expect(find.text('Fiscal e NF-e'), findsOneWidget);
    expect(find.text('GME'), findsOneWidget);

    // Flash News lateral (Imagem 3)
    expect(find.text('FLASH NEWS'), findsOneWidget);
    expect(find.text('NOTÍCIAS'), findsOneWidget);

    // Desmonta
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
