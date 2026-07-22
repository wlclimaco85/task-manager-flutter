# PATTERNS.md — Arquitetura Responsiva Flutter AppAcademia

**Data**: 2026-07-21  
**Escopo**: `task_manager_flutter` — Padrões layout, widgets, breakpoints, plataformas  
**Objetivo**: Mapear estrutura responsiva existente + reutilização NFe Fase 3  

---

## 1. Breakpoint Consolidado

### Definição Global

Arquivo: `lib/core/responsive/responsive_helper.dart`

```dart
enum Breakpoint { mobile, tablet, desktop }

class ResponsiveHelper {
  static const int breakpointMobile = 768;    // < 768px
  static const int breakpointTablet = 1024;   // 768px - 1024px
  // Desktop >= 1024px
}
```

### Razão: Unificação

- **ResponsiveHelper** define: `768`, `1024`
- **ResponsiveWidget**: `768`, `1024` (cópia)
- **ResponsiveGridLayout**: `768`, `1024` (cópia)
- **tablet_breakpoint_styles.dart**: min=600, max=1023 (diferente!)
- **mobile_breakpoint_styles.dart**: min=375, max=599 (range, não breakpoint)

**Problema**: Inconsistência `tablet_breakpoint_styles` (min=600, max=1023) vs ResponsiveHelper (768-1024)

**Recomendação**: Consolidar em `lib/core/responsive/breakpoints.dart`
```dart
class Breakpoints {
  static const int mobile = 768;     // < 768: mobile
  static const int tablet = 1024;    // 768-1024: tablet
  static const int desktop = 1024;   // >= 1024: desktop
}
```
Importar de uma única fonte em todos os widgets.

---

## 2. Layout Patterns — LayoutBuilder vs ResponsiveWidget

### Pattern A: ResponsiveWidget (Recomendado)

Arquivo: `lib/widgets/responsive_widget.dart`

**Uso**: Stack vertical com builders por breakpoint
```dart
ResponsiveWidget(
  mobileBuilder: (ctx, width) => _buildMobileLayout(),
  tabletBuilder: (ctx, width) => _buildTabletLayout(),  // opcional
  desktopBuilder: (ctx, width) => _buildDesktopLayout(), // opcional
)
```

**Características**:
- ✅ Fallback automático (desktop → tablet → mobile)
- ✅ Builders recebem width (constraints.maxWidth)
- ✅ Usado em: `dashboard_screen.dart`, `responsive_sidebar.dart`
- ❌ Não captura altura (constraints.maxHeight)

### Pattern B: LayoutBuilder direto

Arquivo: Várias telas (`features/diario_nutricional_screen.dart`, `nfe_list_screen.dart`)

**Uso**: Lógica customizada
```dart
body: LayoutBuilder(builder: (context, constraints) {
  final width = constraints.maxWidth;
  if (width < 800) return _buildMobileLayout();
  return _buildWebLayout();
})
```

**Problema**: Hardcoded breakpoint `800` (deveria ser `768`)

---

## 3. Widgets Reutilizáveis Existentes

### 3.1 Responsive Grid

Arquivo: `lib/widgets/responsive/responsive_grid_layout.dart`

```dart
ResponsiveGridLayout(
  children: nfes.map((nfe) => NfeCard(nfe: nfe)).toList(),
  padding: EdgeInsets.all(16),
  spacing: 12,      // crossAxisSpacing
  runSpacing: 12,   // mainAxisSpacing
)
```

**Breakpoints**:
- Mobile: 1 coluna
- Tablet: 2 colunas
- Desktop: 3 colunas

**Reutilizável para**: Cards NFe, Cards itens

### 3.2 Responsive Sidebar

Arquivo: `lib/widgets/responsive/responsive_sidebar.dart`

```dart
ResponsiveSidebar(
  items: [
    SidebarItem(title: 'Emissão'),
    SidebarItem(title: 'Consulta'),
  ],
  header: MyHeader(),
  footer: MyFooter(),
  backgroundColor: Colors.grey[200],
)
```

**Breakpoints**:
- Mobile: Hidden (drawer/hamburger)
- Tablet: Collapsible 200px
- Desktop: Permanent 250px

### 3.3 Responsive Button Bar

Arquivo: `lib/widgets/responsive/responsive_button_bar.dart`

**Uso**: Botões de ação (Emitir, Cancelar, Download, XML Viewer)

### 3.4 NFCe DANFE Widget

Arquivo: `lib/widgets/nfce/nfce_danfe_panel.dart`

**Detecção Plataforma**:
```dart
final _usaSalvarArquivo = kIsWeb || 
  switch (defaultTargetPlatform) {
    TargetPlatform.windows || TargetPlatform.linux => true,
    _ => false,
  };
```

**Plataforma-específico**:
- Web/Desktop: Salva PDF local
- Mobile: Compartilha (Share Plus)

---

## 4. Telas NFe — Padrão Atual

### 4.1 nfe_list_screen.dart

**Localização**: `lib/screens/nfe/nfe_list_screen.dart`

**Estrutura**:
```
NfeListScreen (StatefulWidget)
├── FilterSection (Card com 4 campos)
│   ├── TextField (Número NFe)
│   ├── DropdownButtonFormField (Status)
│   └── Row de DatePickers
├── Content (condicional)
│   ├── Loading
│   ├── Error
│   ├── Empty
│   └── _NfeListView (DataTable + Paginação)
```

**Responsividade Atual**:
- Detecta breakpoint: `isMobile = width < 800` (problema: hardcoded)
- Row com data pickers sempre horizontal (quebra em mobile < 600px)
- DataTable com `SingleChildScrollView` horizontal

**Problemas**:
- ❌ Não usa ResponsiveHelper (breakpoint 800 vs 768)
- ❌ FilterSection não adapta para 3+ telas (sempre column)
- ❌ DataTable ruim em mobile (<600px) — texto sobreposto
- ❌ Paginação Row não adapta para móbil
- ⚠️ `const` não usado em widgets privados (_LoadingWidget, etc) → rebuild unnecessário

### 4.2 nfe_detail_screen.dart

**Localização**: `lib/screens/nfe/nfe_detail_screen.dart`

**Estrutura**:
```
NfeDetailScreen (StatefulWidget, recebe nfeId)
├── HeaderCard (NFe número, status, emitente)
├── Mobile Layout:
│   ├── InfoCard
│   ├── ItensExpandable (DataTable)
│   ├── ImpostosExpandable
│   └── ActionButtons
└── Web Layout (2 colunas):
    ├── Left Column:
    │   ├── InfoCard
    │   └── ImpostosExpandable
    └── Right Column:
        ├── ItensExpandable
        └── ActionButtons
```

**Responsividade**:
- Detecta: `isMobile = width < 800`
- Renderiza 2 layouts completamente diferentes
- ✅ Bom padrão mobile-first, mas hardcoded breakpoint

**Padrão Reutilizável**:
```dart
isMobile ? _buildMobileLayout() : _buildWebLayout()
```

---

## 5. Plataformas — Estrutura por Diretório

### 5.1 Estrutura de Telas

| Diretório | Plataforma | Padrão | Status |
|-----------|-----------|--------|--------|
| `lib/screens/nfe/` | Multiplataforma | StatefulWidget genérico | ✅ Existente |
| `lib/mobile/screens/` | iOS/Android | ~60 telas específicas | ✅ Existente |
| `lib/web/screens/` | Web/Chrome | ~80 telas com grid layout | ✅ Existente |
| `lib/windows/screens/` | Windows | 5-10 telas Windows | ✅ Existente |

### 5.2 NFe por Plataforma

**Atual**:
- `lib/screens/nfe/nfe_list_screen.dart` — Multiplataforma (ResponsiveWidget fallback)
- `lib/screens/nfe/nfe_detail_screen.dart` — Multiplataforma (isMobile ternário)

**Não Encontrado**:
- `lib/mobile/screens/nfe_list_screen.dart`
- `lib/web/screens/nfe_list_screen.dart`
- `lib/windows/screens/nfe_list_screen.dart`

**Padrão Adotado**: Telas genéricas em `lib/screens/` + breakpoints responsivos

---

## 6. DataTable — Problema em Mobile

### Padrão Atual

```dart
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: DataTable(
    columns: [/* 6 colunas */],
    rows: nfes.map((nfe) => DataRow(...)).toList(),
  ),
)
```

**Problema**: DataTable + 6 colunas em mobile (<600px) → texto truncado, experiência ruim

### Alternativa: Cards Mobile

Para NFe lista em mobile, usar cards em vez de DataTable:
```dart
ResponsiveWidget(
  mobileBuilder: (ctx, w) => ListView(
    children: nfes.map((nfe) => NfeCard(nfe: nfe)).toList(),
  ),
  desktopBuilder: (ctx, w) => DataTable(...),
)
```

---

## 7. Const Constructors — Oportunidades

### Achados

| Arquivo | Uso | Status |
|---------|-----|--------|
| `nfe_list_screen.dart` linha 260-270 | `_LoadingWidget` | ❌ Sem `const` na classe |
| `nfe_list_screen.dart` linha 319-320 | `_EmptyWidget` | ❌ Sem `const` |
| `nfe_detail_screen.dart` | Todos os helpers | ✅ Interna (OK) |

**Recomendação**:
```dart
class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget({Key? key}) : super(key: key);
  // ...
}

// Uso:
const _LoadingWidget()  // Agora com const
```

---

## 8. Design Tokens — Estrutura Responsiva

Arquivo: `lib/core/design/design_tokens.dart`

### Cores Consolidadas

Tokens base (usados por breakpoints):
- **Primary**: `#93070A` (Vermelho AppAcademia)
- **Secondary**: `#005826` (Verde)
- **Success**: `#2E7D32`
- **Error**: `#D32F2F`
- **Warning**: `#FFA000`

### Tipografia por Breakpoint

| Breakpoint | Logo | H1 | H2 | Body | Caption |
|-----------|------|-----|-----|------|---------|
| **Mobile** | 32px | 24px | 20px | 14px | 12px |
| **Tablet** | 36px | 28px | 24px | 16px | 13px |
| **Desktop** | 40px | 32px | 28px | 18px | 14px |

Arquivo: `lib/core/theme/{mobile,tablet,desktop}_breakpoint_styles.dart`

### Spacing por Breakpoint

| Tipo | Mobile | Tablet | Desktop |
|------|--------|--------|---------|
| Container Padding | 8px | 16px | 24px |
| Element Margin | 8px | 16px | 24px |
| Section Gap | 16px | 24px | 32px |
| Button Height | 40px | 44px | 48px |

---

## 9. Padrões Encontrados — Mapa Rápido

### ✅ Implementado

| Padrão | Arquivo | Uso |
|--------|---------|-----|
| **ResponsiveWidget** | `lib/widgets/responsive_widget.dart` | Seletor builder por breakpoint |
| **ResponsiveGridLayout** | `lib/widgets/responsive/responsive_grid_layout.dart` | Grid 1-2-3 colunas |
| **ResponsiveSidebar** | `lib/widgets/responsive/responsive_sidebar.dart` | Drawer/collapsible/permanent |
| **ResponsiveHelper** | `lib/core/responsive/responsive_helper.dart` | Enum + métodos breakpoint |
| **LayoutBuilder** | 10+ telas | Lógica customizada |
| **MediaQuery** | `nfe_list_screen.dart` | Detecção width direto |
| **Plataforma Detection** | `nfce_danfe_panel.dart` | `kIsWeb`, `defaultTargetPlatform` |

### ⚠️ Inconsistências

1. **Breakpoint**: ResponsiveHelper (768/1024) ≠ tablet_breakpoint_styles (600/1023)
2. **Hardcoded Values**: `width < 800` em nfe_*.dart (deveria ser `< 768`)
3. **Fallback Telas**: Não há `lib/mobile/screens/nfe_*` — tudo genérico

### ❌ Não Encontrado

| Padrão | Razão | Recomendação |
|--------|-------|--------------|
| **SliverList** | Não há scroll performance crítica | OK (não necessário) |
| **StreamBuilder Responsivo** | Estado via Provider | ✅ Atual funciona |
| **FractionallySizedBox** | Row/Expanded suficientes | OK |

---

## 10. Recomendações — Fase 3 NFe

### 10.1 Unificar Breakpoints

**Arquivo novo**: `lib/core/responsive/breakpoints.dart`
```dart
abstract class Breakpoints {
  static const int mobile = 768;
  static const int tablet = 1024;
  // Use em: ResponsiveHelper, tablet_breakpoint_styles, todos widgets
}
```

### 10.2 Criar NfeCard (Mobile Friendly)

**Arquivo**: `lib/widgets/nfe/nfe_card.dart`
```dart
class NfeCard extends StatelessWidget {
  final NfeModel nfe;
  const NfeCard({required this.nfe});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NFe ${nfe.numeroFormatado}', style: Theme.of(context).textTheme.titleMedium),
            Text('Status: ${nfe.statusNfe.label}'),
            Text('R\$ ${nfe.valores.total.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}
```

### 10.3 Refatorar nfe_list_screen.dart

**Mudanças**:
1. Usar `ResponsiveHelper` para breakpoint (não 800)
2. Substituir DataTable por Cards em mobile (ResponsiveWidget)
3. Filtros adaptativos: Mobile (stack) → Desktop (grid)
4. Adicionar `const` em widgets privados

### 10.4 Refatorar nfe_detail_screen.dart

**Mudanças**:
1. Manter padrão 2-layout (mobile/desktop)
2. Adaptar DataTable itens (Cards mobile)
3. Adicionar tablet layout (3 colunas ou 2 colunas + sidebar)

### 10.5 Criar BaseDataTable (wrapper seguro)

**Arquivo**: `lib/widgets/responsive/responsive_data_table.dart`
```dart
class ResponsiveDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveWidget(
      mobileBuilder: (ctx, w) => _buildCardList(),   // Fallback cards
      desktopBuilder: (ctx, w) => _buildDataTable(), // Real DataTable
    );
  }
}
```

---

## 11. Resumo — Próximas Ações

| Item | Status | Prioridade | Arquivo |
|------|--------|-----------|---------|
| Unificar breakpoints | ❌ TODO | P0 | `breakpoints.dart` novo |
| Criar NfeCard widget | ❌ TODO | P1 | `lib/widgets/nfe/nfe_card.dart` novo |
| Refatorar nfe_list_screen | ❌ TODO | P1 | `nfe_list_screen.dart` editar |
| Refatorar nfe_detail_screen | ❌ TODO | P1 | `nfe_detail_screen.dart` editar |
| Criar ResponsiveDataTable | ❌ TODO | P2 | `responsive_data_table.dart` novo |
| Documentar patterns | ✅ DONE | P3 | PATTERNS.md (este arquivo) |

---

## 12. Referência Rápida — Imports

```dart
// Breakpoints e helpers
import 'package:task_manager_flutter/core/responsive/responsive_helper.dart';
import 'package:task_manager_flutter/widgets/responsive_widget.dart';

// Widgets responsivos
import 'package:task_manager_flutter/widgets/responsive/responsive_grid_layout.dart';
import 'package:task_manager_flutter/widgets/responsive/responsive_sidebar.dart';

// Design tokens
import 'package:task_manager_flutter/core/design/design_tokens.dart';
import 'package:task_manager_flutter/core/theme/mobile_breakpoint_styles.dart';

// Detecção plataforma
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';   // defaultTargetPlatform
```

---

**Gerado**: 2026-07-21 | **Revisão**: Ready for Fase 3 NFe implementation
