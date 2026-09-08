import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/auth_screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen mostra vitrine do produto e mantem formulario',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pump();

    expect(find.text('Portal do escritorio para clientes'), findsOneWidget);
    expect(find.text('Chat com o escritorio'), findsWidgets);
    expect(find.text('GED e documentos'), findsWidgets);
    expect(find.text('Financeiro essencial'), findsWidgets);
    expect(find.text('Fiscal e NF-e'), findsWidgets);
    expect(find.text('Abertura de chamados'), findsWidgets);
    expect(find.text('Upload de extratos'), findsWidgets);
    expect(find.text('R\$ 99,90'), findsOneWidget);
    expect(find.text('R\$ 199,90'), findsOneWidget);
    expect(
      find.textContaining('fazemos um orcamento para criar a solucao'),
      findsOneWidget,
    );
    expect(find.text('Incluso'), findsWidgets);
    expect(find.text('Opcional'), findsWidgets);
    expect(find.text('Baixar na Play Store'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('LoginScreen fica rolavel e mostra vitrine no mobile',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pump();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('Chat com o escritorio'), findsWidgets);
    expect(find.text('GED e documentos'), findsWidgets);
    expect(find.text('Abertura de chamados'), findsWidgets);
    expect(find.text('Financeiro avancado'), findsWidgets);
    expect(find.text('R\$ 99,90'), findsOneWidget);
    expect(find.text('R\$ 199,90'), findsOneWidget);
    expect(
      find.textContaining('fazemos um orcamento para criar a solucao'),
      findsOneWidget,
    );
    expect(find.text('Baixar na Play Store'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
