import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/web/screens/ged_arquivos_screen.dart';

void main() {
  testWidgets('GedArquivosScreen renderiza corretamente com filtros e acoes',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GedArquivosScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    // Deve exibir o cabeçalho do GED
    expect(find.textContaining('GED'), findsWidgets);
    expect(find.byIcon(Icons.filter_alt), findsOneWidget);
    expect(find.text('Novo Upload'), findsOneWidget);
  });
}
