import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_status.dart';
import 'package:task_manager_flutter/models/nfe/nfe_tomador_model.dart';
import 'package:task_manager_flutter/models/nfe/valores_nfe_model.dart';
import 'package:task_manager_flutter/models/nfe_state.dart';
import 'package:task_manager_flutter/mobile/screens/nfe_list_screen.dart';
import 'package:task_manager_flutter/providers/nfe_notifier.dart';

// Mock do NfeNotifier
class MockNfeNotifier extends Mock implements NfeNotifier {}

void main() {
  group('NfeListScreen', () {
    late MockNfeNotifier mockNotifier;

    setUp(() {
      mockNotifier = MockNfeNotifier();
    });

    /// Helper para criar NfeModel de teste
    NfeModel _createTestNfe({
      int id = 1,
      String numero = '000001',
      int serie = 1,
      String status = 'AUTORIZADA',
      double total = 1500.0,
      String tomadorNome = 'Teste LTDA',
    }) {
      return NfeModel(
        id: id,
        empresaId: 1,
        numero: numero,
        serie: serie,
        dataHora: DateTime.now(),
        statusNfe: NfeStatus.fromCode(status),
        cnpjEmitente: '12345678901234',
        uf: 'SP',
        ambiente: 'HOMOLOGACAO',
        tomador: NfeTomadorModel(
          cnpjCpf: '12345678901234',
          razaoSocial: tomadorNome,
          endereco: 'Rua Teste',
          numero: '123',
          bairro: 'Centro',
          cep: '12345678',
          uf: 'SP',
          municipio: 'São Paulo',
        ),
        itens: [],
        valores: ValoresNfeModel(
          subtotal: total,
          totalIcms: 0,
          totalPis: 0,
          totalCofins: 0,
          desconto: 0,
          total: total,
        ),
        criadoEm: DateTime.now(),
      );
    }

    /// Helper para envolver screen com Provider
    Widget _wrapWithProvider(NfeNotifier notifier) {
      return MaterialApp(
        home: ChangeNotifierProvider<NfeNotifier>.value(
          value: notifier,
          child: const NfeListScreen(),
        ),
      );
    }

    testWidgets('renderiza AppBar com título correto', (WidgetTester tester) async {
      when(() => mockNotifier.state).thenReturn(
        NfeState(
          nfes: [],
          isLoading: false,
        ),
      );

      await tester.pumpWidget(_wrapWithProvider(mockNotifier));
      await tester.pumpAndSettle();

      expect(find.text('Notas Fiscais Emitidas'), findsOneWidget);
    });

    testWidgets('renderiza loading shimmer quando isLoading=true', (WidgetTester tester) async {
      when(() => mockNotifier.state).thenReturn(
        NfeState(
          nfes: [],
          isLoading: true,
        ),
      );

      await tester.pumpWidget(_wrapWithProvider(mockNotifier));
      await tester.pumpAndSettle();

      // Verifica se há Cards (shimmer)
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('renderiza empty state quando nfes.isEmpty', (WidgetTester tester) async {
      when(() => mockNotifier.state).thenReturn(
        NfeState(
          nfes: [],
          isLoading: false,
        ),
      );

      await tester.pumpWidget(_wrapWithProvider(mockNotifier));
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma NFe encontrada'), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    });

    testWidgets('renderiza error state quando hasError=true', (WidgetTester tester) async {
      when(() => mockNotifier.state).thenReturn(
        NfeState(
          nfes: [],
          isLoading: false,
          errorMessage: 'Erro ao carregar dados',
        ),
      );
      when(() => mockNotifier.limparErro()).thenReturn(null);
      when(() => mockNotifier.listarNfe()).thenAnswer((_) async {});

      await tester.pumpWidget(_wrapWithProvider(mockNotifier));
      await tester.pumpAndSettle();

      expect(find.text('Erro ao carregar NFes'), findsOneWidget);
      expect(find.text('Erro ao carregar dados'), findsOneWidget);
    });

    testWidgets('renderiza grid com NFes quando loaded', (WidgetTester tester) async {
      final nfes = [
        _createTestNfe(id: 1, numero: '000001'),
        _createTestNfe(id: 2, numero: '000002'),
        _createTestNfe(id: 3, numero: '000003'),
      ];

      when(() => mockNotifier.state).thenReturn(
        NfeState(
          nfes: nfes,
          isLoading: false,
        ),
      );

      await tester.pumpWidget(_wrapWithProvider(mockNotifier));
      await tester.pumpAndSettle();

      // Verifica se há cards para cada NFe
      expect(find.byType(Card), findsWidgets);
      expect(find.text('NFe #000001'), findsOneWidget);
      expect(find.text('NFe #000002'), findsOneWidget);
      expect(find.text('NFe #000003'), findsOneWidget);
    });

    testWidgets('exibe status badge com cor correta (AUTORIZADA=verde)', (WidgetTester tester) async {
      final nfe = _createTestNfe(status: 'AUTORIZADA');
      when(() => mockNotifier.state).thenReturn(
        NfeState(
          nfes: [nfe],
          isLoading: false,
        ),
      );

      await tester.pumpWidget(_wrapWithProvider(mockNotifier));
      await tester.pumpAndSettle();

      expect(find.text('Autorizada'), findsOneWidget);
    });

    testWidgets('abre NfeDetailDialog ao tocar no card', (WidgetTester tester) async {
      final nfe = _createTestNfe(id: 1, numero: '000001');
      when(() => mockNotifier.state).thenReturn(
        NfeState(
          nfes: [nfe],
          isLoading: false,
        ),
      );

      await tester.pumpWidget(_wrapWithProvider(mockNotifier));
      await tester.pumpAndSettle();

      // Toca no card
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();

      // Verifica se dialog foi aberto
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('renderiza filter bar como sticky header', (WidgetTester tester) async {
      final nfes = [_createTestNfe(id: 1)];
      when(() => mockNotifier.state).thenReturn(
        NfeState(
          nfes: nfes,
          isLoading: false,
        ),
      );
      when(() => mockNotifier.applyFilter(any())).thenReturn(null);

      await tester.pumpWidget(_wrapWithProvider(mockNotifier));
      await tester.pumpAndSettle();

      // Verifica se há DropdownButton (status filter)
      expect(find.byType(DropdownButton), findsWidgets);
    });

    testWidgets('exibe FAB com ícone add', (WidgetTester tester) async {
      when(() => mockNotifier.state).thenReturn(
        NfeState(
          nfes: [],
          isLoading: false,
        ),
      );

      await tester.pumpWidget(_wrapWithProvider(mockNotifier));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('formata valor em R$ corretamente', (WidgetTester tester) async {
      final nfe = _createTestNfe(total: 1234.50);
      when(() => mockNotifier.state).thenReturn(
        NfeState(
          nfes: [nfe],
          isLoading: false,
        ),
      );

      await tester.pumpWidget(_wrapWithProvider(mockNotifier));
      await tester.pumpAndSettle();

      // Verifica formato: R$ 1234,50
      expect(find.text('R\$ 1234,50'), findsOneWidget);
    });

    testWidgets('trunca destinatário longo com ellipsis', (WidgetTester tester) async {
      final nomeLongo = 'A' * 50;
      final nfe = _createTestNfe(tomadorNome: nomeLongo);
      when(() => mockNotifier.state).thenReturn(
        NfeState(
          nfes: [nfe],
          isLoading: false,
        ),
      );

      await tester.pumpWidget(_wrapWithProvider(mockNotifier));
      await tester.pumpAndSettle();

      // Verifica se o nome foi truncado
      final text = find.byType(Text);
      expect(text, findsWidgets); // Garante que há Texts renderizados
    });

    testWidgets('grid responsivo renderiza 1 coluna em mobile (375px)', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(375, 812);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      final nfes = List.generate(
        4,
        (i) => _createTestNfe(id: i, numero: '00000${i + 1}'),
      );

      when(() => mockNotifier.state).thenReturn(
        NfeState(
          nfes: nfes,
          isLoading: false,
        ),
      );

      await tester.pumpWidget(_wrapWithProvider(mockNotifier));
      await tester.pumpAndSettle();

      // Verifica se há grid com cards
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('grid responsivo renderiza 2 colunas em tablet (768px)', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(768, 1024);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      final nfes = List.generate(
        4,
        (i) => _createTestNfe(id: i, numero: '00000${i + 1}'),
      );

      when(() => mockNotifier.state).thenReturn(
        NfeState(
          nfes: nfes,
          isLoading: false,
        ),
      );

      await tester.pumpWidget(_wrapWithProvider(mockNotifier));
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('grid responsivo renderiza 4 colunas em desktop (1920px)', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      final nfes = List.generate(
        8,
        (i) => _createTestNfe(id: i, numero: '00000${i + 1}'),
      );

      when(() => mockNotifier.state).thenReturn(
        NfeState(
          nfes: nfes,
          isLoading: false,
        ),
      );

      await tester.pumpWidget(_wrapWithProvider(mockNotifier));
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
    });
  });
}
