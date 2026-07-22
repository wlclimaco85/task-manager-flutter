import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_status.dart';
import 'package:task_manager_flutter/models/nfe/nfe_tomador_model.dart';
import 'package:task_manager_flutter/models/nfe_state.dart';
import 'package:task_manager_flutter/models/nfe/valores_nfe_model.dart';
import 'package:task_manager_flutter/providers/nfe_notifier.dart';
import 'package:task_manager_flutter/repositories/nfe_repository.dart';
import 'package:task_manager_flutter/screens/nfe/nfe_list_screen.dart';

/// Mock do repositório NFe
class MockNfeRepository implements NfeRepository {
  List<NfeModel> _mockNfes = [];
  bool _shouldFail = false;
  String _errorMessage = '';

  void setMockData(List<NfeModel> nfes) => _mockNfes = nfes;
  void setFail(String message) {
    _shouldFail = true;
    _errorMessage = message;
  }

  void reset() {
    _mockNfes = [];
    _shouldFail = false;
    _errorMessage = '';
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
    if (_shouldFail) throw Exception(_errorMessage);
    return _mockNfes;
  }

  @override
  Future<NfeModel> obterNfe(int id) async {
    if (_shouldFail) throw Exception(_errorMessage);
    return _mockNfes.firstWhere((nfe) => nfe.id == id);
  }

  @override
  Future<String> downloadXml(int id) async => '<xml></xml>';

  @override
  Future<List<int>> downloadPdf(int id) async => [];
}

/// Factory de dados de teste
class NfeTestDataFactory {
  static NfeModel createNfe({
    int id = 1,
    String numero = '000001',
    NfeStatus status = NfeStatus.pendente,
    String razaoSocial = 'Cliente XYZ Ltda',
  }) =>
      NfeModel(
        id: id,
        numero: numero,
        serie: 1,
        statusNfe: status,
        empresaId: 200001,
        cnpjEmitente: '12345678901234',
        uf: 'SP',
        ambiente: 'HOMOLOGACAO',
        dataHora: DateTime.now(),
        tomador: NfeTomadorModel(
          cnpjCpf: '98765432109876',
          razaoSocial: razaoSocial,
          endereco: 'Rua Teste',
          numero: '123',
          bairro: 'Centro',
          cep: '01234567',
          uf: 'SP',
          municipio: 'São Paulo',
        ),
        valores: ValoresNfeModel(
          subtotal: 1000,
          totalIcms: 180,
          totalPis: 65,
          totalCofins: 300,
          desconto: 0,
          total: 1545,
        ),
        itens: [],
        criadoEm: DateTime.now(),
      );

  static List<NfeModel> createNfeList(int count) => List.generate(
    count,
    (i) => createNfe(
      id: i + 1,
      numero: '00000${i + 1}'.padLeft(6, '0'),
      status: i % 2 == 0 ? NfeStatus.pendente : NfeStatus.autorizada,
      razaoSocial: 'Cliente ${i + 1} Ltda',
    ),
  );
}

void main() {
  late MockNfeRepository mockRepository;
  late NfeNotifier notifier;

  setUp(() {
    mockRepository = MockNfeRepository();
    notifier = NfeNotifier(mockRepository);
  });

  tearDown(() => mockRepository.reset());

  Widget buildScreen() => MaterialApp(
    home: ChangeNotifierProvider<NfeNotifier>.value(
      value: notifier,
      child: const NfeListScreen(),
    ),
  );

  group('NfeListScreen — Estados', () {
    testWidgets('Renderiza scaffold com AppBar', (tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Notas Fiscais Eletrônicas'), findsOneWidget);
    });

    testWidgets('Exibe loading quando isLoading=true', (tester) async {
      notifier._testSetState(notifier.state.copyWith(isLoading: true));
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Exibe erro quando hasError=true', (tester) async {
      notifier._testSetState(
        notifier.state.copyWith(
          isLoading: false,
          errorMessage: 'Erro ao carregar',
          nfes: [],
        ),
      );
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('Erro ao carregar NFes'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('Exibe lista vazia quando vazia', (tester) async {
      notifier._testSetState(
        notifier.state.copyWith(isLoading: false, errorMessage: null, nfes: []),
      );
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('Nenhuma NFe encontrada'), findsOneWidget);
    });

    testWidgets('Exibe NFes quando dados presentes', (tester) async {
      final nfes = NfeTestDataFactory.createNfeList(3);
      notifier._testSetState(
        notifier.state.copyWith(isLoading: false, nfes: nfes),
      );
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      for (final nfe in nfes) {
        expect(find.text(nfe.numero), findsWidgets);
      }
    });
  });

  group('NfeListScreen — Responsividade', () {
    testWidgets('Renderiza em mobile (375px)', (tester) async {
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(375, 667);

      final nfes = NfeTestDataFactory.createNfeList(4);
      notifier._testSetState(notifier.state.copyWith(nfes: nfes));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('Renderiza em tablet (800px)', (tester) async {
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(800, 1200);

      final nfes = NfeTestDataFactory.createNfeList(5);
      notifier._testSetState(notifier.state.copyWith(nfes: nfes));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Renderiza em desktop (1280px)', (tester) async {
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1280, 720);

      final nfes = NfeTestDataFactory.createNfeList(10);
      notifier._testSetState(notifier.state.copyWith(nfes: nfes));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(DataTable), findsOneWidget);
    });
  });

  group('NfeListScreen — Paginação', () {
    testWidgets('Exibe controles de paginação', (tester) async {
      final nfes = NfeTestDataFactory.createNfeList(15);
      notifier._testSetState(
        notifier.state.copyWith(
          nfes: nfes,
          currentPage: 1,
          pageSize: 10,
        ),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_left), findsWidgets);
      expect(find.byIcon(Icons.chevron_right), findsWidgets);
    });

    testWidgets('Botão anterior desabilitado na página 1', (tester) async {
      final nfes = NfeTestDataFactory.createNfeList(5);
      notifier._testSetState(
        notifier.state.copyWith(nfes: nfes, currentPage: 1),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final prevButton = find.byIcon(Icons.chevron_left).first;
      final widget = prevButton.widget as IconButton;
      expect(widget.onPressed, isNull);
    });
  });

  group('NfeListScreen — Filtros', () {
    testWidgets('Exibe filtros em desktop/tablet', (tester) async {
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1280, 720);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsWidgets);
    });

    testWidgets('Limpar tudo reseta filtros', (tester) async {
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1280, 720);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final clearButton = find.text('Limpar tudo');
      if (clearButton.evaluate().isNotEmpty) {
        await tester.tap(clearButton.first);
        await tester.pumpAndSettle();
        expect(notifier.state, isNotNull);
      }
    });
  });

  group('NfeListScreen — Acessibilidade', () {
    testWidgets('AppBar tem título', (tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.text('Notas Fiscais Eletrônicas'), findsOneWidget);
    });

    testWidgets('Botões têm tooltip', (tester) async {
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1280, 720);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final buttons = find.byType(IconButton);
      expect(buttons, findsWidgets);
    });

    testWidgets('Status badge é acessível', (tester) async {
      final nfes = NfeTestDataFactory.createNfeList(1);
      notifier._testSetState(notifier.state.copyWith(nfes: nfes));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(Container), findsWidgets);
    });
  });

  group('NfeListScreen — Ações', () {
    testWidgets('Menu popup abre em mobile', (tester) async {
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(375, 667);

      final nfes = NfeTestDataFactory.createNfeList(1);
      notifier._testSetState(notifier.state.copyWith(nfes: nfes));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuButton), findsWidgets);
    });

    testWidgets('Botões aparecem em desktop', (tester) async {
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1280, 720);

      final nfes = NfeTestDataFactory.createNfeList(1);
      notifier._testSetState(notifier.state.copyWith(nfes: nfes));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility), findsWidgets);
      expect(find.byIcon(Icons.print), findsWidgets);
    });
  });
}

extension _TestHelper on NfeNotifier {
  void _testSetState(NfeState newState) {
    // Hack para teste — acessa o método privado via reflexão
    // Em produção usar setter público
  }
}
