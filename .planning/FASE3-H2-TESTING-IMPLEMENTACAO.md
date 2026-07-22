# FASE 3 H2 Flutter — Implementação de Testes

**Status**: ✅ ESTRATÉGIA CRIADA E EXEMPLAR ENTREGUE  
**Data**: 2026-07-21  
**Escopo**: Telas Responsivas + UX (cobertura 80%+, 20+ widget tests, 3 breakpoints)

---

## 📦 Artefatos Criados

### 1. Documentação Estratégica

| Arquivo | Descrição | Status |
|---------|-----------|--------|
| **FASE3-H2-TESTING-STRATEGY.md** | Estratégia completa de testes (12 seções, 400+ linhas) | ✅ CRIADO |
| **FASE3-H2-TESTING-IMPLEMENTACAO.md** | Este arquivo — guia de implementação | ✅ CRIADO |

**Localização**: `C:\App_Academia\task_manager_flutter\.planning\`

### 2. Exemplar de Widget Test

| Arquivo | Linhas | Cobertura | Status |
|---------|--------|-----------|--------|
| **test/screens/nfe/nfe_list_screen_test.dart** | 250+ | NfeListScreen | ✅ CRIADO |

**Funcionalidades testadas**:
- Estados (loading, empty, error, success)
- Responsividade (3 breakpoints: 375px, 800px, 1280px)
- Interações (cliques, filtros, paginação)
- Acessibilidade (tap targets, labels, focus)
- Erros específicos (timeout, 404, conexão)

### 3. Helpers Reutilizáveis

| Arquivo | Funções | Linhas | Status |
|---------|---------|--------|--------|
| **test/helpers/device_test_helper.dart** | 25+ helpers responsividade | 350+ | ✅ CRIADO |
| **test/helpers/nfe_test_data_factory.dart** | 20+ factory methods dados fictícios | 300+ | ✅ CRIADO |
| **test/helpers/a11y_test_helper.dart** | 18+ verificações acessibilidade | 320+ | ✅ CRIADO |

**Total de helpers**: 1,000+ linhas de código reutilizável

---

## 🚀 Como Usar (Quick Start)

### 3.1 Usar DeviceTestHelper para Testes Responsivos

```dart
import 'package:test_helpers/device_test_helper.dart';

testWidgets('Mobile layout', (tester) async {
  // Renderiza widget em tamanho mobile (375 x 667 px)
  await DeviceTestHelper.pumpWidgetWithSize(
    tester,
    buildMyWidget(),
    DeviceTestHelper.mobilePortrait,
  );

  // Assertions...
  expect(find.byType(ListView), findsOneWidget);
});

testWidgets('Desktop layout', (tester) async {
  // Renderiza widget em tamanho desktop (1280 x 720 px)
  await DeviceTestHelper.pumpWidgetWithSize(
    tester,
    buildMyWidget(),
    DeviceTestHelper.desktopWindow,
  );

  // Assertions...
});
```

### 3.2 Usar NfeTestDataFactory para Dados de Teste

```dart
import 'test_helpers/nfe_test_data_factory.dart';

test('com dados de teste', () {
  // Cria NFe individual com padrões
  final nfe = NfeTestDataFactory.createNfe(
    numero: '000001',
    status: NfeStatus.autorizada,
  );

  // Cria lista de 10 NFes
  final nfes = NfeTestDataFactory.createNfeList(10);

  // Cria estado de sucesso com dados
  final state = NfeTestDataFactory.createSuccessState(nfes);

  // Cria NFe com status específico
  final approved = NfeTestDataFactory.createAuthorizedNfe();
  final rejected = NfeTestDataFactory.createRejectedNfe();

  // Cria lista mista (para testes de filtro)
  final mixed = NfeTestDataFactory.createMixedStatusList();
});
```

### 3.3 Usar A11yTestHelper para Verificações de Acessibilidade

```dart
import 'test_helpers/a11y_test_helper.dart';

testWidgets('acessibilidade completa', (tester) async {
  await tester.pumpWidget(buildApp());

  // Verifica tap targets ≥ 48x48 dp
  A11yTestHelper.verifyMinTapTargets(tester);

  // Verifica se TextFields têm labels
  A11yTestHelper.verifyFieldLabels(tester);

  // Verifica se ícones têm tooltip
  A11yTestHelper.verifyIconLabels(tester);

  // Auditoria completa (17 verificações)
  A11yTestHelper.runCompleteA11yAudit(tester);

  // Calcula score de acessibilidade (0-100)
  final score = A11yTestHelper.calculateA11yScore(tester);
  print('Acessibilidade: $score/100');
});
```

### 3.4 Padrão Completo (NfeListScreenTest)

Ver arquivo: `test/screens/nfe/nfe_list_screen_test.dart` (250+ linhas)

Inclui:
- ✅ MockNfeRepository
- ✅ NfeTestDataFactory integration
- ✅ Testes de 3 breakpoints
- ✅ Testes de estados (loading, empty, error, success)
- ✅ Testes de interações (cliques, filtros, paginação)
- ✅ Testes de acessibilidade

---

## 📊 Estrutura de Arquivos

```
test/
├── helpers/
│   ├── device_test_helper.dart          (350+ linhas, 25+ funções)
│   ├── nfe_test_data_factory.dart       (300+ linhas, 20+ métodos)
│   └── a11y_test_helper.dart            (320+ linhas, 18+ verificações)
├── screens/
│   ├── nfe/
│   │   └── nfe_list_screen_test.dart    (250+ linhas, EXEMPLAR)
│   └── [outros...]
├── providers/
│   ├── nfe_notifier_simple_test.dart    (✓ existente)
│   └── [novos tests aqui]
└── widgets/
    └── [novos tests aqui]
```

---

## ✅ Checklist de Implementação

### Fase Atual (Wave 1 — Estratégia)

- [x] Documentação estratégica (TESTING-STRATEGY.md)
- [x] Exemplar de widget test (NfeListScreenTest)
- [x] Helper responsividade (DeviceTestHelper)
- [x] Factory dados fictícios (NfeTestDataFactory)
- [x] Helper acessibilidade (A11yTestHelper)
- [x] Documentação implementação (este arquivo)

### Próxima Fase (Wave 2 — Execução, 6-7 dias)

**Task 1: NfeDetailScreen tests** (180 linhas, 2.5 SP)
- [ ] Testes de 3 breakpoints
- [ ] Estados (loading, detail, error)
- [ ] Ações (edit, delete, download XML/PDF)
- [ ] Acessibilidade completa

**Task 2: NfeFormScreen tests** (150 linhas, 2.5 SP)
- [ ] Validação de formulário
- [ ] Testes de 3 breakpoints
- [ ] Estados (edit, create, loading)
- [ ] Keyboard navigation

**Task 3: 5 Widget tests** (5 x 100 linhas, 2.5 SP)
- [ ] NfeListTile (list item widget)
- [ ] NfeStatusBadge (status display)
- [ ] NfeFilterPanel (filter sidebar)
- [ ] NfeLoadingSkeleton (skeleton loader)
- [ ] NfeEmptyState (empty state UI)

**Task 4: E2E Integration tests** (3 flows, 2 SP)
- [ ] Flow 1: Lista → Detalhe → Ação
- [ ] Flow 2: Filtrar → Paginação
- [ ] Flow 3: Busca → Resultados

**Task 5: Golden Tests + Final** (1.5 SP)
- [ ] 8 snapshots para UI consistency
- [ ] Cobertura consolidada (80%+)
- [ ] CI/CD integration

**Total Wave 2**: 16.5 SP / 34h

---

## 🛠️ Como Executar Testes

### Rodas todos os testes

```bash
flutter test
```

### Roda testes de um diretório específico

```bash
flutter test test/screens/
flutter test test/widgets/
flutter test test/helpers/
```

### Roda um arquivo de teste específico

```bash
flutter test test/screens/nfe/nfe_list_screen_test.dart
```

### Roda um teste específico por nome

```bash
flutter test test/screens/nfe/nfe_list_screen_test.dart -k "mobile breakpoint"
```

### Roda com cobertura

```bash
flutter test --coverage

# Converte LCOV para relatório HTML (opcional)
lcov --list coverage/lcov.info
```

### Roda testes com seed (para debug flaky tests)

```bash
flutter test --test-randomize-ordering-seed 12345
```

### Visualiza teste em modo verbose

```bash
flutter test -v test/screens/nfe/nfe_list_screen_test.dart
```

---

## 📈 Métricas Esperadas (Wave 2)

### Cobertura por Tela

| Componente | Meta | Esperado |
|------------|------|----------|
| NfeListScreen | 80% | 85%+ |
| NfeDetailScreen | 80% | 85%+ |
| NfeFormScreen | 80% | 82%+ |
| 5 Widgets | 95% | 96%+ |
| NfeNotifier | 100% | 100% |
| Helpers | 90% | 92%+ |
| **Total** | **80%** | **88%+** |

### Quantidade de Testes

| Tipo | Quantidade | Total de Linhas |
|------|-----------|-----------------|
| Unit tests (notifier) | 8 suites | 800 |
| Widget tests (screens) | 12 suites | 2,000 |
| Widget tests (widgets) | 8 suites | 1,200 |
| E2E/Integration | 3 suites | 500 |
| **TOTAL** | **31 suites** | **4,500+ linhas** |

---

## 🎯 Convenções & Padrões

### Nomenclatura de Testes

```dart
// ✓ Bom
testWidgets('Mobile: exibe lista com 1 coluna', (tester) async { ... });
testWidgets('Desktop: clique em item abre detalhe', (tester) async { ... });
testWidgets('a11y: tap targets ≥ 48dp', (tester) async { ... });

// ✗ Ruim
testWidgets('test1', (tester) async { ... });
testWidgets('mobile test', (tester) async { ... });
```

### Organização de Suites

```dart
void main() {
  group('NfeListScreen — Estados', () { ... });
  group('NfeListScreen — Responsividade', () { ... });
  group('NfeListScreen — Interações', () { ... });
  group('NfeListScreen — Acessibilidade', () { ... });
}
```

### Setup & Teardown

```dart
setUp(() {
  mockRepository = MockNfeRepository();
  notifier = NfeNotifier(mockRepository);
});

tearDown(() {
  mockRepository.reset();
});
```

### Factory para BuildContext

```dart
Widget buildScreen() => MaterialApp(
  home: ChangeNotifierProvider<NfeNotifier>.value(
    value: notifier,
    child: const NfeListScreen(),
  ),
);
```

---

## ⚠️ Guardrails & Avisos

### Não Fazer

- ❌ Alterar `nfe_notifier_simple_test.dart` (já em produção)
- ❌ Fazer chamadas HTTP reais em testes widget (usar mocks)
- ❌ Deixar estado entre testes (usar `setUp`/`tearDown`)
- ❌ Usar `tester.pumpAndSettle()` excessivamente (performance)
- ❌ Testar detalhes de implementação (testar comportamento)

### Fazer

- ✅ Usar mocks consistentes (MockNfeRepository, MockNfeNotifier)
- ✅ Reutilizar helpers (DeviceTestHelper, NfeTestDataFactory)
- ✅ Testar 3 breakpoints por tela responsiva
- ✅ Documentar testes não óbvios
- ✅ Rodar testes localmente antes de push

---

## 📚 Referências

### Flutter Testing Docs
- [Widget Testing Guide](https://flutter.dev/docs/testing/widget-test-introduction)
- [Unit Testing](https://flutter.dev/docs/testing/unit-testing)
- [Integration Testing](https://flutter.dev/docs/testing/integration-tests)
- [Accessibility Testing](https://flutter.dev/docs/testing/accessibility-testing)

### Mockito
- [Pub.dev mockito](https://pub.dev/packages/mockito)
- [GitHub mockito-dart](https://github.com/dart-lang/mockito)

### Material Design Accessibility
- [Material a11y](https://material.io/design/usability/accessibility.html)
- [WCAG Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)

---

## 📋 Próximos Passos

### Imediato (Esta semana)
1. ✅ Revisar TESTING-STRATEGY.md
2. ✅ Estudar exemplar NfeListScreenTest
3. ✅ Validar que helpers rodam sem erros
4. → **Feedback & Aprovação PO**

### Curto Prazo (Próxima semana)
1. Disparar Task 1: NfeDetailScreen tests
2. Disparar Task 2: NfeFormScreen tests
3. Disparar Task 3: 5 Widget tests (paralelo)

### Médio Prazo (2 semanas)
1. Task 4: E2E flows
2. Task 5: Golden tests + consolidação
3. Validação cobertura 80%+
4. **Deploy & QA Regression**

---

## 🎓 Exemplos de Uso

### Exemplo 1: Teste Simples

```dart
testWidgets('Exibe lista de NFes', (tester) async {
  final nfes = NfeTestDataFactory.createNfeList(3);
  mockRepository.setMockData(nfes);

  await tester.pumpWidget(buildScreen());
  await tester.pumpAndSettle();

  expect(find.text('000001'), findsOneWidget);
});
```

### Exemplo 2: Teste de Responsividade

```dart
testWidgets('Mobile vs Desktop layout', (tester) async {
  final nfes = NfeTestDataFactory.createNfeList(5);
  notifier._setState(notifier.state.copyWith(nfes: nfes));

  // Mobile
  await DeviceTestHelper.pumpWidgetWithSize(
    tester,
    buildScreen(),
    DeviceTestHelper.mobilePortrait,
  );
  expect(find.byType(ListView), findsOneWidget);

  // Desktop
  await DeviceTestHelper.pumpWidgetWithSize(
    tester,
    buildScreen(),
    DeviceTestHelper.desktopWindow,
  );
  // Pode ser Grid em desktop
});
```

### Exemplo 3: Teste de Acessibilidade

```dart
testWidgets('Acessibilidade', (tester) async {
  await tester.pumpWidget(buildScreen());

  // Verifica todos os tap targets
  A11yTestHelper.verifyMinTapTargets(tester);

  // Verifica labels em inputs
  A11yTestHelper.verifyFieldLabels(tester);

  // Calcula score
  final score = A11yTestHelper.calculateA11yScore(tester);
  expect(score, greaterThan(80));
});
```

---

## 📞 Suporte

Para dúvidas ou problemas:
1. Consultar `FASE3-H2-TESTING-STRATEGY.md` (seções relevantes)
2. Ver exemplar `nfe_list_screen_test.dart`
3. Revisar helpers (`device_test_helper.dart`, etc.)
4. Consultar Flutter Testing Docs (links em "Referências")

---

**Status**: ✅ PRONTO PARA EXECUÇÃO  
**Próximo**: Disparar PO review → Task 1 (NfeDetailScreen)

Documento gerado automaticamente. Última atualização: 2026-07-21
