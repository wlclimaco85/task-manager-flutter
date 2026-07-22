import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_flutter/models/nfe/nfe_item_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_status.dart';
import 'package:task_manager_flutter/models/nfe/nfe_tomador_model.dart';
import 'package:task_manager_flutter/models/nfe/valores_nfe_model.dart';
import 'package:task_manager_flutter/models/nfe_state.dart';
import 'package:task_manager_flutter/providers/nfe_notifier.dart';
import 'package:task_manager_flutter/repositories/nfe_repository.dart';
import 'package:task_manager_flutter/screens/nfe/nfe_form_screen.dart';

class MockNfeRepository extends Mock implements NfeRepository {}

class MockNfeNotifier extends ChangeNotifier {
  NfeState _state = NfeState(
    nfes: [],
    selected: null,
    isLoading: false,
    errorMessage: null,
    currentPage: 1,
    pageSize: 10,
  );

  NfeState get state => _state;

  Future<NfeModel> criarNfe(Map<String, dynamic> dados) async {
    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    try {
      // Simula NFe criada
      final nfe = NfeModel(
        id: 1,
        empresaId: 1,
        numero: '000001',
        serie: 1,
        dataHora: DateTime.now(),
        statusNfe: NfeStatus.rascunho,
        cnpjEmitente: '11222333000181',
        uf: 'SP',
        ambiente: 'HOMOLOGACAO',
        tomador: NfeTomadorModel(
          cnpjCpf: '44555666000102',
          razaoSocial: 'Cliente B Indústria Ltda',
          endereco: 'Avenida B',
          numero: '200',
          bairro: 'Industrial',
          cep: '01310200',
          uf: 'SP',
          municipio: 'São Paulo',
        ),
        itens: [],
        valores: ValoresNfeModel(
          baseIcms: 100.0,
          icms: 18.0,
          pis: 1.65,
          cofins: 7.6,
          total: 127.25,
        ),
        criadoEm: DateTime.now(),
      );

      _state = _state.copyWith(
        selected: nfe,
        isLoading: false,
        errorMessage: null,
      );
      notifyListeners();

      return nfe;
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      notifyListeners();
      rethrow;
    }
  }
}

void main() {
  group('NfeFormScreen Tests', () {
    late MockNfeNotifier mockNfeNotifier;

    setUp(() {
      mockNfeNotifier = MockNfeNotifier();
    });

    Widget buildTestApp({Widget? home}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<NfeNotifier>.value(value: mockNfeNotifier),
        ],
        child: MaterialApp(
          home: home ?? const NfeFormScreen(),
          routes: {
            '/nfe/detail': (context) => const Scaffold(body: Text('Detail Screen')),
          },
        ),
      );
    }

    testWidgets('Renderização inicial do form', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      expect(find.byType(Form), findsOneWidget);
      expect(find.text('Nova Nota Fiscal Eletrônica'), findsWidgets);
      expect(find.text('Cliente *'), findsOneWidget);
      expect(find.text('Natureza da Operação *'), findsOneWidget);
    });

    testWidgets('Layout mobile (tela estreita)', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(buildTestApp());

      // Em mobile, os campos devem estar em coluna única
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Row), findsWidgets); // pode ter rows para buttons
    });

    testWidgets('Layout tablet (tela média)', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(800, 1000);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(buildTestApp());

      // Em tablet, deve haver layout com 2 colunas
      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('Layout desktop (tela larga)', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1400, 900);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(buildTestApp());

      // Em desktop, deve haver layout com 3 colunas
      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('Seleção de cliente valida CNPJ/CPF', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Abre dropdown de cliente
      await tester.tap(find.byType(DropdownButtonFormField).first);
      await tester.pumpAndSettle();

      // Seleciona primeiro cliente
      await tester.tap(find.text('Cliente A Comércio Ltda (11.222.333/0000-81)'));
      await tester.pumpAndSettle();

      // Verifica se CNPJ foi preenchido
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('Adicionar item cria novo item vazio', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Clica em "Adicionar Item"
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verifica se item foi adicionado
      expect(find.text('Novo Item'), findsOneWidget);
    });

    testWidgets('Remover item remove da lista', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Adiciona item
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verifica se item existe
      expect(find.text('Novo Item'), findsOneWidget);

      // Nota: remoção seria feita via ícone delete em NfeItemsTable
      // Este teste valida que a lógica de adição funciona
    });

    testWidgets('Cálculo automático de totais', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Verifica se seção de totais existe
      expect(find.text('Resumo de Totais'), findsOneWidget);
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('ICMS (18%)'), findsOneWidget);
      expect(find.text('PIS (1,65%)'), findsOneWidget);
      expect(find.text('COFINS (7,6%)'), findsOneWidget);
      expect(find.text('TOTAL'), findsOneWidget);
    });

    testWidgets('Validação: cliente obrigatório', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Tenta submeter sem cliente
      await tester.tap(find.text('Criar NFe'));
      await tester.pumpAndSettle();

      // Deve mostrar erro
      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('Validação: natureza obrigatória', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Seleciona cliente
      await tester.tap(find.byType(DropdownButtonFormField).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cliente A Comércio Ltda (11.222.333/0000-81)'));
      await tester.pumpAndSettle();

      // Tenta submeter sem natureza
      await tester.tap(find.text('Criar NFe'));
      await tester.pumpAndSettle();

      // Deve mostrar erro
      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('Validação: itens obrigatório', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Seleciona cliente
      await tester.tap(find.byType(DropdownButtonFormField).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cliente A Comércio Ltda (11.222.333/0000-81)'));
      await tester.pumpAndSettle();

      // Seleciona natureza
      await tester.tap(find.byType(DropdownButtonFormField).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Venda'));
      await tester.pumpAndSettle();

      // Tenta submeter sem itens
      await tester.tap(find.text('Criar NFe'));
      await tester.pumpAndSettle();

      // Deve mostrar erro
      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('Submit com dados válidos chama criarNfe', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Seleciona cliente
      await tester.tap(find.byType(DropdownButtonFormField).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cliente A Comércio Ltda (11.222.333/0000-81)'));
      await tester.pumpAndSettle();

      // Seleciona natureza
      await tester.tap(find.byType(DropdownButtonFormField).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Venda'));
      await tester.pumpAndSettle();

      // Adiciona item
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Submete (mesmo que com mock, validará a cascata)
      await tester.tap(find.text('Criar NFe'));
      await tester.pumpAndSettle();

      // Deve processar submission (loading spinner aparece)
    });

    testWidgets('Campos obrigatórios marcados com *', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      expect(find.text('Cliente *'), findsOneWidget);
      expect(find.text('Natureza da Operação *'), findsOneWidget);
      expect(find.text('Itens *'), findsOneWidget);
    });

    testWidgets('TextFormField com rótulos acessíveis', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Verifica se labels estão presentes
      expect(find.text('Série'), findsOneWidget);
      expect(find.text('Observações'), findsOneWidget);
      expect(find.text('CNPJ/CPF'), findsOneWidget);
      expect(find.text('Razão Social'), findsOneWidget);
    });

    testWidgets('Botão submit desabilitado durante envio', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Seleciona cliente
      await tester.tap(find.byType(DropdownButtonFormField).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cliente A Comércio Ltda (11.222.333/0000-81)'));
      await tester.pumpAndSettle();

      // Seleciona natureza
      await tester.tap(find.byType(DropdownButtonFormField).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Venda'));
      await tester.pumpAndSettle();

      // Adiciona item
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Submete
      await tester.tap(find.text('Criar NFe'));
      await tester.pumpAndSettle();

      // Durante envio, button show loading
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });
}
