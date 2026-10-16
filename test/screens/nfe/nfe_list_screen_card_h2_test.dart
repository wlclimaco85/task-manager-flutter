import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_flutter/mobile/screens/nfe_list_screen.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/providers/nfe_notifier.dart';

import '../../helpers/fake_nfe_repository.dart';
import '../../helpers/nfe_fixtures.dart';

/// Renderizacao dos cards de NFe na lista (mobile): numero, serie, status e valor.
void main() {
  late FakeNfeRepository repository;
  late NfeNotifier notifier;

  setUp(() {
    repository = FakeNfeRepository();
    notifier = NfeNotifier(repository);
  });

  Future<void> pumpComNfes(WidgetTester tester, List<NfeModel> nfes) async {
    repository.nfesParaListar = nfes;
    await notifier.listarNfe();
    await tester.pumpWidget(
      ChangeNotifierProvider<NfeNotifier>.value(
        value: notifier,
        child: const MaterialApp(home: NfeListScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('card autorizada mostra status "Autorizada"', (tester) async {
    await pumpComNfes(tester, [NfeModel.fromJson(nfeJson(1))]);

    expect(find.text('Autorizada'), findsOneWidget);
  });

  testWidgets('card rejeitada mostra status "Rejeitada"', (tester) async {
    await pumpComNfes(tester, [NfeModel.fromJson(nfeJson(2, status: 'REJEITADA'))]);

    expect(find.text('Rejeitada'), findsOneWidget);
  });

  testWidgets('card mostra o titulo da tela de notas emitidas', (tester) async {
    await pumpComNfes(tester, [NfeModel.fromJson(nfeJson(3))]);

    expect(find.text('Notas Fiscais Emitidas'), findsOneWidget);
  });
}
