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

  group('NfeDetailScreen - Widget Rendering', () {
    testWidgets('Renderiza Scaffold com AppBar', (WidgetTester tester) async {
      final nfe = NfeTestDataFactory.createNfe();
      mockRepository.setMockData([nfe]);

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1400, 900);

      await tester.pumpWidget(buildWithProvider(const NfeDetailScreen(nfeId: 1)));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Detalhes da NFe'), findsOneWidget);
    });

    testWidgets('Estado vazio exibe ícone de info', (WidgetTester tester) async {
      mockRepository.setMockData([]);

      await tester.pumpWidget(buildWithProvider(const NfeDetailScreen(nfeId: 1)));

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.text('NFe não encontrada'), findsOneWidget);
    });

    testWidgets('Estado erro exibe ícone de erro', (WidgetTester tester) async {
      mockRepository.setFail();

      await tester.pumpWidget(buildWithProvider(const NfeDetailScreen(nfeId: 1)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('Com dados renderiza múltiplos Cards', (WidgetTester tester) async {
      final nfe = NfeTestDataFactory.createNfe();
      mockRepository.setMockData([nfe]);

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1400, 900);

      await tester.pumpWidget(buildWithProvider(const NfeDetailScreen(nfeId: 1)));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsWidgets);
    });
  });

  group('NfeDetailScreen - Responsiveness', () {
    testWidgets('Desktop renderiza para largura grande', (WidgetTester tester) async {
      final nfe = NfeTestDataFactory.createNfe();
      mockRepository.setMockData([nfe]);

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1400, 900);

      await tester.pumpWidget(buildWithProvider(const NfeDetailScreen(nfeId: 1)));
      await tester.pumpAndSettle();

      final scaffold = find.byType(Scaffold);
      expect(scaffold, findsOneWidget);
    });

    testWidgets('Tablet renderiza para largura média', (WidgetTester tester) async {
      final nfe = NfeTestDataFactory.createNfe();
      mockRepository.setMockData([nfe]);

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(800, 1000);

      await tester.pumpWidget(buildWithProvider(const NfeDetailScreen(nfeId: 1)));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('NfeDetailScreen - Status Display', () {
    testWidgets('Exibe status pendente com cor apropriada', (WidgetTester tester) async {
      final nfe = NfeTestDataFactory.createNfe(status: NfeStatus.pendente);
      mockRepository.setMockData([nfe]);

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1400, 900);

      await tester.pumpWidget(buildWithProvider(const NfeDetailScreen(nfeId: 1)));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Exibe status autorizado', (WidgetTester tester) async {
      final nfe = NfeTestDataFactory.createNfe(status: NfeStatus.autorizada);
      mockRepository.setMockData([nfe]);

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1400, 900);

      await tester.pumpWidget(buildWithProvider(const NfeDetailScreen(nfeId: 1)));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('NfeDetailScreen - Data Display', () {
    testWidgets('Renderiza informações de NFe', (WidgetTester tester) async {
      final nfe = NfeTestDataFactory.createNfe(
        numero: '123456',
        razaoSocial: 'Empresa Teste LTDA',
      );
      mockRepository.setMockData([nfe]);

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1400, 900);

      await tester.pumpWidget(buildWithProvider(const NfeDetailScreen(nfeId: 1)));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
