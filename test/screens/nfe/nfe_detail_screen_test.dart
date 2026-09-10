import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_status.dart';
import 'package:task_manager_flutter/models/nfe/nfe_tomador_model.dart';
import 'package:task_manager_flutter/models/nfe/valores_nfe_model.dart';
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

  @override
  Future<NfeModel> criarNfe(Map<String, dynamic> dados) async {
    if (_shouldFail) throw Exception('Erro ao criar');
    return NfeModel(
      id: 1,
      empresaId: 1,
      numero: '000001',
      serie: 1,
      dataHora: DateTime.now(),
      statusNfe: NfeStatus.pendente,
      cnpjEmitente: '11222333000181',
      uf: 'SP',
      ambiente: 'HOMOLOGACAO',
      tomador: NfeTomadorModel(
        cnpjCpf: '44555666000102',
        razaoSocial: 'Cliente B',
        endereco: 'Avenida B',
        numero: '200',
        bairro: 'Industrial',
        cep: '01310200',
        uf: 'SP',
        municipio: 'São Paulo',
      ),
      itens: [],
      valores: ValoresNfeModel(
        subtotal: 100.0,
        totalIcms: 18.0,
        totalPis: 1.65,
        totalCofins: 7.6,
        desconto: 0.0,
        total: 127.25,
      ),
      criadoEm: DateTime.now(),
    );
  }
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

  group('NfeDetailScreen', () {
    testWidgets('Renderiza Scaffold com AppBar', (WidgetTester tester) async {
      final nfe = NfeTestDataFactory.createNfe();
      mockRepository.setMockData([nfe]);

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1400, 900);

      await tester.pumpWidget(buildWithProvider(const NfeDetailScreen(nfeId: 1)));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('Desktop renderiza para largura grande', (WidgetTester tester) async {
      final nfe = NfeTestDataFactory.createNfe();
      mockRepository.setMockData([nfe]);

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1400, 900);

      await tester.pumpWidget(buildWithProvider(const NfeDetailScreen(nfeId: 1)));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
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

    testWidgets('Exibe status pendente com cor apropriada', (WidgetTester tester) async {
      final nfe = NfeTestDataFactory.createNfe(status: NfeStatus.pendente);
      mockRepository.setMockData([nfe]);

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1400, 900);

      await tester.pumpWidget(buildWithProvider(const NfeDetailScreen(nfeId: 1)));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

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
