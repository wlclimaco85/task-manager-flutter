import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_flutter/mobile/screens/nfe_list_screen.dart';
import 'package:task_manager_flutter/models/nfe/nfe_exceptions.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/providers/nfe_notifier.dart';

import '../helpers/fake_nfe_repository.dart';
import '../helpers/nfe_fixtures.dart';

Future<void> _pumpTela(WidgetTester tester, NfeNotifier notifier) {
  return tester.pumpWidget(
    ChangeNotifierProvider<NfeNotifier>.value(
      value: notifier,
      child: const MaterialApp(home: NfeListScreen()),
    ),
  );
}

void main() {
  late FakeNfeRepository repository;
  late NfeNotifier notifier;

  setUp(() {
    repository = FakeNfeRepository();
    notifier = NfeNotifier(repository);
  });

  testWidgets('mostra um card para cada NFe carregada', (tester) async {
    repository.nfesParaListar = [
      NfeModel.fromJson(nfeJson(1)),
      NfeModel.fromJson(nfeJson(2)),
    ];
    await notifier.listarNfe();

    await _pumpTela(tester, notifier);
    await tester.pumpAndSettle();

    expect(find.text('NFe #000001'), findsNWidgets(2));
    expect(find.text('Série 1'), findsNWidgets(2));
  });

  testWidgets('card mostra o rotulo do status e o valor total', (tester) async {
    repository.nfesParaListar = [NfeModel.fromJson(nfeJson(1, status: 'CANCELADA'))];
    await notifier.listarNfe();

    await _pumpTela(tester, notifier);
    await tester.pumpAndSettle();

    expect(find.text('Cancelada'), findsOneWidget);
    expect(find.text('R\$ 0,00'), findsOneWidget);
  });

  testWidgets('lista vazia nao mostra nenhum card', (tester) async {
    await notifier.listarNfe();

    await _pumpTela(tester, notifier);
    await tester.pumpAndSettle();

    expect(find.textContaining('NFe #'), findsNothing);
  });

  testWidgets('erro mostra a mensagem e "Tentar novamente" recarrega a lista', (tester) async {
    repository.erroAoListar = NfeRepositoryException('Servidor fora do ar');
    await notifier.listarNfe();

    await _pumpTela(tester, notifier);
    await tester.pumpAndSettle();

    expect(find.textContaining('Servidor fora do ar'), findsOneWidget);
    expect(repository.chamadasListar, 1);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(repository.chamadasListar, 2);
  });
}
