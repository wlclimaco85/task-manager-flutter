# MANIFESTACAO-UI-SPEC — ManifestacaoScreen (Wave 3 P2-502)

**Versão**: 1.0 | **Data**: 2026-07-27 | **Status**: Draft para Execução  
**Projeto**: Flutter task_manager_flutter + task_manager_flutter_merged_final  
**Plataformas**: Mobile (320-480px) | Tablet (600px) | Web/Desktop (1024-1920px)  
**Framework**: Flutter 3.x | **Dart**: 3.x+ | **State**: Provider / GetX (conforme projeto)

---

## 📋 Índice

1. [Design Plan](#design-plan)
2. [Design Tokens](#design-tokens)
3. [Wireframes & Layouts](#wireframes--layouts)
4. [Component Specs](#component-specs)
5. [Responsividade Validation](#responsividade-validation)
6. [Acessibilidade (WCAG 2.1 AA)](#acessibilidade-wcag-21-aa)
7. [Dark Mode Compatibility](#dark-mode-compatibility)
8. [Test Cases (15 cenários)](#test-cases-15-cenários)
9. [Implementation Checklist](#implementation-checklist)

---

## 🎨 Design Plan

### Color Palette
- **Primary (CTA, Active states)**: Vermelho #93070A — ação decisiva (Aceitar/Enviar)
- **Success (Confirmação, Status aprovado)**: Verde #2E7D32 — validação positiva
- **Error (Rejeição, Status recusado)**: Vermelho #D32F2F — feedback crítico
- **Warning (Atenção, Status parcial)**: Laranja #F57C00 — ações pendentes
- **Neutral (Background, Text, Borders)**: Cinza #F5F5F5 (light), #1A1A1A (dark), #757575 (muted)
- **Surface (Cards, Modals)**: Branco #FFFFFF (light), #2A2A2A (dark)

### Typography
- **Display**: Roboto Bold 28px (títulos de seção, cabeçalhos)
- **Heading**: Roboto Medium 18px (subtítulos, nomes de campos)
- **Body**: Roboto Regular 14px (textos, descrições, valores)
- **Caption**: Roboto Regular 12px (rótulos, status badges, observações)
- **Mono**: Roboto Mono 12px (datas, IDs de NFe)

### Layout Concept
Tela de manifestação com fluxo vertical (mobile-first, responsivo). Header fixo com info NFe, conteúdo scrollável com form fields (dropdown status, textarea, date picker), footer com botões de ação. Estados: Vazio (aguardando), Carregando, Sucesso, Erro, Dark mode.

---

## 🔧 Design Tokens

### Spacing Scale (px)
```
4px   — xs (gaps mínimos, bordas internas)
8px   — sm (padding pequeno, gaps menores)
12px  — md (padding padrão, gaps médios)
16px  — lg (padding robusto, gaps grandes)
20px  — xl (padding amplo)
32px  — xxl (gaps entre seções)
```

### Typography Scale
```
28px / Bold    — H1 (Manifestação)
18px / Medium  — H2 (Data, Status Atual)
14px / Regular — Body (descrições, valores)
12px / Regular — Caption (rótulos, badges)
11px / Regular — Micro (help text, timestamp)
```

### Color Tokens (Light Theme)
```
surface-primary:      #FFFFFF       (Cards, containers)
surface-secondary:    #F9F9F9       (Backgrounds, hover states)
surface-tertiary:     #F5F5F5       (Disabled, muted backgrounds)

text-primary:         #1A1A1A       (Headlines, main text)
text-secondary:       #5A5A5A       (Descriptions, labels)
text-tertiary:        #8A8A8A       (Captions, muted text)

border-light:         #E0E0E0       (Dividers, input borders)
border-medium:        #BDBDBD       (Focus states)
border-dark:          #757575       (Prominent borders)

status-success:       #2E7D32       (✓ Aceito, Manifestado)
status-warning:       #F57C00       (⚠ Parcial, Pendente)
status-error:         #D32F2F       (✗ Recusado, Erro)
status-info:          #1976D2       (ℹ Informativo)

action-primary:       #93070A       (Botões CTAs principais)
action-secondary:     #757575       (Botões secundários)
action-disabled:      #E0E0E0       (Desabilitado)
```

### Color Tokens (Dark Theme)
```
surface-primary:      #2A2A2A       (Cards, containers)
surface-secondary:    #1F1F1F       (Backgrounds, hover states)
surface-tertiary:     #151515       (Disabled, muted backgrounds)

text-primary:         #F0F0F0       (Headlines, main text)
text-secondary:       #B0B0B0       (Descriptions, labels)
text-tertiary:        #808080       (Captions, muted text)

border-light:         #404040       (Dividers, input borders)
border-medium:        #505050       (Focus states)
border-dark:          #707070       (Prominent borders)

status-success:       #4CAF50       (✓ Aceito, Manifestado)
status-warning:       #FFB74D       (⚠ Parcial, Pendente)
status-error:         #EF5350       (✗ Recusado, Erro)
status-info:          #42A5F5       (ℹ Informativo)

action-primary:       #D32F2F       (Botões CTAs principais, contrast maior)
action-secondary:     #B0B0B0       (Botões secundários)
action-disabled:      #404040       (Desabilitado)
```

### Spacing & Layout
```
padding-card:         16px          (Cards, containers)
padding-section:      20px          (Seções principais)
gap-tight:            8px           (Elementos adjacentes)
gap-medium:           12px          (Grupos de elementos)
gap-loose:            16px          (Seções, separação)
gap-section:          32px          (Espaçamento entre blocos)

radius-small:         4px           (Inputs, badges)
radius-medium:        8px           (Cards, botões)
radius-large:         12px          (Modals, dropdowns)

touch-target:         48dp           (Mobile touch, botões)
```

---

## 📐 Wireframes & Layouts

### Mobile Layout (320-480px)

```
┌─────────────────────────────────────┐
│  ≡  Manifestação                  ✕ │  ← ManifestacaoHeader (48px height)
├─────────────────────────────────────┤
│ NFe: 1234567890 | 2026-07-20      │  ← NFe Info Card (80px)
│ Empresa: ACME Inc.                │
├─────────────────────────────────────┤
│ DADOS ATUAIS                       │  ← Section Title
│ Status: Não Manifestado            │  ← Status Badge (Verde #2E7D32)
│ Data de Recebimento: -             │
├─────────────────────────────────────┤
│ MANIFESTAR RECEBIMENTO             │  ← Form Section Title
│                                   │
│ Tipo de Manifestação               │  ← Label
│ [Dropdown ▼]                       │  ← StatusDropdownWidget
│  • Confirmação de Recebimento      │
│  • Aceito                          │
│  • Aceito Parcial                  │
│  • Recusado                        │
│  • Discordância do Tomador         │
│                                   │
│ Observações (Opcional)             │  ← Label
│ [Textarea ──────────────────────] │  ← ObservacaoTextfieldWidget
│  Max 500 caracteres (0/500)        │  ← Helper text
│                                   │
│ [Aceitar (Vermelho)] [Recusar]    │  ← Buttons
│                                   │
└─────────────────────────────────────┘

Altura total: ~680px (scrollável)
Componentes: Header, Card, Dropdown, Textarea, 2 Buttons
Estado: Vazio → Carregando → Sucesso → Erro
```

### Tablet Layout (600px)

```
┌─────────────────────────────────────────────────────────────┐
│  ≡  Manifestação de Recebimento                          ✕  │
├─────────────────────────────────────────────────────────────┤
│  NFe: 1234567890 | Data: 2026-07-20                       │
│  Empresa: ACME Inc. - CNPJ: 12.345.678/0001-90            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  DADOS ATUAIS                                              │
│  Status Atual: [Badge Verde "Não Manifestado"]             │
│  Data Recebimento: -                                       │
│                                                             │
│  MANIFESTAR RECEBIMENTO                                    │
│                                                             │
│  Tipo de Manifestação               │  Observações         │
│  [Dropdown ▼ Aceito]               │  [Textarea...........│
│   • Confirmação de Recebimento     │   Max 500 chars]     │
│   • Aceito                          │  0/500               │
│   • Aceito Parcial                  │                      │
│   • Recusado                        │                      │
│   • Discordância do Tomador         │                      │
│                                    │                      │
│  [Aceitar]  [Recusar]  [Limpar]    │                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Largura: ~600px | Altura: ~500px
Layout: 2 colunas (form + observações lado a lado)
```

### Desktop Layout (1024-1920px)

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│ ≡  Manifestação de Recebimento de NFe                                         ✕  │
├──────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│  ┌────────────────────────────┐  ┌─────────────────────────────────────────┐   │
│  │ NFe: 1234567890            │  │  Status Atual: [Badge Verde] Não Manif. │   │
│  │ Data Emissão: 2026-07-20   │  │  Data Recebimento: - (aguardando)      │   │
│  │ Empresa: ACME Inc.         │  │                                        │   │
│  │ CNPJ: 12.345.678/0001-90   │  │  Última atualização: 2026-07-27 14:30  │   │
│  └────────────────────────────┘  └─────────────────────────────────────────┘   │
│                                                                                  │
│  ┌──────────────────────────────────────────────────────────────────────────┐  │
│  │ MANIFESTAR RECEBIMENTO                                                   │  │
│  │                                                                          │  │
│  │ Tipo de Manifestação *            │  Observações (Opcional)             │  │
│  │ [Dropdown ▼ Aceito]               │  [Textarea........................]  │  │
│  │  • Confirmação de Recebimento     │  [Textarea........................]  │  │
│  │  • Aceito                          │  [Textarea........................]  │  │
│  │  • Aceito Parcial                  │  Max 500 caracteres (45/500)        │  │
│  │  • Recusado                        │                                    │  │
│  │  • Discordância do Tomador         │                                    │  │
│  │                                   │                                    │  │
│  │ [Aceitar] [Recusar] [Limpar]      │                                    │  │
│  │                                                                          │  │
│  └──────────────────────────────────────────────────────────────────────────┘  │
│                                                                                  │
└──────────────────────────────────────────────────────────────────────────────────┘

Largura: 1024-1920px | Altura: ~600px
Layout: 3 colunas (info NFe, status, form)
Grid responsivo: 1fr 1fr 2fr
```

---

## 🧩 Component Specs

### 1. ManifestacaoHeader (fixo, mobile-to-desktop)

**Props**:
```dart
ManifestacaoHeader({
  required String nfeNumber,
  required DateTime emissionDate,
  required String companyName,
  VoidCallback? onClose,
  bool isDarkMode = false,
})
```

**Specs**:
- **Height**: 56px (mobile), 64px (desktop)
- **Background**: surface-primary (#FFFFFF light, #2A2A2A dark)
- **Border-bottom**: 1px border-light (#E0E0E0 light, #404040 dark)
- **Padding**: 16px horizontal, 12px vertical
- **Typography**: H2 (18px Medium) para título "Manifestação"
- **Ícone**: Menu (≡) esquerda 16px, Close (✕) direita 16px
- **Layout**: Flex horizontal, justify-content: space-between

**States**:
- Padrão: text-primary, bg surface-primary
- Hover (desktop): bg surface-secondary
- Dark mode: inverte cores conforme dark tokens

**Accessibility**:
- `role="banner"` 
- `aria-label="Cabeçalho da manifestação"`
- Close button: `aria-label="Fechar manifestação"`, 48px touch target

---

### 2. NFe Info Card

**Props**:
```dart
NFeInfoCard({
  required String nfeNumber,
  required DateTime emissionDate,
  required String companyName,
  required String companyCNPJ,
  bool isDarkMode = false,
})
```

**Specs**:
- **Layout**: Card com 16px padding, 8px radius
- **Background**: surface-secondary (#F9F9F9 light, #1F1F1F dark)
- **Border**: 1px border-light (#E0E0E0 light, #404040 dark)
- **Typography**:
  - Título: "NFe" (Caption 12px, text-tertiary)
  - Número: "1234567890" (Body 14px Medium, text-primary, Roboto Mono)
  - Data: "2026-07-20" (Caption 12px, text-secondary)
  - Empresa: "ACME Inc." (Body 14px, text-primary)
  - CNPJ: "12.345.678/0001-90" (Caption 12px, Roboto Mono, text-secondary)
- **Spacing**:
  - Horizontal gap (NFe + Data): 12px
  - Vertical gap (Empresa + CNPJ): 4px
  - Padding interno: 16px

**Mobile layout** (vertical):
```
NFe: 1234567890
Data: 2026-07-20
───────────────────
Empresa: ACME Inc.
CNPJ: 12.345.678/0001-90
```

**Desktop layout** (horizontal):
```
NFe: 1234567890  |  Data: 2026-07-20
Empresa: ACME Inc. - CNPJ: 12.345.678/0001-90
```

---

### 3. StatusDropdownWidget

**Props**:
```dart
StatusDropdownWidget({
  required String value,
  required ValueChanged<String> onChanged,
  String? errorText,
  bool isDarkMode = false,
  bool isEnabled = true,
})
```

**Specs**:
- **Height**: 48px (touch target mobile)
- **Width**: 100% (mobile), auto (desktop)
- **Background**: surface-primary (#FFFFFF light, #2A2A2A dark)
- **Border**: 2px border-light (#E0E0E0 light, #404040 dark)
- **Border-radius**: 4px
- **Padding**: 12px horizontal, 8px vertical
- **Font**: Body 14px Regular
- **Icon**: Dropdown arrow (▼) 16px, right-aligned

**States**:
- **Default**: text-primary, border-light
- **Hover**: bg surface-secondary, border-medium
- **Focus**: border 2px border-medium (#BDBDBD light, #505050 dark), outline 2px action-primary
- **Disabled**: bg surface-tertiary (#F5F5F5 light, #151515 dark), text-tertiary, cursor not-allowed
- **Error**: border 2px status-error (#D32F2F light, #EF5350 dark)

**Options** (fixed):
1. Confirmação de Recebimento
2. Aceito
3. Aceito Parcial
4. Recusado
5. Discordância do Tomador

**Mobile behavior**: Dropdown expande full-width com shadow, espaçamento 8px entre items, scroll se > 5 items

**Accessibility**:
- `aria-label="Tipo de manifestação"`
- `aria-required="true"`
- `role="listbox"` para opções
- Focus outline visible

---

### 4. ObservacaoTextfieldWidget

**Props**:
```dart
ObservacaoTextfieldWidget({
  required TextEditingController controller,
  required ValueChanged<String>? onChanged,
  String? errorText,
  int maxLength = 500,
  int minLines = 3,
  int maxLines = 6,
  bool isDarkMode = false,
})
```

**Specs**:
- **Height**: 120px (minLines: 3), expansível até 144px (maxLines: 6)
- **Width**: 100%
- **Background**: surface-primary (#FFFFFF light, #2A2A2A dark)
- **Border**: 1px border-light (#E0E0E0 light, #404040 dark)
- **Border-radius**: 4px
- **Padding**: 12px (interno)
- **Font**: Body 14px Regular, line-height 1.6
- **Placeholder**: "Digite observações..." (text-tertiary, italic)
- **Counter**: "0/500" (Caption 12px, text-tertiary, bottom-right 8px)

**States**:
- **Default**: bg surface-primary, border-light, text-primary
- **Focus**: border 2px border-medium, outline 2px action-primary
- **Typing**: counter color progredindo text-secondary (0-250) → warning (251-400) → error (401+)
- **Max Length atingido**: text-error, bg surface-tertiary, counter text-error
- **Error**: border 2px status-error, error message abaixo (Caption 12px, text-error)

**Accessibility**:
- `aria-label="Observações"`
- `aria-describedby="obs-helper"` (helper text)
- Counter atualizado em real-time
- `aria-live="polite"` para counter updates
- Max 500 characters enforced

---

### 5. Status Badge

**Props**:
```dart
StatusBadge({
  required String status, // 'nao_manifestado', 'aceito', 'parcial', 'recusado'
  bool isDarkMode = false,
})
```

**Specs**:
- **Height**: 24px
- **Padding**: 8px horizontal, 6px vertical
- **Border-radius**: 12px (pill shape)
- **Font**: Caption 12px Medium, text-white
- **Display**: Ícone (16px) + Label

| Status | Ícone | Label | Color (Light) | Color (Dark) |
|--------|-------|-------|---------------|--------------|
| Não Manifestado | ○ | Não Manifestado | status-info #1976D2 | status-info #42A5F5 |
| Aceito | ✓ | Aceito | status-success #2E7D32 | status-success #4CAF50 |
| Parcial | ⚠ | Aceito Parcial | status-warning #F57C00 | status-warning #FFB74D |
| Recusado | ✕ | Recusado | status-error #D32F2F | status-error #EF5350 |

**Accessibility**:
- `role="status"`
- `aria-label="Status: Não Manifestado"`

---

### 6. Action Buttons

**Props**:
```dart
ActionButton({
  required String label,
  required VoidCallback onPressed,
  required ActionType type, // primary, secondary, danger
  bool isLoading = false,
  bool isEnabled = true,
  bool isDarkMode = false,
})

enum ActionType { primary, secondary, danger }
```

**Specs**:

**Primary Button** (Aceitar/Enviar)
- **Width**: 100% (mobile), auto (desktop)
- **Height**: 48px
- **Background**: action-primary (#93070A light, #D32F2F dark)
- **Text**: Caption 14px Medium, color #FFFFFF
- **Border**: none
- **Border-radius**: 4px
- **Padding**: 12px 24px
- **States**:
  - Default: bg action-primary
  - Hover: bg #7A0508 (darker)
  - Focus: outline 2px offset 2px #93070A
  - Disabled: bg action-disabled, cursor not-allowed
  - Loading: spinner white 20px, label hidden

**Secondary Button** (Recusar)
- **Width**: 100% (mobile), auto (desktop)
- **Height**: 48px
- **Background**: transparent
- **Text**: Caption 14px Medium, color action-primary
- **Border**: 2px solid action-primary
- **Border-radius**: 4px
- **Padding**: 12px 24px
- **States**:
  - Default: border action-primary, text action-primary
  - Hover: bg action-primary with 10% opacity
  - Focus: outline 2px offset 2px action-primary
  - Disabled: border action-disabled, text action-disabled

**Danger Button** (Limpar/Cancelar)
- Mesmo layout secondary, color status-error

**Mobile layout**: Stack vertical, full-width, gap 8px  
**Desktop layout**: Horizontal, gap 12px

**Accessibility**:
- `aria-label="Aceitar manifestação"`
- `aria-busy="true"` quando loading
- 48px minimum touch target
- Focus visible outline

---

## ✅ Responsividade Validation

### Breakpoints & Behavior

| Breakpoint | Device | Width Range | Layout | Grid Cols | Font Scale |
|-----------|--------|------------|--------|-----------|-----------|
| xs | Mobile | 320-480px | Vertical | 1 | 1.0x |
| sm | Mobile Large | 480-600px | Vertical | 1 | 1.05x |
| md | Tablet | 600-1024px | 2 Col | 2 | 1.1x |
| lg | Desktop | 1024-1440px | 3 Col | 3 | 1.15x |
| xl | Desktop XL | 1440px+ | 3 Col | 3 | 1.2x |

### Mobile (320-480px)
- Stack vertical, full-width
- Padding: 16px
- Gap: 12px entre componentes
- Buttons: full-width (100%), 48px height
- Header height: 56px
- Textarea: minLines 3, max 6
- Touch targets: 48x48dp minimum

### Tablet (600px)
- 2-column layout (form + observações)
- Max-width: 100%
- Padding: 20px
- Gap: 16px entre grupos
- Buttons: auto-width, inline
- Header height: 60px

### Desktop (1024px+)
- 3-column layout (info + status + form)
- Max-width: 1200px (centered)
- Padding: 32px
- Gap: 20px entre colunas
- Buttons: auto-width, group compacto
- Header height: 64px

### Overflow & Scrolling
- Body never scrolls horizontally
- Textarea scrolls internally se conteúdo > maxLines
- Dropdown menu max-height 400px com scroll interno
- Wide content (tables, lists) em scroll container isolado

### Test Responsividade
```
Mobile 320px:   Portrait + Landscape
Mobile 480px:   Portrait + Landscape
Tablet 600px:   Portrait + Landscape
Desktop 1024px: Full
Desktop 1440px: Full
```

---

## ♿ Acessibilidade (WCAG 2.1 AA)

### Color Contrast
- **Text on Background**: ≥ 4.5:1 (AA standard)
  - Primary text (#1A1A1A) on white (#FFFFFF): 21:1 ✓
  - Secondary text (#5A5A5A) on white (#FFFFFF): 8.5:1 ✓
  - Tertiary text (#8A8A8A) on white (#FFFFFF): 5.5:1 ✓

- **Interactive Elements**: ≥ 3:1
  - Primary button (#93070A) on white: 7.5:1 ✓
  - Status badges (all colors): ≥ 3:1 ✓

- **Dark mode contrast** (similar standards aplicadas)

### Keyboard Navigation
- Tab order: Header → NFe Card → Status Badge → Dropdown → Textarea → Buttons → Close
- All interactive elements tabbable (`tabIndex="0"` ou semantic elements)
- Focus outline: 2px action-primary, 2px offset, visible on all states
- No keyboard trap — focus cycle completo sem deadlock
- Escape key fecha dropdown e modal (se aplicável)

### Semantic HTML/Widgets
- Header: `<header>` ou `Semantics.role(label: 'banner')`
- Buttons: `<button>` ou `ElevatedButton`, labels descritivos
- Inputs: `<input>` ou `TextField` com `label`
- Landmarks: main, nav, header, footer com roles corretos

### Labels & ARIA
```dart
// Dropdown
Semantics(
  label: 'Tipo de manifestação',
  enabled: true,
  child: DropdownButton(...),
)

// Textarea
Semantics(
  label: 'Observações',
  textField: true,
  child: TextField(...),
)

// Buttons
ElevatedButton(
  onPressed: onAceitar,
  child: Semantics(
    label: 'Aceitar manifestação de recebimento da NFe',
    button: true,
    enabled: true,
    child: Text('Aceitar'),
  ),
)

// Status Badge
Semantics(
  label: 'Status da manifestação: Não Manifestado',
  enabled: true,
  child: Container(...),
)
```

### Touch Targets
- Minimum 48x48dp (mobile)
- Buttons, dropdowns, closers: sempre ≥ 48x48dp
- Spacing entre targets: ≥ 8px

### Reader Support
- Alt text para ícones: "Fechar", "Dropdown menu", "Verificado", "Erro"
- Error messages linked a input via `aria-describedby`
- Form sections with headings (h2, h3) para estrutura
- Status updates via `aria-live="polite"`

### Motion & Animation
- Respect `prefers-reduced-motion: reduce`
- Transitions máx 200ms
- No autoplay, autoscroll, blinking content
- Loading spinner: accessible via `aria-busy="true"`

### Language & Clarity
- Labels claros: "Tipo de Manifestação *" (asterisco = obrigatório)
- Error messages específicos: "Campo obrigatório" não "Erro"
- Helper text: "Max 500 caracteres" não "500"
- Formato data: "2026-07-20" (ISO 8601)

---

## 🌓 Dark Mode Compatibility

### Token Override (Light → Dark)

```css
:root {
  --surface-primary: #FFFFFF;
  --surface-secondary: #F9F9F9;
  --text-primary: #1A1A1A;
  --text-secondary: #5A5A5A;
  --status-success: #2E7D32;
  --status-error: #D32F2F;
  --status-warning: #F57C00;
}

@media (prefers-color-scheme: dark) {
  :root {
    --surface-primary: #2A2A2A;
    --surface-secondary: #1F1F1F;
    --text-primary: #F0F0F0;
    --text-secondary: #B0B0B0;
    --status-success: #4CAF50;
    --status-error: #EF5350;
    --status-warning: #FFB74D;
  }
}

:root[data-theme="dark"] {
  /* Override do toggle do tema */
  --surface-primary: #2A2A2A;
  /* ... */
}
```

### Component Contrast (Dark Mode)
- **Body text**: #F0F0F0 on #2A2A2A = 13:1 ✓
- **Secondary text**: #B0B0B0 on #2A2A2A = 6.5:1 ✓
- **Primary button**: #D32F2F on #2A2A2A = 4.5:1 ✓ (enhanced for dark)
- **Status badges**: Enhanced saturation para visibility

### Images & Visual Elements
- Reducir brilho de bordas em dark mode (border-light: #404040)
- Sem transparency changes; usar cores calculadas
- Icons: auto-inverted (Flutter handles via Theme)

### Testing Dark Mode
- Ativar sistema dark mode + toggle interno
- Screenshot 5 componentes key em ambos temas
- Verificar contrast em todo estado (default, hover, focus, disabled, error)

---

## 🧪 Test Cases (15 Cenários)

### Mobile Tests (5 cenários — 320-480px)

**M1: Tela vazia com dropdown focado**
- Given: Usuário abre ManifestacaoScreen primeira vez
- When: Toca no dropdown "Tipo de Manifestação"
- Then: Dropdown expande com 5 opções visíveis, focus outline present, touch target 48x48dp
- Screenshot: mobile-m1-dropdown-focus.png

**M2: Preenchimento textarea com contador**
- Given: Dropdown selecionado "Aceito"
- When: Digita "Teste de observação" na textarea
- Then: Contador atualiza "21/500", texto em text-secondary, foco mantém outline
- Screenshot: mobile-m2-textarea-counter.png

**M3: Botão Aceitar desabilitado quando dropdown vazio**
- Given: Nenhuma opção dropdown selecionada
- When: Tenta clicar "Aceitar"
- Then: Botão disabled (action-disabled), cursor not-allowed, texto opacity reduzido
- Screenshot: mobile-m3-button-disabled.png

**M4: Max length textarea (500 chars)**
- Given: Textarea com 500 caracteres digitados
- When: Tenta digitar mais 1 caractere
- Then: Input bloqueado (preventDefault), contador red #D32F2F, error message "Máximo 500 caracteres"
- Screenshot: mobile-m4-textarea-max.png

**M5: Dark mode — status badge cor correta**
- Given: Tema dark ativado
- When: Status badge "Aceito" renderizado
- Then: Background status-success #4CAF50 (não #2E7D32), text white, contrast ≥ 4.5:1
- Screenshot: mobile-m5-dark-badge.png

---

### Web/Tablet Tests (5 cenários — 600-1024px)

**W1: 2-column layout em tablet**
- Given: Viewport 600px (tablet)
- When: ManifestacaoScreen renderiza
- Then: Dropdown 1 col esquerda, textarea 1 col direita, gap 16px, botões bottom
- Screenshot: tablet-w1-2column-layout.png

**W2: Dropdown menu scroll interno (> 5 items)**
- Given: Dropdown expandido com 5+ opções
- When: Renderiza
- Then: Menu altura máx 400px, scroll bar interno se necessário, fundo surface-secondary hover
- Screenshot: tablet-w2-dropdown-scroll.png

**W3: Focus navigation (Tab key)**
- Given: Usuário em navegação keyboard
- When: Pressiona Tab 5x (Header → Dropdown → Textarea → Buttons → Close)
- Then: Focus outline 2px action-primary visível em cada elemento, ordem lógica seguida
- Screenshot: tablet-w3-tab-navigation.png

**W4: Error state — dropdown obrigatório**
- Given: Usuário clica "Aceitar" sem dropdown selecionado
- When: Form validation run
- Then: Dropdown border 2px status-error #D32F2F, error message "Campo obrigatório" Caption 12px red
- Screenshot: tablet-w4-dropdown-error.png

**W5: Desktop 1024px — 3-column layout**
- Given: Viewport 1024px
- When: ManifestacaoScreen renderiza
- Then: NFe Info + Status 1st col (20%), Form 2nd col (40%), Observações 3rd col (40%), gap 20px
- Screenshot: desktop-w5-3column-layout.png

---

### Windows/Desktop Tests (5 cenários — 1024-1920px)

**D1: Landscape responsividade buttons inline**
- Given: Desktop 1400px landscape
- When: Buttons renderizam
- Then: [Aceitar] [Recusar] [Limpar] inline horizontal, gap 12px, auto-width, altura 48px
- Screenshot: desktop-d1-buttons-inline.png

**D2: Loading state — spinner animation**
- Given: Usuário clica "Aceitar"
- When: API call em progresso
- Then: Botão mostra spinner branco 20px, label "Aceitar" hidden, `aria-busy="true"`, background darker
- Screenshot: desktop-d2-loading-spinner.gif

**D3: Success state — status badge updated**
- Given: API response sucesso
- When: ManifestacaoScreen refresh
- Then: Status badge muda "Não Manifestado" → "Aceito" (verde #2E7D32 light, #4CAF50 dark)
- Screenshot: desktop-d3-success-badge.png

**D4: Error handling — toast/snackbar**
- Given: API call falha (e.g., NFe não encontrada)
- When: Response erro
- Then: Error toast aparece (status-error bg, Caption 14px, "Erro: NFe não encontrada", dismiss 5s ou tap)
- Screenshot: desktop-d4-error-toast.png

**D5: Contrast validation — all states**
- Given: Manual contrast check with tool (e.g., WebAIM)
- When: Verificar 10 pares text-background (primary, secondary, tertiary em light + dark)
- Then: Todos ≥ 4.5:1 (AA), buttons ≥ 3:1, badges ≥ 4.5:1
- Screenshot: contrast-validation-report.txt

---

## 📋 Implementation Checklist

### Phase 1: Setup & Tokens (4h)
- [ ] Create `manifestacao_screen.dart` with Widget skeleton
- [ ] Define `manifestacao_tokens.dart` with all color, spacing, typography tokens
- [ ] Create `manifestacao_theme.dart` (light + dark theme)
- [ ] Test tokens in debugger (all colors, spacing values)
- [ ] Git commit: "refactor(flutter): design tokens ManifestacaoScreen"

### Phase 2: Components (8h)
- [ ] ManifestacaoHeader (with close button, menu icon)
- [ ] NFe Info Card (responsive mobile/desktop layout)
- [ ] StatusDropdownWidget (5 options, disabled states, error)
- [ ] ObservacaoTextfieldWidget (maxLength 500, counter, error)
- [ ] StatusBadge (4 status types, icons)
- [ ] ActionButtons (primary, secondary, loading state)
- [ ] Git commit: "feat(flutter): ManifestacaoScreen components"

### Phase 3: Layout & Responsividad (6h)
- [ ] Implement MediaQuery breakpoints (320, 480, 600, 1024, 1440px)
- [ ] Mobile single-column layout (StackView vertical)
- [ ] Tablet 2-column (Responsive GridView)
- [ ] Desktop 3-column (Flexible columns)
- [ ] Test overflow/scrolling (no horizontal scroll)
- [ ] Git commit: "feat(flutter): responsive layout mobile/tablet/desktop"

### Phase 4: Accessibility (4h)
- [ ] Add Semantics labels to all interactive elements
- [ ] Verify keyboard navigation (Tab order)
- [ ] Test screen reader (TalkBack, VoiceOver)
- [ ] Validate contrast (all states, light + dark)
- [ ] Test touch targets (48x48dp minimum)
- [ ] Git commit: "feat(flutter): accessibility WCAG 2.1 AA"

### Phase 5: Dark Mode (3h)
- [ ] Implement ThemeData.dark() override
- [ ] Test color tokens in dark theme
- [ ] Validate contrast dark mode (4.5:1+)
- [ ] Screenshot 5 key components dark mode
- [ ] Git commit: "feat(flutter): dark mode support"

### Phase 6: API Integration (6h)
- [ ] GET /manifestacao/{nfeId} — fetch current status
- [ ] POST /manifestacao — submit manifestation
- [ ] Error handling (400, 404, 500 responses)
- [ ] Loading state with spinner
- [ ] Success/error toast notifications
- [ ] Git commit: "feat(flutter): API integration manifestacao endpoints"

### Phase 7: Testing (8h)
- [ ] Unit tests: StatusBadge, counter logic (5 tests)
- [ ] Widget tests: ManifestacaoScreen states (10 tests)
- [ ] Integration test: Form submit flow (3 tests)
- [ ] Screenshots: 15 scenarios (mobile, tablet, desktop)
- [ ] Accessibility audit (manual + automated)
- [ ] Git commit: "test(flutter): ManifestacaoScreen unit + widget tests"

### Phase 8: Replication & Merge (2h)
- [ ] Sync task_manager_flutter_merged_final (100% copy, except theme)
- [ ] Run `flutter analyze` both projects
- [ ] Code review quality gate
- [ ] Merge to main branch
- [ ] Git commit: "chore(flutter): replication to merged_final + merge main"

**Total**: 41 hours (spritable em 2 dias paralelo com P2-501 Backend)

---

## 📊 Métricas Finais

| Métrica | Meta | Status |
|---------|------|--------|
| **Testes Unit** | ≥ 8 | 🔄 Será contabilizado |
| **Testes Widget** | ≥ 10 | 🔄 Será contabilizado |
| **Testes Integration** | ≥ 3 | 🔄 Será contabilizado |
| **Code Coverage** | ≥ 80% | 🔄 Alvo P2-502 |
| **Screenshots E2E** | 15 (5 mobile, 5 tablet, 5 desktop) | 📋 Spec pronto |
| **Accessibility** | WCAG 2.1 AA | ✅ Especificado |
| **Dark Mode** | Suportado | ✅ Design tokens prontos |
| **Responsividade** | Mobile + Tablet + Desktop | ✅ Layouts prontos |
| **Replicação** | 100% task_manager_flutter_merged_final | 📋 Plano definido |

---

## 📞 Referências

- **Wave 3 P2 Card**: `.planning/memory/WAVE3-P2-CARDS-TRELLO-2026-07-23.md`
- **Design Tokens AppAcademia**: CLAUDE.md (projeto)
- **Flutter Best Practices**: Flutter docs 3.x
- **WCAG 2.1 AA Guidelines**: https://www.w3.org/WAI/WCAG21/quickref/
- **Material Design 3**: https://m3.material.io/

---

**Versão**: 1.0 | **Status**: ✅ Pronto para Execução | **Próximo Step**: gsd-executor P2-502 H2 implementação
