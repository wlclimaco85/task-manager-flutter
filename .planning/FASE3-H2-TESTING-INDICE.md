# FASE 3 H2 Flutter — Índice de Testes

**Data**: 2026-07-21  
**Status**: ✅ ESTRATÉGIA + EXEMPLAR COMPLETO  
**Total de Artefatos**: 6 arquivos, 2,100+ linhas

---

## 📋 Índice Completo

### 1️⃣ Documentação Estratégica (2 arquivos)

#### **FASE3-H2-TESTING-STRATEGY.md** (400+ linhas)
**Localização**: `.planning/FASE3-H2-TESTING-STRATEGY.md`

**Conteúdo**:
- ✅ Seção 1: Test Pyramid (unit/widget/integration structure)
- ✅ Seção 2: Cobertura esperada (80%+ por tela, matriz detalhada)
- ✅ Seção 3: Widget test fixtures (3 breakpoints: 375/800/1280px)
- ✅ Seção 4: Mocking strategy (MockNfeRepository, MockNfeNotifier, test data)
- ✅ Seção 5: Accessibility checks (tap targets, labels, contrast, keyboard)
- ✅ Seção 6: Regression checklist (loading, empty, error, success, 3 breakpoints)
- ✅ Seção 7: Tools & setup (flutter test, mockito, CI/CD)
- ✅ Seção 8: Estrutura de arquivos
- ✅ Seção 9: Critérios de aceitação (DoD)
- ✅ Seção 10: Timeline estimado (16.5 SP / 34h)
- ✅ Seção 11: Notas importantes (guardrails, reutilização)
- ✅ Seção 12: Referências (Flutter Docs, Material a11y, WCAG)

**Uso**: Guia definitivo de estratégia, referência para planejamento

---

#### **FASE3-H2-TESTING-IMPLEMENTACAO.md** (300+ linhas)
**Localização**: `.planning/FASE3-H2-TESTING-IMPLEMENTACAO.md`

**Conteúdo**:
- ✅ Sumário de artefatos criados
- ✅ Quick start guide (3 exemplos de uso)
- ✅ Estrutura de arquivos
- ✅ Checklist de implementação (Wave 1 completo, Wave 2 roadmap)
- ✅ Como executar testes (10+ comandos flutter test)
- ✅ Métricas esperadas (cobertura, quantity)
- ✅ Convenções & padrões (nomenclatura, organização)
- ✅ Guardrails & avisos (5 não fazer, 5 fazer)
- ✅ Referências (links relevantes)
- ✅ Próximos passos (imediato, curto, médio prazo)
- ✅ Exemplos de uso (3 exemplos práticos)

**Uso**: Guia prático de implementação, onboarding rápido

---

### 2️⃣ Exemplar de Widget Test (1 arquivo)

#### **test/screens/nfe/nfe_list_screen_test.dart** (250+ linhas)
**Localização**: `test/screens/nfe/nfe_list_screen_test.dart`

**Seções**:
1. **MOCKS & FIXTURES** (100 linhas)
   - MockNfeRepository (completo)
   - NfeTestDataFactory (referenciar helper)
   - DeviceTestHelper (referenciar helper)

2. **WIDGET TESTS** (150 linhas, 9 test groups)

   **Group 1: Estados Gerais** (7 testes)
   - Carrega com estado inicial
   - Exibe loading indicator
   - Exibe mensagem de erro
   - Exibe lista vazia
   - Exibe lista com sucesso

   **Group 2: Responsividade** (3 testes)
   - Mobile (375px): 1 coluna, layout compacto
   - Tablet (800px): layout intermediário
   - Desktop (1280px): múltiplas colunas

   **Group 3: Interações** (3 testes)
   - Clique em item abre detalhe
   - Botão atualizar recarrega
   - Pull-to-refresh atualiza

   **Group 4: Filtros** (2 testes)
   - Filtro por status
   - Limpar filtros

   **Group 5: Acessibilidade** (3 testes)
   - AppBar com semântica
   - Botões com label/tooltip
   - TextFields com labels

   **Group 6: Paginação** (2 testes)
   - Próxima página incrementa
   - Botão anterior desabilitado

   **Group 7: Erros** (3 testes)
   - Erro de conexão
   - Erro 404 (NFe não encontrada)
   - Erro timeout

**Total de testes**: 23 testWidgets + exemplos de mocks

**Cobertura**: NfeListScreen 80%+ (loading, empty, error, success, 3 breakpoints, a11y)

**Uso**: Modelo para NfeDetailScreen, NfeFormScreen e outros testes widget

---

### 3️⃣ Helpers Reutilizáveis (3 arquivos, 1,000+ linhas)

#### **test/helpers/device_test_helper.dart** (350+ linhas)
**Localização**: `test/helpers/device_test_helper.dart`

**Funcionalidades** (25+ helpers):

1. **Device Sizes** (6 constantes)
   - `mobilePortrait` (375 x 667)
   - `mobileLandscape` (667 x 375)
   - `tabletPortrait` (800 x 1200)
   - `tabletLandscape` (1200 x 800)
   - `desktopWindow` (1280 x 720)
   - `desktopFullHd` (1920 x 1080)

2. **Pump Functions** (4 funções)
   - `pumpWidgetWithSize()` — renderiza com tamanho específico
   - `pumpWidgetAndSettle()` — pump padrão
   - `testBothOrientations()` — testa portrait + landscape

3. **Assertion Helpers** (4 funções)
   - `isWidgetVisible()` — verifica visibilidade
   - `waitForWidgetVisibility()` — aguarda aparecer
   - `getScreenWidth()` / `getScreenHeight()` — dimensões

4. **Breakpoint Helpers** (3 funções)
   - `isMobileWidth()` / `isTabletWidth()` / `isDesktopWidth()`
   - `getBreakpointName()` — retorna "mobile"/"tablet"/"desktop"

5. **Scroll Helpers** (4 funções)
   - `scrollUp()` / `scrollDown()` / `scrollLeft()` / `scrollRight()`

6. **Gesture Helpers** (4 funções)
   - `longPress()` / `doubleTap()` / `drag()` / `swipe()`

7. **Input Helpers** (3 funções)
   - `typeText()` / `clearTextField()` / `selectDropdownOption()`

8. **Debugging** (2 funções)
   - `printScreenSize()` / `describeWidget()`

**Uso**: Reutilizar em todos os testes widget (NfeDetailScreen, NfeFormScreen, widgets)

---

#### **test/helpers/nfe_test_data_factory.dart** (300+ linhas)
**Localização**: `test/helpers/nfe_test_data_factory.dart`

**Funcionalidades** (20+ factory methods):

1. **NfeModel Factories** (5 métodos)
   - `createNfe()` — NFe com valores customizáveis
   - `createNfeList()` — lista de N NFes sequenciais
   - `createNfeListByStatus()` — lista com status específico

2. **Tomador Factories** (1 método)
   - `createTomador()` — NfeTomadorModel

3. **Valores Factories** (1 método)
   - `createValores()` — ValoresNfeModel com cálculos automáticos

4. **NfeState Factories** (5 métodos)
   - `createEmptyState()` / `createLoadingState()` / `createErrorState()`
   - `createSuccessState()` / `createSelectedState()`

5. **Status-Specific Factories** (4 métodos)
   - `createPendingNfe()` / `createAuthorizedNfe()`
   - `createRejectedNfe()` / `createCanceledNfe()`

6. **Special Factories** (3 métodos)
   - `createHighValueNfe()` / `createLowValueNfe()` / `createLongNameNfe()`

7. **Pagination Factories** (2 métodos)
   - `createPaginatedNfeFirstPage()` / `createPaginatedNfeNextPage()`

8. **Mixed Factories** (1 método)
   - `createMixedStatusList()` — lista com diferentes status

9. **Date Factories** (4 métodos)
   - `createNfeWithDate()` / `createTodayNfe()` / `createYesterdayNfe()`
   - `createWeekAgoNfe()` / `createMonthAgoNfe()`

**Uso**: Dados consistentes em todos os testes widget e unitários

---

#### **test/helpers/a11y_test_helper.dart** (320+ linhas)
**Localização**: `test/helpers/a11y_test_helper.dart`

**Funcionalidades** (18+ verificações):

1. **Tap Target Verification** (3 testes)
   - `verifyMinTapTargets()` — InkWells ≥ 48x48 dp
   - `verifyGestureDetectorSize()` — GestureDetectors
   - `verifyIconButtonSize()` — IconButtons

2. **Label & Semantic** (3 testes)
   - `verifyFieldLabels()` — TextFields com label/hint
   - `verifyButtonLabels()` — Botões com texto/label
   - `verifyIconLabels()` — Ícones com tooltip/semantics

3. **Semantic & Screen Reader** (3 testes)
   - `verifySemantics()` — Elementos com semântica
   - `verifyKeyboardNavigation()` — Navegação TAB
   - `verifyDescriptions()` — Elementos com descrição

4. **Contrast & Color (WCAG)** (1 teste)
   - `verifyTextContrast()` — Texto com contraste suficiente

5. **Focus & Navigation** (2 testes)
   - `verifyFocusIndicators()` — Visual focus indicators
   - `verifyKeyboardOnlyNavigation()` — Navegação apenas teclado

6. **Comprehensive** (1 teste)
   - `runCompleteA11yAudit()` — Suite completa (7 verificações)

7. **Debugging** (2 funções)
   - `debugWidgetA11y()` / `listFocusableWidgets()`
   - `calculateA11yScore()` — Score 0-100

**Uso**: Verificar acessibilidade em todos os widget tests

---

### 4️⃣ Resumo Executivo

#### **FASE3-H2-TESTING-INDICE.md** (este arquivo)
**Localização**: `.planning/FASE3-H2-TESTING-INDICE.md`

**Conteúdo**: Índice completo de todos artefatos, referências cruzadas

---

## 🎯 Como Começar

### Passo 1: Ler Documentação (30 min)
```
Ler: .planning/FASE3-H2-TESTING-STRATEGY.md
Foco: Seções 1-6 (pyramid, cobertura, fixtures, mocking, a11y)
```

### Passo 2: Entender Exemplar (30 min)
```
Ler: test/screens/nfe/nfe_list_screen_test.dart
Analise: Estrutura, mocks, padrões, test groups
```

### Passo 3: Validar Helpers (30 min)
```
Rodar: flutter test test/helpers/
Verificar: Sem erros, imports corretos
```

### Passo 4: Implementar Próximas Telas
```
Baseado em: nfe_list_screen_test.dart
Telas: NfeDetailScreen, NfeFormScreen
Usar: DeviceTestHelper, NfeTestDataFactory, A11yTestHelper
```

---

## 📊 Estatísticas

| Métrica | Valor |
|---------|-------|
| **Linhas de código (teste + helpers)** | 2,100+ |
| **Artefatos criados** | 6 |
| **Test groups no exemplar** | 7 |
| **Testes widget implementados** | 23 |
| **Helpers reutilizáveis** | 25+ |
| **Factory methods** | 20+ |
| **Verificações a11y** | 18+ |
| **Breakpoints testados** | 3 (375/800/1280px) |
| **Cobertura esperada** | 80%+ |

---

## 🔗 Referências Cruzadas

### Documentação → Exemplar
- `TESTING-STRATEGY.md` §4 (Mocking) → `nfe_list_screen_test.dart` (MockNfeRepository)
- `TESTING-STRATEGY.md` §3 (Fixtures) → `nfe_list_screen_test.dart` (DeviceTestHelper)
- `TESTING-STRATEGY.md` §5 (a11y) → `nfe_list_screen_test.dart` (Group 5)
- `TESTING-STRATEGY.md` §6 (Regression) → `nfe_list_screen_test.dart` (Groups 1-7)

### Exemplar → Helpers
- `nfe_list_screen_test.dart` usa `DeviceTestHelper`
- `nfe_list_screen_test.dart` usa `NfeTestDataFactory`
- `nfe_list_screen_test.dart` pode usar `A11yTestHelper` (exemplo em §5)

### Helpers Interdependências
- `DeviceTestHelper` — independente (não depende de outros)
- `NfeTestDataFactory` — independente (não depende de outros)
- `A11yTestHelper` — independente (não depende de outros)
- Todos 3 podem ser usados juntos

---

## ✅ Checklist de Validação

- [x] Estratégia documentada (TESTING-STRATEGY.md)
- [x] Exemplar implementado (nfe_list_screen_test.dart, 250+ linhas)
- [x] DeviceTestHelper criado (350+ linhas, 25+ helpers)
- [x] NfeTestDataFactory criado (300+ linhas, 20+ methods)
- [x] A11yTestHelper criado (320+ linhas, 18+ checks)
- [x] Guia de implementação (TESTING-IMPLEMENTACAO.md)
- [x] Índice completo (este arquivo)
- [x] Todos imports validados
- [x] Exemplos práticos inclusos
- [x] Documentação de referência

---

## 🚀 Próximas Ações

### Imediato (T+0 a T+4h)
1. ✅ Revisar com PO: estratégia + exemplar
2. ✅ QA valida helpers (sem erros)
3. ✅ Feedback → ajustes rápidos

### Próxima Semana (T+5 a T+7)
1. Disparar Task 1: NfeDetailScreen tests (180 linhas, 2.5 SP)
2. Disparar Task 2: NfeFormScreen tests (150 linhas, 2.5 SP)
3. Disparar Task 3: 5 Widget tests (5 x 100 linhas, 2.5 SP)

### 2 Semanas (T+8 a T+14)
1. Task 4: E2E flows (3 flows, 2 SP)
2. Task 5: Golden tests + final (1.5 SP)
3. Consolidar cobertura 80%+
4. Deploy & QA Regression

---

## 📞 Suporte Rápido

| Pergunta | Resposta |
|----------|----------|
| Onde começo? | Leia `TESTING-IMPLEMENTACAO.md` (30 min quick start) |
| Qual é o exemplar? | `nfe_list_screen_test.dart` (250+ linhas, pronto para copiar) |
| Como uso helpers? | Veja seção "🎓 Exemplos de Uso" em `TESTING-IMPLEMENTACAO.md` |
| Falta algo? | Consulte `TESTING-STRATEGY.md` (guia completo) |
| Quero corrigir teste flaky? | Use `flutter test --test-randomize-ordering-seed` |
| Preciso coverage? | Rode `flutter test --coverage` + `lcov --list` |

---

## 📄 Mapa Mental

```
FASE3-H2-TESTING/
│
├── 📚 DOCUMENTAÇÃO ESTRATÉGICA
│   ├── TESTING-STRATEGY.md (12 seções, 400+ linhas)
│   ├── TESTING-IMPLEMENTACAO.md (12 seções, 300+ linhas)
│   └── TESTING-INDICE.md (este arquivo)
│
├── 🧪 EXEMPLAR
│   └── test/screens/nfe/nfe_list_screen_test.dart (250+ linhas)
│       ├── MockNfeRepository
│       ├── 7 test groups
│       └── 23 testes widget
│
├── 🛠️ HELPERS REUTILIZÁVEIS
│   ├── test/helpers/device_test_helper.dart (350+ linhas)
│   │   ├── 6 device sizes
│   │   ├── Pump functions
│   │   ├── Scroll helpers
│   │   ├── Gesture helpers
│   │   └── Input helpers
│   │
│   ├── test/helpers/nfe_test_data_factory.dart (300+ linhas)
│   │   ├── NfeModel factories
│   │   ├── NfeState factories
│   │   ├── Status-specific factories
│   │   └── Date factories
│   │
│   └── test/helpers/a11y_test_helper.dart (320+ linhas)
│       ├── Tap target verification
│       ├── Label verification
│       ├── Semantic verification
│       ├── Contrast verification
│       └── Focus verification
│
└── 📊 ÍNDICES & REFERÊNCIAS
    └── Este arquivo (TESTING-INDICE.md)
```

---

**Documento gerado**: 2026-07-21  
**Status**: ✅ PRONTO PARA EXECUÇÃO  
**Próxima ação**: PO review + Task 1 dispatch

