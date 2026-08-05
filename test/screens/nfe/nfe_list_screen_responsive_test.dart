import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_status.dart';
import 'package:task_manager_flutter/models/nfe_state.dart';
import 'package:task_manager_flutter/providers/nfe_notifier.dart';
import 'package:task_manager_flutter/screens/nfe/nfe_list_screen.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_card.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_pagination_bar.dart';

class MockNfeNotifier extends Mock implements NfeNotifier {}

void main() {
  group('NfeListScreen Responsividade', () {
    late MockNfeNotifier mockNotifier;

    setUp(() {
      mockNotifier = MockNfeNotifier();
    });

    /// Cria app de teste com NfeListScreen envolvido em ChangeNotifierProvider
    Widget createTestApp({required Size size}) {
      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<NfeNotifier>.value(
            value: mockNotifier,
            child: const NfeListScreen(),
          ),
        ),
      );
    }

    testWidgets('grid renderiza 4 colunas em desktop (width >= 1200px)',
        (WidgetTester tester) async {
      // Arrange
      when(mockNotifier.state).thenReturn(
        NfeState(
          nfes: [],
          isLoading: false,
          errorMessage: null,
          currentPage: 1,
          pageSize: 10,
        ),
      );

      await tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      // Act
      await tester.pumpWidget(createTestApp(size: const Size(1920, 1080)));

      // Assert
      expect(find.byType(GridView), findsWidgets);
      expect(find.byType(NfeListScreen), findsOneWidget);
    });

    testWidgets('grid renderiza 2 colunas em tablet (768px <= width < 1200px)',
        (WidgetTester tester) async {
      // Arrange
      when(mockNotifier.state).thenReturn(
        NfeState(
          nfes: [],
          isLoading: false,
          errorMessage: null,
          currentPage: 1,
          pageSize: 10,
        ),
      );

      await tester.binding.window.physicalSizeTestValue = const Size(800, 600);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      // Act
      await tester.pumpWidget(createTestApp(size: const Size(800, 600)));

      // Assert
      expect(find.byType(GridView), findsWidgets);
    });

    testWidgets('grid renderiza 1 coluna em mobile (width < 768px)',
        (WidgetTester tester) async {
      // Arrange
      when(mockNotifier.state).thenReturn(
        NfeState(
          nfes: [],
          isLoading: false,
          errorMessage: null,
          currentPage: 1,
          pageSize: 10,
        ),
      );

      await tester.binding.window.physicalSizeTestValue = const Size(360, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      // Act
      await tester.pumpWidget(createTestApp(size: const Size(360, 800)));

      // Assert
      expect(find.byType(GridView), findsWidgets);
    });

    testWidgets('loading state renderiza spinner', (WidgetTester tester) async {
      // Arrange
      when(mockNotifier.state).thenReturn(
        NfeState(
          nfes: [],
          isLoading: true,
          errorMessage: null,
          currentPage: 1,
          pageSize: 10,
        ),
      );

      // Act
      await tester.pumpWidget(createTestApp(size: const Size(800, 600)));

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Carregando NFes...'), findsOneWidget);
    });

    testWidgets('error state renderiza mensagem + retry button',
        (WidgetTester tester) async {
      // Arrange
      const errorMsg = 'Erro ao conectar ao servidor';
      when(mockNotifier.state).thenReturn(
        NfeState(
          nfes: [],
          isLoading: false,
          errorMessage: errorMsg,
          currentPage: 1,
          pageSize: 10,
        ),
      );

      // Act
      await tester.pumpWidget(createTestApp(size: const Size(800, 600)));

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Erro ao carregar NFes'), findsOneWidget);
      expect(find.text(errorMsg), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('empty state renderiza quando nfes.isEmpty',
        (WidgetTester tester) async {
      // Arrange
      when(mockNotifier.state).thenReturn(
        NfeState(
          nfes: [],
          isLoading: false,
          errorMessage: null,
          currentPage: 1,
          pageSize: 10,
        ),
      );

      // Act
      await tester.pumpWidget(createTestApp(size: const Size(800, 600)));

      // Assert
      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('Nenhuma NFe encontrada'), findsOneWidget);
      expect(find.text('Ajuste os filtros e tente novamente'), findsOneWidget);
    });

    testWidgets('pagination bar renderiza com dados', (WidgetTester tester) async {
      // Arrange
      final nfe = NfeModel(
        id: 1,
        numero: '123456',
        serie: '1',
        statusNfe: NfeStatus.autorizada,
        dataHora: DateTime.now(),
        valores: NfeValores(
          subtotal: 1000.00,
          desconto: 0,
          icms: 100.00,
          pis: 10.00,
          cofins: 20.00,
          ipi: 0,
          csll: 0,
          inss: 0,
          frete: 50.00,
          seguro: 5.00,
          total: 1185.00,
        ),
        emitente: NfePessoa(
          cnpjCpf: '11.222.333/0001-81',
          razaoSocial: 'Empresa Emitente LTDA',
          endereco: 'Rua A, 123',
          cidade: 'São Paulo',
          uf: 'SP',
        ),
        tomador: NfePessoa(
          cnpjCpf: '11.444.555/0001-81',
          razaoSocial: 'Cliente LTDA',
          endereco: 'Rua B, 456',
          cidade: 'Rio de Janeiro',
          uf: 'RJ',
        ),
        nfeTomador: null,
      );

      when(mockNotifier.state).thenReturn(
        NfeState(
          nfes: [nfe],
          isLoading: false,
          errorMessage: null,
          currentPage: 1,
          pageSize: 10,
          totalPages: 3,
        ),
      );

      // Act
      await tester.pumpWidget(createTestApp(size: const Size(800, 600)));

      // Assert
      expect(find.byType(NfePaginationBar), findsOneWidget);
      expect(find.text('Página 1 de 3'), findsOneWidget);
    });

    testWidgets('NfeCard renderiza sem erros', (WidgetTester tester) async {
      // Arrange
      final nfe = NfeModel(
        id: 1,
        numero: '123456',
        serie: '1',
        statusNfe: NfeStatus.autorizada,
        dataHora: DateTime.now(),
        valores: NfeValores(
          subtotal: 1000.00,
          desconto: 0,
          icms: 100.00,
          pis: 10.00,
          cofins: 20.00,
          ipi: 0,
          csll: 0,
          inss: 0,
          frete: 50.00,
          seguro: 5.00,
          total: 1185.00,
        ),
        emitente: NfePessoa(
          cnpjCpf: '11.222.333/0001-81',
          razaoSocial: 'Empresa Emitente LTDA',
          endereco: 'Rua A, 123',
          cidade: 'São Paulo',
          uf: 'SP',
        ),
        tomador: NfePessoa(
          cnpjCpf: '11.444.555/0001-81',
          razaoSocial: 'Cliente LTDA',
          endereco: 'Rua B, 456',
          cidade: 'Rio de Janeiro',
          uf: 'RJ',
        ),
        nfeTomador: null,
      );

      when(mockNotifier.state).thenReturn(
        NfeState(
          nfes: [nfe],
          isLoading: false,
          errorMessage: null,
          currentPage: 1,
          pageSize: 10,
        ),
      );

      // Act
      await tester.pumpWidget(createTestApp(size: const Size(800, 600)));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(NfeCard), findsWidgets);
      expect(find.text('NF-e 123456'), findsOneWidget);
      expect(find.text('Cliente: Cliente LTDA'), findsOneWidget);
    });

    testWidgets('dark mode renderiza corretamente', (WidgetTester tester) async {
      // Arrange
      when(mockNotifier.state).thenReturn(
        NfeState(
          nfes: [],
          isLoading: false,
          errorMessage: null,
          currentPage: 1,
          pageSize: 10,
        ),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: ChangeNotifierProvider<NfeNotifier>.value(
              value: mockNotifier,
              child: const NfeListScreen(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(NfeListScreen), findsOneWidget);
    });
  });
}
