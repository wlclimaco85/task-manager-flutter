import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_status.dart';
import 'package:task_manager_flutter/providers/nfe_notifier.dart';
import 'package:task_manager_flutter/repositories/nfe_repository.dart';
import 'package:task_manager_flutter/screens/nfe/nfe_detail_screen.dart';

import '../../helpers/nfe_test_data_factory.dart';

/// Mock simples do repositório
class MockNfeRepository implements NfeRepository {
  List<NfeModel> _mockNfes = [];
  bool _shouldFail = false;

  void setMockData(List<NfeModel> nfes) => _mockNfes = nfes;
  void setFail() => _shouldFail = true;
  void reset() {
    _mockNfes = [];
    _shouldFail = false;
  }

  @override
  Future<List<NfeModel>> listarNfe({
    required int page,
    required int pageSize,
    String? status,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? clienteCnpj,
  }) async {
    if (_shouldFail) throw Exception('Erro ao listar');
    return _mockNfes;
  }

  @override
  Future<NfeModel> obterNfe(int id) async {
    if (_shouldFail) throw Exception('Erro ao obter');
    return _mockNfes.firstWhere((nfe) => nfe.id == id);
  }

  @override
  Future<String> downloadXml(int id) async => '<xml></xml>';

  @override
  Future<List<int>> downloadPdf(int id) async => [];
}

void main() {
  late MockNfeRepository mockRepository;
  late NfeNotifier notifier;

  setUp(() {
    mockRepository = MockNfeRepository();
    notifier = NfeNotifier(mockRepository);
  });

  tearDown(() {
    mockRepository.reset();
  });

  /// Helper para renderizar com Provider
  Widget buildWithProvider(Widget child) {
    return MaterialApp(
      home: ChangeNotifierProvider<NfeNotifier>.value(
        value: notifier,
        child: child,
      ),
    );
  }

  group('NfeDetailScreen - Responsividade', () {
    testWidgets('Mobile: renderiza expandables stackadas', (WidgetTester tester) async {
      final nfe = NfeTestDataFactory.createNfe(status: NfeStatus.autorizada);
      mockRepository.setMockData([nfe]);

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);

      await tester.pumpWidget(buildWithProvider(const NfeDetailScreen(nfeId: 1)));
      await tester.pumpAndSettle();

      expect(find.byType(ExpansionTile), findsWidgets);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('Tablet: renderiza abas (TabBar)', (WidgetTester tester) async {
      final nfe = NfeTestDataFactory.createNfe(status: NfeStatus.pendente);
      mockRepository.setMockData([nfe]);

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(800, 1000);

      await tester.pumpWidget(buildWithProvider(const NfeDetailScreen(nfeId: 1)));
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Dados'), findsOneWidget);
      expect(find.text('Itens'), findsOneWidget);
    });

    testWidgets('Desktop: renderiza layout 2-colunas', (WidgetTester tester) async {
      final nfe = NfeTestDataFactory.createNfe(status: NfeStatus.cancelada);
      mockRepository.setMockData([nfe]);

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1400, 900);

      await tester.pumpWidget(buildWithProvider(const NfeDetailScreen(nfeId: 1)));
      await tester.pumpAndSettle();

      expect(find.byType(Row), findsWidgets);
      expect(find.text('NFe ${nfe.numeroFormatado}'), findsOneWidget);
    });
  });

  group('NfeDetailScreen - Estados', () {
    testWidgets('Estado loading: exibe CircularProgressIndicator', (WidgetTester tester) async {
      await tester.pumpWidget(buildWithProvider(const NfeDetailScreen(nfeId: 1)));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Estado erro: exibe mensagem', (WidgetTester tester) async {
      mockRepository.setFail();

      await tester.pumpWidget(buildWithProvider(const NfeDetailScreen(nfeId: 1)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('Estado vazio: exibe NFe não encontrada', (WidgetTester tester) async {
      mockRepository.setMockData([]);

      await tester.pumpWidget(buildWithProvider(const NfeDetailScreen(nfeId: 1)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.text('NFe não encontrada'), findsOneWidget);
    });

    testWidgets('Estado sucesso: renderiza dados NFe', (WidgetTester tester) async {
      final nfe = NfeTestDataFactory.createNfe(numero: '123456');
      mockRepository.setMockData([nfe]);

      await tester.pumpWidget(buildWithProvider(const NfeDetailScreen(nfeId: 1)));
      await tester.pumpAndSettle();

      expect(find.text('NFe ${nfe.numeroFormatado}'), findsOneWidget);
    });
  });

  group('NfeDetailScreen - Ações', () {
    testWidgets('NFe pendente: exibe botão Emitir', (WidgetTester tester) async {
      final nfe = NfeTestDataFactory.createNfe(status: NfeStatus.pendente);
      mockRepository.setMockData([nfe]);

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1400, 900);

      await tester.pumpWidget(buildWithProvider(const NfeDetailScreen(nfeId: 1)));
      await tester.pumpAndSettle();

      expect(find.text('Emitir'), findsWidgets);
    });

    testWidgets('NFe autorizada: exibe botão Cancelar', (WidgetTester tester) async {
      final nfe = NfeTestDataFactory.createNfe(status: NfeStatus.autorizada);
      mockRepository.setMockData([nfe]);

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1400, 900);

      await tester.pumpWidget(buildWithProvider(const NfeDetailScreen(nfeId: 1)));
      await tester.pumpAndSettle();

      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('Mobile: FAB abre bottom sheet', (WidgetTester tester) async {
      final nfe = NfeTestDataFactory.createNfe(status: NfeStatus.autorizada);
      mockRepository.setMockData([nfe]);

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);

      await tester.pumpWidget(buildWithProvider(const NfeDetailScreen(nfeId: 1)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Ações'), findsOneWidget);
    });
  });

  group('NfeDetailScreen - Acessibilidade', () {
    testWidgets('Header contém labels semânticos', (WidgetTester tester) async {
      final nfe = NfeTestDataFactory.createNfe();
      mockRepository.setMockData([nfe]);

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1400, 900);

      await tester.pumpWidget(buildWithProvider(const NfeDetailScreen(nfeId: 1)));
      await tester.pumpAndSettle();

      expect(find.text('Emitente'), findsWidgets);
      expect(find.text('UF'), findsWidgets);
      expect(find.text('Data'), findsWidgets);
    });
  });

  group('NfeDetailScreen - Tab Navigation', () {
    testWidgets('Tablet: abas navegáveis', (WidgetTester tester) async {
      final nfe = NfeTestDataFactory.createNfe();
      mockRepository.setMockData([nfe]);

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(800, 1000);

      await tester.pumpWidget(buildWithProvider(const NfeDetailScreen(nfeId: 1)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Itens'));
      await tester.pumpAndSettle();

      expect(find.byType(Tab), findsWidgets);
    });
  });

  group('NfeDetailScreen - Dados Nulos', () {
    testWidgets('Renderiza sem protocolo', (WidgetTester tester) async {
      final nfe = NfeTestDataFactory.createNfe();
      mockRepository.setMockData([nfe]);

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1400, 900);

      await tester.pumpWidget(buildWithProvider(const NfeDetailScreen(nfeId: 1)));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsWidgets);
    });
  });
}
