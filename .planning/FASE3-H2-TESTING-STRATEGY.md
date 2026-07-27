# FASE 3 H2 Flutter — Estratégia de Testes

**Autor**: Claude Code  
**Data**: 2026-07-21  
**Escopo**: Telas Responsivas + UX (NfeListScreen, NfeDetailScreen, NfeFormScreen, Widgets, Testes)  
**Requisito**: 80%+ cobertura, 20+ widget tests, 3 tamanhos (mobile/tablet/desktop)

---

## 1. Test Pyramid (Estrutura)

```
          ▲
         ╱ ╲
        ╱   ╲        Integration Tests (5-10%)
       ╱     ╲       - E2E flows: filtro → detalhe → ação
      ╱───────╲
     ╱         ╲     Widget Tests (40-45%)
    ╱           ╲    - Telas responsivas (3 breakpoints)
   ╱_____________╲   - Estados (loading, empty, error, success)
  ╱               ╲   - Interações (cliques, swipes, forms)
 ╱                 ╲  - Accessibility (tap targets, labels)
╱───────────────────╲ Unit Tests (50-55%)
                      - Notifiers (NfeNotifier)
                      - State transitions (NfeState)
                      - Helpers (filterNfes, calculateTotal)
                      - Models (fromJson, toJson)
```

---

## 2. Cobertura Esperada (80%+)

### 2.1 Cobertura por Tela

| Componente | Unit | Widget | Integration | Total | Meta |
|------------|------|--------|-------------|-------|------|
| **NfeListScreen** | 15% | 60% | 5% | 80% | ✓ 80% |
| **NfeDetailScreen** | 10% | 65% | 5% | 80% | ✓ 80% |
| **NfeFormScreen** | 20% | 55% | 5% | 80% | ✓ 80% |
| **Widgets reutilizáveis** (5) | 25% | 70% | 0% | 95% | ✓ 95% |
| **NfeNotifier** (state mgmt) | 85% | 15% | 0% | 100% | ✓ 100% |
| **NfeRepository mocks** | 100% | 0% | 0% | 100% | ✓ 100% |
| **Helpers** | 90% | 0% | 0% | 90% | ✓ 90% |

### 2.2 Artefatos de Teste

- **Testes unitários**: 12 suites (1,200+ linhas)
- **Testes widget**: 20+ suites (4,000+ linhas)
- **Testes integração**: 3 suites (500+ linhas)
- **Golden tests** (opcional): 8 snapshots (UI consistency)
- **Total**: ~32 suites, 5,700+ linhas de teste

---

## 3. Widget Test Fixtures (Responsividade)

### 3.1 Breakpoints Testados

| Breakpoint | Width | Height | Plataforma | Caso de Uso |
|------------|-------|--------|-----------|-----------|
| **Mobile** | 375px | 667px | iOS/Android | Tela padrão smartphone |
| **Tablet** | 800px | 1200px | iPad / Android tablet | Modo paisagem tablet |
| **Desktop** | 1280px | 720px | Windows/Web | Janela desktop padrão |

### 3.2 Device Fixture Helper

```dart
/// Helper para criar widget tree com tamanho específico
class DeviceTestHelper {
  static const Size mobileLandscape = Size(667, 375);
  static const Size mobilePortrait = Size(375, 667);
  static const Size tabletPortrait = Size(800, 1200);
  static const Size tabletLandscape = Size(1200, 800);
  static const Size desktopWindow = Size(1280, 720);

  static Future<void> pumpWidget(
    WidgetTester tester,
    Widget widget,
    Size size,
  ) async {
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    tester.binding.window.physicalSizeTestValue = size;

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }
}
```

### 3.3 Fixture de MockNfeNotifier

```dart
/// Mock simples de NfeNotifier para testes widget
class MockNfeNotifier extends ChangeNotifier {
  NfeState _state;
  
  MockNfeNotifier({NfeState? initialState})
    : _state = initialState ?? NfeState.empty();

  NfeState get state => _state;

  void setState(NfeState newState) {
    _state = newState;
    notifyListeners();
  }

  // Getters para simular loading, erro, sucesso
  void simulateLoading() => setState(_state.copyWith(isLoading: true));
  void simulateError(String msg) => setState(_state.copyWith(
    isLoading: false,
    errorMessage: msg,
  ));
  void simulateSuccess(List<NfeModel> nfes) => setState(_state.copyWith(
    isLoading: false,
    errorMessage: null,
    nfes: nfes,
  ));
}
```

---

## 4. Mocking Strategy

### 4.1 NfeRepository Mock

```dart
/// Mock do repositório para testes widget/integração
class MockNfeRepository implements NfeRepository {
  List<NfeModel> mockNfes = [];
  bool shouldFail = false;
  String errorMessage = '';

  Future<List<NfeModel>> listarNfe({...}) async {
    if (shouldFail) throw NfeRepositoryException(errorMessage);
    return mockNfes;
  }

  Future<NfeModel> obterNfe(int id) async {
    if (shouldFail) throw NfeRepositoryException(errorMessage);
    return mockNfes.firstWhere((n) => n.id == id);
  }

  Future<String> downloadXml(int id) async => '<mock/>';
  Future<List<int>> downloadPdf(int id) async => [0, 1, 2];
}
```

### 4.2 Dados Fictícios (Test Data)

```dart
/// Factory para criar dados de teste consistentes
class NfeTestDataFactory {
  static NfeModel createNfe({
    int id = 1,
    String numero = '000001',
    NfeStatus status = NfeStatus.pendente,
  }) => NfeModel(
    id: id,
    numero: numero,
    serie: 1,
    statusNfe: status,
    empresaId: 200001,
    cnpjEmitente: '12345678901234',
    uf: 'SP',
    ambiente: 'HOMOLOGACAO',
    dataHora: DateTime.now(),
    tomador: const NfeTomadorModel(
      cnpjCpf: '98765432109876',
      razaoSocial: 'Cliente XYZ Ltda',
      endereco: 'Rua Teste, 123',
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

  static List<NfeModel> createNfeList(int count) =>
    List.generate(count, (i) => createNfe(id: i + 1, numero: '00000${i+1}'));
}
```

---

## 5. Accessibility Checks (a11y)

### 5.1 Requisitos de Acessibilidade

| Requisito | Critério | Teste |
|-----------|----------|-------|
| **Tap Targets** | ≥ 48dp (Material) | `find.byType(InkWell).evaluate().length >= expected` |
| **Text Labels** | Todo botão/campo tem label | `find.bySemantics(label: '...').evaluate()` |
| **Contrast** | WCAG AA mínimo 4.5:1 | Visual inspection + `canvaskit` render |
| **Focus** | Navegação keyboard + visual focus | `find.bySemanticsLabel(...).hitTest()` |
| **Tooltip** | Ícones isolados têm tooltip | `find.byTooltip('...')` |
| **Screen Reader** | Descrições automáticas | `Semantics` wrapper verificado |

### 5.2 Accessibility Test Helper

```dart
class A11yTestHelper {
  /// Verifica se todos InkWells têm tamanho ≥ 48x48 dp
  static void verifyMinTapTargets(WidgetTester tester) {
    final inkWells = find.byType(InkWell);
    expect(inkWells, findsWidgets);

    for (final match in inkWells.evaluate()) {
      final box = match.renderObject as RenderBox;
      final size = box.size;
      expect(
        size.width >= 48 && size.height >= 48,
        true,
        reason: 'Tap target ${size} menores que 48x48dp',
      );
    }
  }

  /// Verifica se campo de texto tem label semântico
  static void verifyFieldLabels(WidgetTester tester) {
    final textFields = find.byType(TextField);
    expect(textFields, findsWidgets);

    for (final match in textFields.evaluate()) {
      final widget = match.widget as TextField;
      expect(
        widget.semanticCounterText != null || widget.decoration?.labelText != null,
        true,
        reason: 'TextField sem label ou counter',
      );
    }
  }
}
```

---

## 6. Regression Checklist

### 6.1 Estados Obrigatórios (Loading, Empty, Error, Success)

**NfeListScreen:**

```dart
// ✓ Estado LOADING
expect(find.byType(CircularProgressIndicator), findsOneWidget);
expect(find.byType(ListView), findsNothing);

// ✓ Estado EMPTY (sem NFes)
expect(find.text('Nenhuma nota fiscal encontrada'), findsOneWidget);
expect(find.byType(EmptyStateWidget), findsOneWidget);

// ✓ Estado ERROR
expect(find.text('Erro ao carregar'), findsOneWidget);
expect(find.byType(ErrorWidget), findsOneWidget);
expect(find.byIcon(Icons.error), findsOneWidget);

// ✓ Estado SUCCESS (com dados)
expect(find.byType(NfeListTile), findsWidgets);
expect(find.text('000001'), findsOneWidget);
expect(find.byType(FloatingActionButton), findsOneWidget);
```

### 6.2 Responsividade (3 Breakpoints)

```dart
// ✓ MOBILE (375px): 1 coluna, padding reduzido, buttons empilhados
// - Filtros em drawer ou bottom sheet
// - Lista vertical
// - Ações em card footer

// ✓ TABLET (800px): 2 colunas, sidebar, grid adaptado
// - Filtros em sidebar esquerda (sticky)
// - Lista + detalhe lado a lado
// - Ações inline

// ✓ DESKTOP (1280px): 3+ colunas, full layout, toolbar
// - Filtros em painel esquerdo expansível
// - Lista detalhada (muitas colunas)
// - Preview detalhe em painel direito
// - Ações em toolbar
```

### 6.3 Interações Críticas

```dart
// ✓ Clique em item da lista → abre detalhe
await tester.tap(find.byType(NfeListTile).first);
await tester.pumpAndSettle();
expect(find.byType(NfeDetailScreen), findsOneWidget);

// ✓ Filtro por status → recarrega lista com novo status
await tester.tap(find.byType(DropdownButton).at(0));
await tester.pumpAndSettle();
await tester.tap(find.text('AUTORIZADA'));
await tester.pumpAndSettle();
expect(find.byType(NfeListTile), findsWidgets);

// ✓ Pull-to-refresh → recarrega dados
await tester.fling(find.byType(RefreshIndicator), Offset(0, 300), 1000);
await tester.pumpAndSettle();

// ✓ Paginação → carrega próxima página
await tester.tap(find.byIcon(Icons.navigate_next));
await tester.pumpAndSettle();
expect(notifier.state.currentPage, 2);

// ✓ Busca por CNPJ → filtra cliente
await tester.enterText(find.byType(TextField).at(0), '12345678901234');
await tester.tap(find.byIcon(Icons.search));
await tester.pumpAndSettle();
```

---

## 7. Tools & Setup

### 7.1 Dependências (já em pubspec.yaml)

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  integration_test:
    sdk: flutter
```

### 7.2 Executar Testes

```bash
# Todos os testes
flutter test

# Apenas unit tests
flutter test test/units/

# Apenas widget tests
flutter test test/widgets/

# Apenas um arquivo
flutter test test/widgets/nfe_list_screen_test.dart

# Com cobertura
flutter test --coverage
lcov --summary coverage/lcov.info

# Teste específico
flutter test test/widgets/nfe_list_screen_test.dart -k "mobile breakpoint"
```

### 7.3 CI/CD Integration

```yaml
# .github/workflows/test.yml
- name: Run tests
  run: flutter test --coverage

- name: Upload coverage
  run: |
    dart pub global activate coverage
    format_coverage --packages=.packages -i coverage/lcov.info -o coverage/lcov-formatted.info --report-on=lib
```

---

## 8. Estrutura de Arquivos

```
test/
├── providers/
│   ├── nfe_notifier_simple_test.dart    (✓ existente)
│   └── nfe_notifier_widget_test.dart    (novo: Provider integration)
├── screens/
│   ├── nfe/
│   │   ├── nfe_list_screen_test.dart    (NEW: 200+ linhas, 3 breakpoints)
│   │   ├── nfe_detail_screen_test.dart  (NEW: 180+ linhas)
│   │   └── nfe_form_screen_test.dart    (NEW: 150+ linhas)
│   └── nfe_screen_e2e_test.dart         (novo: E2E flow)
├── widgets/
│   ├── nfe_list_tile_test.dart          (novo: widget reutilizável)
│   ├── nfe_status_badge_test.dart       (novo: widget reutilizável)
│   ├── nfe_filter_panel_test.dart       (novo: widget reutilizável)
│   ├── nfe_loading_skeleton_test.dart   (novo: widget reutilizável)
│   └── nfe_empty_state_test.dart        (novo: widget reutilizável)
├── helpers/
│   ├── device_test_helper.dart          (novo: fixture responsividade)
│   ├── nfe_test_data_factory.dart       (novo: dados fictícios)
│   ├── mock_nfe_notifier.dart           (novo: mock notifier)
│   ├── mock_nfe_repository.dart         (novo: mock repo)
│   └── a11y_test_helper.dart            (novo: testes acessibilidade)
└── integration_tests/
    └── nfe_flow_e2e_test.dart           (novo: flow E2E)
```

---

## 9. Critérios de Aceitação (DoD)

- [ ] 20+ widget tests implementados (mínimo)
- [ ] 80%+ cobertura de código nas 3 telas
- [ ] 3 breakpoints testados (mobile 375px, tablet 800px, desktop 1280px)
- [ ] 5 widgets reutilizáveis com testes (NfeListTile, NfeStatusBadge, NfeFilterPanel, NfeLoadingSkeleton, NfeEmptyState)
- [ ] Estados testados: loading, empty, error, success em cada tela
- [ ] Accessibility checks: tap targets (48dp), labels, focus navigation
- [ ] Regression checklist documentada + executada
- [ ] Golden tests (opcional) para UI consistency
- [ ] Todos testes passam: `flutter test --coverage` ≥ 80%
- [ ] Mock strategy documentada (MockNfeNotifier, MockNfeRepository, test data)
- [ ] Testes rodam em CI/CD pipeline
- [ ] Documentação finalizada com exemplos

---

## 10. Timeline Estimado

| Task | SP | Horas | Responsável | Bloqueador |
|------|----|----|---|---|
| Criar fixtures + helpers | 2 | 4h | QA | - |
| NfeListScreen tests (200 linhas) | 3 | 6h | QA | fixtures |
| NfeDetailScreen tests (180 linhas) | 2.5 | 5h | QA | fixtures |
| NfeFormScreen tests (150 linhas) | 2.5 | 5h | QA | fixtures |
| 5 Widget tests (100 linhas each) | 2.5 | 5h | QA | telas |
| E2E integration tests (3 flows) | 2 | 4h | QA | telas |
| Golden tests + accessibility | 1.5 | 3h | QA | telas |
| Coverage review + final report | 1 | 2h | QA | testes |
| **TOTAL** | **16.5 SP** | **34h** | - | - |

---

## 11. Notas Importantes

### 11.1 Reutilização Existente

- Usar `nfe_notifier_simple_test.dart` como modelo para testes unitários de notifier
- Padrão `MockXXX` implementado em `nfe_notifier_simple_test.dart` — replicar em outros mocks
- `ResponsiveHelper` já existe com breakpoints: mobile < 768, tablet < 1024, desktop ≥ 1024

### 11.2 Sem Dependência de Backend Real

- Todos os dados vêm de mocks (MockNfeRepository)
- Sem chamadas HTTP reais em testes
- Simulação de states (loading, error, success) via MockNfeNotifier

### 11.3 Cobertura Mínima vs Ideal

- **Mínimo obrigatório**: 80% por tela
- **Ideal**: 90%+ (widgets reutilizáveis em 95%)
- Golden tests são **opcionais** mas recomendados para UI stability

### 11.4 Guardrai (Avisos)

- ⚠️ Não alterar nfe_notifier_simple_test.dart (já em produção)
- ⚠️ MockNfeRepository deve ter mesma interface que NfeRepository
- ⚠️ Fixtures devem ser imutáveis (final const) para evitar vazamento de estado entre testes
- ⚠️ Usar `tester.pumpAndSettle()` após interações async
- ⚠️ Breakpoints: mobile=375, tablet=800, desktop=1280 (fixo em projeto)

---

## 12. Referências

- **Flutter Testing**: https://flutter.dev/docs/testing
- **Widget Testing Guide**: https://flutter.dev/docs/testing/widget-test-introduction
- **MockData Pattern**: https://pub.dev/packages/mockito
- **Responsive Testing**: https://flutter.dev/docs/testing/platform-channel-testing
- **Accessibility**: https://flutter.dev/docs/testing/accessibility-testing

---

**Status**: ✅ READY FOR IMPLEMENTATION  
**Próximo**: Disparar exemplar NfeListScreenTest (80+ linhas)
