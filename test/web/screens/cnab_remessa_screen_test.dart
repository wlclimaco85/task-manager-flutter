import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/web/screens/cnab_remessa_screen.dart';
import 'package:task_manager_flutter/widgets/searchable_dropdown.dart';

void main() {
  testWidgets('CnabRemessaScreen renders SearchableDropdownField for conta bancaria',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: CnabRemessaScreen(),
    ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verifica que o AppBar foi renderizado
    expect(find.text('Envio EDI (Remessa CNAB)'), findsOneWidget);

    // Verifica que o SearchableDropdownField para conta bancaria esta presente
    expect(find.byType(SearchableDropdownField), findsOneWidget);

    // Verifica que o botao de gerar remessa esta presente
    expect(find.text('Gerar Arquivo de Remessa (EDI)'), findsOneWidget);

    // Botao deve estar desabilitado sem selecao de conta
    final buttonFinder = find.widgetWithText(ElevatedButton, 'Gerar Arquivo de Remessa (EDI)');
    expect(buttonFinder, findsOneWidget);
    final button = tester.widget<ElevatedButton>(buttonFinder);
    expect(button.onPressed, isNull);

    // Drena eventuais timers de log/erro de rede assíncronos
    await tester.pump(const Duration(seconds: 2));
  });
}
