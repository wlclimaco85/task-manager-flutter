import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/searchable_dropdown.dart';

class _Host extends StatefulWidget {
  const _Host();
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String? serieId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SearchableDropdownField(
          label: 'Serie NFS-e',
          value: serieId,
          valueField: 'id',
          displayField: 'display',
          isRequired: true,
          onSearch: (q) async => [
            {'id': 7, 'serie': '001', 'display': '001 - Nota de servico'},
          ],
          onChanged: (v) => setState(() => serieId = v),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('serie escolhida via busca remota (onSearch) aparece no campo',
      (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '001');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('001 - Nota de servico'));
    await tester.pumpAndSettle();

    expect(find.text('001 - Nota de servico'), findsOneWidget);
    expect(find.text('— Selecione —'), findsNothing);
  });
}
