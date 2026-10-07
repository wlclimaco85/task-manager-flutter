import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/searchable_dropdown.dart';

/// Reproduz o uso do campo "Serie" da NFS-e (itens estaticos, nullable):
/// a serie escolhida no popup precisa aparecer no campo, nunca "— Selecione —".
class _Host extends StatefulWidget {
  const _Host();
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String? serieId;
  final series = <Map<String, dynamic>>[
    {'id': '7', 'serie': '001', 'descricao': 'Nota de servico'},
    {'id': '8', 'serie': '002', 'descricao': 'Outra'},
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SearchableDropdownField(
          label: 'Série',
          value: series.any((o) => o['id'] == serieId) ? serieId : null,
          items: series
              .map((s) => <String, dynamic>{
                    'id': s['id'],
                    'nome': '${s['serie']} - ${s['descricao']}',
                  })
              .toList(),
          valueField: 'id',
          displayField: 'nome',
          nullable: true,
          nullLabel: '— Selecione —',
          onChanged: (v) => setState(() => serieId = v),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('serie escolhida no popup aparece no campo', (tester) async {
    await tester.pumpWidget(const _Host());
    expect(find.text('— Selecione —'), findsOneWidget);

    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('001 - Nota de servico'));
    await tester.pumpAndSettle();

    expect(find.text('001 - Nota de servico'), findsOneWidget);
    expect(find.text('— Selecione —'), findsNothing);
  });
}
