import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/auth_screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen mostra header horizontal, funcionalidades e carrossel de noticias no desktop',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pump();

    // 1. Header Horizontal de Login
    expect(find.text('Portal do escritório para clientes'), findsWidgets);
    expect(find.text('Acessar'), findsOneWidget);
    expect(find.text('Esqueceu a senha?'), findsOneWidget);
    expect(find.text('Solicitar acesso'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));

    // 2. Módulos Inclusos na Grid
    expect(find.text('Chat com o escritorio'), findsOneWidget);
    expect(find.text('GED e documentos'), findsOneWidget);
    expect(find.text('Financeiro essencial'), findsOneWidget);
    expect(find.text('Abertura de chamados'), findsOneWidget);
    expect(find.text('Upload de extratos'), findsOneWidget);
    expect(find.text('Incluso'), findsWidgets);
    expect(find.textContaining('R\$ 99,90'), findsOneWidget);
    expect(find.textContaining('R\$ 199,90'), findsOneWidget);

    // 3. Carrossel de Notícias na Lateral
    expect(find.text('Últimas Notícias & Comunicados'), findsOneWidget);
  });

  testWidgets('LoginScreen adapta para mobile com layout responsivo',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pump();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('Acessar'), findsOneWidget);
    expect(find.text('Esqueceu a senha?'), findsOneWidget);
    expect(find.text('Solicitar acesso'), findsOneWidget);
    expect(find.text('Chat com o escritorio'), findsOneWidget);
    expect(find.text('GED e documentos'), findsOneWidget);
    expect(find.text('Abertura de chamados'), findsOneWidget);
    expect(find.text('Últimas Notícias & Comunicados'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
