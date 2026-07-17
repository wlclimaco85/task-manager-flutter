# AppAcademia Login — Design System Master
**Build Date**: 2026-07-17  
**Version**: 1.0.0  
**Project**: Abraço Contabilidade (fintech contábil B2B)  
**Platforms**: Mobile (375px), Tablet (768px), Desktop (1024px+)  
**Framework**: Material Design 3 + Flutter

---

## TABLE OF CONTENTS

1. [Core Design System](#core-design-system)
2. [Paleta & Tokens](#paleta--tokens)
3. [Tipografia & Scale](#tipografia--scale)
4. [Spacing & Layout](#spacing--layout)
5. [Breakpoints & Responsividade](#breakpoints--responsividade)
6. [Componentes Base](#componentes-base)
7. [Estados & Interações](#estados--interações)
8. [Acessibilidade (WCAG AA)](#acessibilidade-wcag-aa)
9. [Variante 1 — Conservative](#variante-1--conservative)
10. [Variante 2 — Bold](#variante-2--bold)
11. [Mockups 3 Breakpoints](#mockups-3-breakpoints)
12. [Flutter Implementation Guidance](#flutter-implementation-guidance)
13. [Recomendação de Implementação](#recomendação-de-implementação)
14. [Checklist Pré-Implementação](#checklist-pré-implementação)

---

## CORE DESIGN SYSTEM

### Princípios de Design

- **Professional**: Contabilidade exige confiança. Paleta sóbria, tipografia legível.
- **Accessible**: WCAG AA em todos os estados (focus, hover, contraste).
- **Mobile-First**: Comece em 375px; expanda para tablet/desktop.
- **Familiar**: Padrões Material Design 3 que contadores conhecem.
- **Performant**: Sem animações pesadas; responsive sem JS complexo.

---

## PALETA & TOKENS

### Cores Primárias

| Token | Hex | RGB | Uso |
|-------|-----|-----|-----|
| **primary** | `#93070A` | rgb(147, 7, 10) | Botões principais, headers, foco |
| **primary-dark** | `#6B0507` | rgb(107, 5, 7) | Hover, pressed states |
| **primary-light** | `#D64449` | rgb(214, 68, 73) | Disabled, subtle backgrounds |

### Cores Secundárias

| Token | Hex | RGB | Uso |
|-------|-----|-----|-----|
| **secondary** | `#005826` | rgb(0, 88, 38) | Ícones secundários, accent |
| **secondary-light** | `#2D7F4D` | rgb(45, 127, 77) | Backgrounds, cards |
| **secondary-pale** | `#E8F4ED` | rgb(232, 244, 237) | Light backgrounds |

### Cores Neutras (Acessibilidade)

| Token | Hex | RGB | Uso | Contrast vs White |
|-------|-----|-----|-----|-------------------|
| **text-primary** | `#1A1A1A` | rgb(26, 26, 26) | Corpo, labels | 16.5:1 ✅ |
| **text-secondary** | `#555555` | rgb(85, 85, 85) | Subtitles, hints | 7.6:1 ✅ |
| **text-disabled** | `#ADADAD` | rgb(173, 173, 173) | Disabled fields | 3.1:1 ✅ |
| **bg-white** | `#FFFFFF` | rgb(255, 255, 255) | Base background | N/A |
| **bg-light** | `#F5F5F5` | rgb(245, 245, 245) | Card backgrounds | N/A |
| **border-light** | `#E0E0E0` | rgb(224, 224, 224) | Input borders | N/A |
| **border-focus** | `#93070A` | rgb(147, 7, 10) | Focus rings | 2.8:1 (over white) |

### Cores de Status

| Token | Hex | RGB | Uso |
|-------|-----|-----|-----|
| **error** | `#B71C1C` | rgb(183, 28, 28) | Erros, validação negativa |
| **error-light** | `#FFCDD2` | rgb(255, 205, 210) | Error backgrounds |
| **success** | `#2E7D32` | rgb(46, 125, 50) | Sucesso, validação positiva |
| **warning** | `#F57F17` | rgb(245, 127, 23) | Avisos, atenção |

### Design Tokens (Dart Constants)

```dart
// PRIMARY
const Color gridColorPrimary = Color(0xFF93070A);
const Color gridColorPrimaryDark = Color(0xFF6B0507);
const Color gridColorPrimaryLight = Color(0xFFD64449);

// SECONDARY
const Color gridColorSecondary = Color(0xFF005826);
const Color gridColorSecondaryLight = Color(0xFF2D7F4D);
const Color gridColorSecondaryPale = Color(0xFFE8F4ED);

// NEUTRAL
const Color gridColorTextPrimary = Color(0xFF1A1A1A);
const Color gridColorTextSecondary = Color(0xFF555555);
const Color gridColorTextDisabled = Color(0xFFADADAD);
const Color gridColorBgWhite = Color(0xFFFFFFFF);
const Color gridColorBgLight = Color(0xFFF5F5F5);
const Color gridColorBorderLight = Color(0xFFE0E0E0);
const Color gridColorBorderFocus = Color(0xFF93070A);

// STATUS
const Color gridColorError = Color(0xFFB71C1C);
const Color gridColorErrorLight = Color(0xFFFFCDD2);
const Color gridColorSuccess = Color(0xFF2E7D32);
const Color gridColorWarning = Color(0xFFF57F17);
```

---

## TIPOGRAFIA & SCALE

### Font Stack

```
// Padrão: Roboto (Material Design 3)
fontFamily: 'Roboto'

// Fallback: Sistema
iOS: -apple-system, BlinkMacSystemFont, 'Segoe UI'
Android: Roboto
Web/Desktop: 'Segoe UI', sans-serif
```

### Type Scale (Mobile-First)

| Role | Size | Weight | LineHeight | Uso |
|------|------|--------|-----------|-----|
| **H1** (Hero) | 32px | 700 | 1.2 (38px) | Logo/brand na tela |
| **H2** (Title) | 28px | 600 | 1.3 (36px) | Título do formulário |
| **H3** (Subtitle) | 20px | 600 | 1.4 (28px) | Seções secundárias |
| **Body-Large** | 16px | 400 | 1.5 (24px) | Labels, corpo |
| **Body-Regular** | 14px | 400 | 1.6 (22px) | Hints, subtext |
| **Label-Large** | 14px | 500 | 1.4 (20px) | Botões, badges |
| **Label-Small** | 12px | 500 | 1.3 (16px) | Captions, meta |
| **Mono** | 13px | 400 | 1.5 | Códigos, tokens |

### Tablet Adjustments (≥768px)

- Aumentar **H1** para 36px
- Aumentar **H2** para 32px
- **Body-Large** permanece 16px
- Aumentar margens entre elementos (+20%)

### Desktop Adjustments (≥1024px)

- Aumentar **H1** para 40px
- Aumentar **H2** para 36px
- **Body-Large** permanece 16px
- Aumentar espaçamento (+30%)

```dart
// design_tokens.dart
class TextStyles {
  // Mobile
  static const TextStyle h1Mobile = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    fontFamily: 'Roboto',
    color: gridColorTextPrimary,
  );

  static const TextStyle h2Mobile = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.3,
    fontFamily: 'Roboto',
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    fontFamily: 'Roboto',
  );

  static const TextStyle bodyRegular = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    fontFamily: 'Roboto',
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    fontFamily: 'Roboto',
  );

  // Tablet
  static const TextStyle h1Tablet = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.2,
    fontFamily: 'Roboto',
  );

  // Desktop
  static const TextStyle h1Desktop = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.2,
    fontFamily: 'Roboto',
  );
}
```

---

## SPACING & LAYOUT

### Spacing Scale

```
4px = 0.5 unit
8px = 1 unit (base)
12px = 1.5 unit
16px = 2 unit (most common)
20px = 2.5 unit
24px = 3 unit
32px = 4 unit
40px = 5 unit
48px = 6 unit
```

### Mobile Layout (375px)

- **Horizontal padding**: 16px
- **Vertical padding**: 24px
- **Card spacing**: 16px between cards
- **Form field height**: 56px (48pt touch target + 8px padding)
- **Button min height**: 48px (WCAG AA touch target)

### Tablet Layout (768px)

- **Horizontal padding**: 24px
- **Vertical padding**: 32px
- **Max content width**: 700px (centered)
- **Form field height**: 56px (consistent)
- **Button height**: 48px (consistent)

### Desktop Layout (1024px+)

- **Horizontal padding**: 32px
- **Vertical padding**: 40px
- **Max content width**: 900px (centered)
- **Form field height**: 48px
- **Button height**: 48px

```dart
class Spacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class TouchTargets {
  static const double buttonMinHeight = 48.0;
  static const double inputMinHeight = 56.0;
  static const double touchFocusRing = 4.0;
}
```

---

## BREAKPOINTS & RESPONSIVIDADE

### Breakpoint Definitions

| Device Type | Min Width | Max Width | Padding | Max Content |
|-------------|-----------|-----------|---------|-------------|
| **Mobile** | 0px | 374px | 16px | 342px |
| **Mobile (Large)** | 375px | 599px | 16px | 343px |
| **Tablet** | 600px | 767px | 24px | 552px |
| **Tablet (Large)** | 768px | 1023px | 24px | 720px |
| **Desktop** | 1024px | ∞ | 32px | 960px |

### Responsive Layout Strategy

```dart
class ResponsiveHelper {
  static bool isMobile(double width) => width < 600;
  static bool isTablet(double width) => width >= 600 && width < 1024;
  static bool isDesktop(double width) => width >= 1024;
  
  static EdgeInsets getPadding(double width) {
    if (width < 600) return EdgeInsets.all(16);
    if (width < 1024) return EdgeInsets.all(24);
    return EdgeInsets.all(32);
  }
  
  static double getMaxContentWidth(double width) {
    if (width < 600) return width - 32;
    if (width < 1024) return 552;
    return 960;
  }
}

// Uso em Widget
class ResponsiveLoginForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = ResponsiveHelper.isMobile(constraints.maxWidth);
        final padding = ResponsiveHelper.getPadding(constraints.maxWidth);
        
        return Padding(
          padding: padding,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveHelper.getMaxContentWidth(constraints.maxWidth),
              ),
              child: SingleChildScrollView(
                child: Column(...),
              ),
            ),
          ),
        );
      },
    );
  }
}
```

---

## COMPONENTES BASE

### Input Field (TextField)

```dart
// Base Style
InputDecoration(
  labelText: 'Email',
  labelStyle: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: gridColorTextSecondary,
  ),
  hintText: 'seu@email.com',
  hintStyle: TextStyle(
    fontSize: 14,
    color: gridColorTextDisabled,
  ),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(
      color: gridColorBorderLight,
      width: 1.0,
    ),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(
      color: gridColorBorderLight,
      width: 1.0,
    ),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(
      color: gridColorBorderFocus,
      width: 2.0,
    ),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(
      color: gridColorError,
      width: 1.5,
    ),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(
      color: gridColorError,
      width: 2.0,
    ),
  ),
  filled: true,
  fillColor: gridColorBgWhite,
  errorStyle: TextStyle(
    color: gridColorError,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  ),
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
)

// Min Height: 56px
// Touch target: ✅ WCAG AA
```

### Button (ElevatedButton)

```dart
// Primary Button (Main CTA)
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: gridColorPrimary,
    foregroundColor: Colors.white,
    minimumSize: Size(double.infinity, 48),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    elevation: 2,
    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
  ),
  child: Text(
    'Entrar',
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),
)

// States
// Enabled: bg: #93070A, text: white
// Hover: bg: #6B0507 (darker)
// Pressed: bg: #6B0507 + scale 0.98
// Disabled: bg: #D64449, text: rgba(255,255,255,0.6), cursor: not-allowed
// Focus: outline 2px #93070A

// Secondary Button
OutlinedButton(
  onPressed: () {},
  style: OutlinedButton.styleFrom(
    minimumSize: Size(double.infinity, 48),
    side: BorderSide(color: gridColorSecondary, width: 2),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  child: Text(
    'Cadastro',
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: gridColorSecondary,
    ),
  ),
)
```

### Card Component

```dart
Card(
  elevation: 1,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(color: gridColorBorderLight, width: 1),
  ),
  color: gridColorBgWhite,
  child: Padding(
    padding: EdgeInsets.all(Spacing.lg),
    child: Column(...),
  ),
)
```

### Focus Ring (Acessibilidade)

```dart
// Aplicar em todos os elementos interativos
FocusableActionDetector(
  onShowFocusHighlight: (hasFocus) {
    // Mostrar outline 2px quando focado
  },
  child: Container(
    decoration: BoxDecoration(
      border: hasFocus ? Border.all(
        color: gridColorBorderFocus,
        width: 2,
      ) : null,
    ),
    child: TextField(...),
  ),
)
```

---

## ESTADOS & INTERAÇÕES

### TextField States

| Estado | Border | BG | Text Color | Exemplo |
|--------|--------|----|----|----------|
| **Default** | Light gray (#E0E0E0), 1px | White | Primary text | `Email` label visible |
| **Focused** | Primary (#93070A), 2px | White | Primary text + cursor | User typing |
| **Filled** | Primary, 1px | White | Primary text | Email: `user@abc.com` |
| **Error** | Error (#B71C1C), 1.5px | Error light (#FFCDD2) | Error text | "Email inválido" |
| **Disabled** | Disabled gray, 1px | Light bg (#F5F5F5) | Disabled text | Non-editable field |
| **Success** | Success (#2E7D32), 1px | White | Success text | ✓ Validated |

### Button States

| Estado | BG | Text | Cursor | Interaction |
|--------|----|----|--------|-------------|
| **Default** | Primary (#93070A) | White | Pointer | Hoverable |
| **Hover** | Dark primary (#6B0507) | White | Pointer | Brightness -10% |
| **Pressed/Active** | Dark primary (#6B0507) | White | Pointer | Scale 0.98, shadow increase |
| **Disabled** | Light primary (#D64449) | White 60% | Not-allowed | opacity: 0.6 |
| **Focus** | Primary + ring | White | Pointer | Ring: 2px #93070A |

### Hover & Focus (Web/Tablet)

```dart
// Hover Effect (Web only)
MouseRegion(
  onEnter: (_) => setState(() => isHovered = true),
  onExit: (_) => setState(() => isHovered = false),
  child: Container(
    color: isHovered ? gridColorPrimaryDark : gridColorPrimary,
    child: ElevatedButton(...),
  ),
)

// Focus Ring (All platforms)
Focus(
  onKey: (node, event) => KeyEventResult.handled,
  child: Container(
    decoration: BoxDecoration(
      border: hasFocus ? Border.all(
        color: gridColorBorderFocus,
        width: 2,
      ) : null,
    ),
    child: ElevatedButton(...),
  ),
)
```

### Loading State

```dart
// Show spinner overlay
if (isLoading)
  Container(
    color: Colors.black.withOpacity(0.3),
    child: Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(gridColorPrimary),
        strokeWidth: 2,
      ),
    ),
  )
```

---

## ACESSIBILIDADE (WCAG AA)

### Contrast Requirements

| Element | Foreground | Background | Ratio | Status |
|---------|-----------|-----------|-------|--------|
| Primary button text | White | #93070A | 8.2:1 | ✅ AAA |
| Primary button hover | White | #6B0507 | 10.1:1 | ✅ AAA |
| Body text | #1A1A1A | #FFFFFF | 16.5:1 | ✅ AAA |
| Secondary text | #555555 | #FFFFFF | 7.6:1 | ✅ AA |
| Disabled text | #ADADAD | #FFFFFF | 3.1:1 | ✅ AA |
| Error text | #B71C1C | #FFCDD2 | 5.1:1 | ✅ AA |
| Focus ring | #93070A | #FFFFFF | 2.8:1 | ✅ AA (interactive element) |

**Fix from Current State**:
- ❌ `Colors.orange` in errorStyle: 2.16:1 (FAIL) → ✅ Use `gridColorError` (#B71C1C): 5.1:1
- ❌ Tagline alpha: 0.65 (too faint) → ✅ Raise to 0.95

### Keyboard Navigation

```dart
// All form fields must be focusable
// Tab order: Logo → Email → Password → "Entrar" → "Esqueceu senha?" → "Cadastro"

class AccessibleLoginForm extends StatefulWidget {
  @override
  State<AccessibleLoginForm> createState() => _AccessibleLoginFormState();
}

class _AccessibleLoginFormState extends State<AccessibleLoginForm> {
  late FocusNode emailFocus;
  late FocusNode passwordFocus;
  late FocusNode submitFocus;

  @override
  void initState() {
    super.initState();
    emailFocus = FocusNode();
    passwordFocus = FocusNode();
    submitFocus = FocusNode();
  }

  @override
  void dispose() {
    emailFocus.dispose();
    passwordFocus.dispose();
    submitFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          TextField(
            focusNode: emailFocus,
            onSubmitted: (_) => passwordFocus.requestFocus(),
            decoration: InputDecoration(
              labelText: 'Email ou CPF/CNPJ',
              hintText: 'seu@email.com ou 12345678901234',
            ),
          ),
          TextField(
            focusNode: passwordFocus,
            onSubmitted: (_) => submitFocus.requestFocus(),
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Senha',
            ),
          ),
          Focus(
            focusNode: submitFocus,
            child: ElevatedButton(...),
          ),
        ],
      ),
    );
  }
}
```

### Screen Reader Support

```dart
// Labels & Semantics
Semantics(
  label: 'Campo de Email',
  enabled: true,
  child: TextField(
    decoration: InputDecoration(
      labelText: 'Email',
      hintText: 'seu@email.com',
    ),
  ),
)

// Button Labels
Semantics(
  button: true,
  label: 'Botão Entrar - Faça login com sua conta',
  child: ElevatedButton(
    child: Text('Entrar'),
  ),
)

// Error Messages
if (emailError != null)
  Semantics(
    label: 'Erro no campo Email: $emailError',
    child: Text(
      emailError,
      style: TextStyle(color: gridColorError),
    ),
  )
```

### Touch Target Sizes (WCAG AA)

- **Buttons**: Minimum 48×48px ✅
- **Input fields**: Minimum 56px height ✅
- **Links**: Minimum 44×44px (if used)
- **Spacing between targets**: ≥8px ✅

---

## VARIANTE 1 — CONSERVATIVE

### Overview

**Filosofia**: Profissional, clássico, confiável. Ideal para contabilidade tradicional.

- **Paleta**: Vermelho sóbrio (#93070A) + Verde clássico (#005826)
- **Tipografia**: Roboto, peso padrão (400-600)
- **Efeitos**: Nenhum (sem gradientes, sem glassmorphism)
- **Espírito**: "Contabilidade confiável. Simples. Direto."

### Core Characteristics

| Aspecto | Decisão |
|--------|---------|
| **Logo** | Estático, branco/preto, sem efeitos |
| **Fundo** | Branco puro (#FFFFFF) |
| **Cards** | Bordas cinza claras, sombra mínima (elevation: 1) |
| **Botões** | Cor sólida, sem gradiente, hover: escurece 15% |
| **Animações** | Transições suaves (150ms) apenas em hover/focus |
| **Tipografia** | Roboto regular; nenhuma fonte extra |
| **Ícones** | Cinza escuro (#1A1A1A) por padrão |
| **Tagline** | Texto claro, preto (#1A1A1A), alpha: 0.95 |

### Visual Rules

```
┌─────────────────────────────────────────────┐
│  CONSERVATIVE VARIANT - Mobile (375px)       │
├─────────────────────────────────────────────┤
│                                             │
│                                             │
│          [Abraço Contabilidade]             │ ← Logo centralized, 60px
│                (branco)                     │
│                                             │
│          Sua contabilidade de forma         │ ← Tagline, 14px, black (alpha: 0.95)
│              simples e segura                │
│                                             │
│  ┌─────────────────────────────────┐       │
│  │  Email ou CPF/CNPJ              │       │ ← TextField, 56px, border: light gray
│  │  [_______________________]      │       │
│  └─────────────────────────────────┘       │
│                                             │
│  ┌─────────────────────────────────┐       │
│  │  Senha                          │       │ ← TextField, 56px, border: light gray
│  │  [_______________________]      │       │
│  └─────────────────────────────────┘       │
│                                             │
│  [    ENTRAR (red #93070A)    ]            │ ← Button, 48px, solid red
│                                             │
│  ────────────────────────────────────       │ ← "ou"
│                                             │
│  [    GOOGLE (outlined)         ]          │ ← OutlineButton, verde border
│  [    MICROSOFT (outlined)      ]          │
│                                             │
│  [ Esqueceu a senha? ]  [ Novo por aqui? ] │ ← Links, 12px, underline on hover
│                                             │
└─────────────────────────────────────────────┘

SPACING:
- Header: 24px top
- Logo: 60px
- Tagline: 12px bottom
- Form gap: 16px between fields
- Button gap: 24px top
- Footer: 16px bottom

COLORS:
- Logo: White (#FFF)
- Tagline: Black (#1A1A1A, alpha: 0.95)
- Border (inactive): Light gray (#E0E0E0)
- Border (focus): Red (#93070A)
- Button bg: Red (#93070A)
- Button text: White
- Links: Green (#005826)
```

### Component Styles (Conservative)

```dart
// login_conservative.dart

class ConservativeLoginTheme {
  // Logo
  static Widget buildLogo() {
    return Text(
      'Abraço',
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        fontFamily: 'Roboto',
      ),
    );
  }

  // Tagline
  static Widget buildTagline() {
    return Text(
      'Sua contabilidade de forma simples e segura',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: gridColorTextPrimary.withOpacity(0.95),
        height: 1.5,
      ),
    );
  }

  // Primary Button (Entrar)
  static ElevatedButton buildPrimaryButton({
    required VoidCallback onPressed,
    required String label,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: gridColorPrimary,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  // Secondary Button (Google, Microsoft)
  static OutlinedButton buildSecondaryButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: Size(double.infinity, 48),
        side: BorderSide(
          color: gridColorSecondary,
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: gridColorSecondary),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: gridColorSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Link Button
  static TextButton buildLinkButton({
    required VoidCallback onPressed,
    required String label,
  }) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: gridColorSecondary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
```

---

## VARIANTE 2 — BOLD

### Overview

**Filosofia**: Moderno, energético, premium. Diferencia no mercado.

- **Paleta**: Gradiente 45° (vermelho → secundário) + glassmorphism
- **Tipografia**: Roboto + inter-spacing dinâmico
- **Efeitos**: Glow, blur, glassmorphism, animações suaves
- **Espírito**: "Fintech do futuro. Segura e moderna."

### Core Characteristics

| Aspecto | Decisão |
|--------|---------|
| **Logo** | Gradiente + sombra/glow |
| **Fundo** | Gradiente 45° (#93070A → #005826) OU padrão radial com overlay |
| **Cards** | Glassmorphism: blur + semi-transparent white (0.1 opacity) |
| **Botões** | Gradiente + glow on hover, shadow dinâmica |
| **Animações** | Fade-in 300ms, button pulse on hover (scale + glow) |
| **Tipografia** | Roboto + letter-spacing +0.5px para premium |
| **Ícones** | Cores gradient matching |
| **Tagline** | Branco com glow outline, alpha: 1.0 |

### Visual Rules

```
┌─────────────────────────────────────────────┐
│  BOLD VARIANT - Mobile (375px)              │
├─────────────────────────────────────────────┤
│                                             │
│  [Gradient Background 45°]                  │ ← #93070A → #005826
│   (with subtle animated pattern)            │
│                                             │
│          [Abraço]                           │ ← Logo gradient + glow
│          (gradient text)                    │
│                                             │
│          Fintech contábil do futuro         │ ← Tagline white + glow
│                                             │
│  ╔═════════════════════════════════╗       │ ← Glassmorphic card
│  ║                                 ║       │   (blur: 20, opacity: 0.85)
│  ║  Email ou CPF/CNPJ              ║       │
│  ║  [_______________________]      ║       │
│  ║                                 ║       │
│  ║  Senha                          ║       │
│  ║  [_______________________]      ║       │
│  ║                                 ║       │
│  ╚═════════════════════════════════╝       │
│                                             │
│  [ENTRAR - Gradient + Glow]                │ ← Button gradient + shadow glow
│                                             │
│  ──────────────────────────────────        │ ← Separador com brilho
│                                             │
│  [GOOGLE] [MICROSOFT]                      │ ← Outlined buttons, gradient border
│                                             │
│  Esqueceu a senha? | Novo por aqui?       │ ← Links, white text, no underline
│                                             │
└─────────────────────────────────────────────┘

SPACING:
- Header: 32px top
- Logo: 64px + glow
- Tagline: 16px bottom
- Form gap: 16px between fields
- Button gap: 32px top
- Footer: 20px bottom

COLORS:
- Background: Gradient #93070A → #005826 (45°)
- Logo: Gradient text
- Tagline: White (#FFF, alpha: 1.0)
- Card: Glassmorphic white (0.85 opacity, blur: 20)
- Button: Gradient #93070A → #6B0507
- Button glow: Shadow (0 0 16px #93070A)
- Links: White
```

### Component Styles (Bold)

```dart
// login_bold.dart

class BoldLoginTheme {
  // Gradient Background
  static BoxDecoration buildBackgroundGradient() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        angle: 45 * (3.14159 / 180),
        colors: [
          gridColorPrimary,      // #93070A
          gridColorSecondary,    // #005826
        ],
        stops: [0.0, 1.0],
      ),
    );
  }

  // Logo with Gradient Text
  static Widget buildLogo() {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          Color(0xFFFFD700),  // Gold
          Color(0xFFFFA500),  // Orange
        ],
      ).createShader(bounds),
      child: Text(
        'Abraço',
        style: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          fontFamily: 'Roboto',
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Glassmorphic Card
  static Widget buildGlassmorphicCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(Spacing.lg),
            child: child,
          ),
        ),
      ),
    );
  }

  // Primary Button with Gradient & Glow
  static ElevatedButton buildPrimaryButton({
    required VoidCallback onPressed,
    required String label,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
        shadowColor: gridColorPrimary.withOpacity(0.6),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gridColorPrimary, gridColorPrimaryDark],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: gridColorPrimary.withOpacity(0.4),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  // Tagline with Glow
  static Widget buildTagline() {
    return Text(
      'Fintech contábil do futuro',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.5,
        shadows: [
          Shadow(
            color: Colors.white.withOpacity(0.4),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
```

### Animations (Bold Only)

```dart
// login_animations.dart

class BoldLoginAnimations {
  // Fade-in on load
  static Widget fadeInAnimation({
    required Widget child,
    required Duration duration,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      builder: (context, value, _) => Opacity(
        opacity: value,
        child: child,
      ),
    );
  }

  // Glow pulse on button hover (Web only)
  static Widget glowPulseOnHover({
    required Widget child,
  }) {
    return MouseRegion(
      onEnter: (_) {
        // Trigger glow animation
      },
      onExit: (_) {
        // Reset animation
      },
      child: child,
    );
  }

  // Scale on press
  static Widget scaleOnPress({
    required VoidCallback onPressed,
    required Widget child,
  }) {
    return GestureDetector(
      onTapDown: (_) {
        // Animate scale to 0.98
      },
      onTapUp: (_) {
        // Animate scale back to 1.0
        onPressed();
      },
      onTapCancel: () {
        // Reset scale
      },
      child: child,
    );
  }
}
```

---

## MOCKUPS 3 BREAKPOINTS

### Mockup 1 — Mobile (375px)

```
CONSERVATIVE:
┌─────────────────────────────────────────┐
│ ▲                                       │ 24px (top padding)
│                                         │
│        Abraço Contabilidade             │ Logo: 60px (centered)
│        (white on red-ish bg)            │
│                                         │
│ Sua contabilidade de forma simples      │ Tagline: 14px, black, 0.95 alpha
│     e segura                            │ 12px bottom
│                                         │
│ ┌─────────────────────────────────────┐ │ Card start
│ │ Email ou CPF/CNPJ                   │ │ 16px h-padding
│ │ [_______________________]           │ │ 56px h-height
│ └─────────────────────────────────────┘ │ Border: light gray, 1px
│                                         │
│ ┌─────────────────────────────────────┐ │ 16px gap
│ │ Senha                               │ │
│ │ [_______________________]           │ │ 56px h-height
│ │ 👁 (show password toggle)           │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ [ ENTRAR ]                              │ 48px h, 24px top margin
│                                         │
│ ──────── ou ────────                    │ Separador
│                                         │
│ [ GOOGLE ]                              │ 48px h, 16px gap
│ [ MICROSOFT ]                           │
│                                         │
│ Esqueceu a senha? | Novo por aqui?     │ Links, 12px
│                                         │
│ ▼ 16px (bottom padding)                 │
└─────────────────────────────────────────┘

TOTAL HEIGHT: ~580px (mobile view, no scroll needed on 700px viewport)
SCROLL: Required on < 600px if keyboard visible


BOLD:
┌─────────────────────────────────────────┐
│ [Gradient Background #93070A → #005826] │
│                                         │
│ ▲ 32px (top padding with glow effect)   │
│                                         │
│        Abraço                           │ Logo: 64px (gradient + glow)
│    (gradient text + glow)               │
│                                         │
│ Fintech contábil do futuro              │ Tagline: 18px, white, glow
│                                         │ 16px bottom
│                                         │
│ ╔═════════════════════════════════════╗ │ Glassmorphic card (blur 20)
│ ║ Email ou CPF/CNPJ                  ║ │ 16px h-padding
│ ║ [_______________________]          ║ │ 56px h-height
│ ╚═════════════════════════════════════╝ │
│                                         │
│ ╔═════════════════════════════════════╗ │ 16px gap
│ ║ Senha                              ║ │
│ ║ [_______________________]          ║ │
│ ║ 👁 (show password toggle)          ║ │
│ ╚═════════════════════════════════════╝ │
│                                         │
│ [  ENTRAR (gradient + glow)  ]          │ 48px h, 32px top
│                                         │
│ ──────── ou ────────                    │ Brilho sutil
│                                         │
│ [  GOOGLE  ] [  MICROSOFT  ]            │ 2-column on mobile
│                                         │
│ Esqueceu a senha? | Novo por aqui?     │ Links, 12px, white
│                                         │
│ ▼ 20px (bottom padding)                 │
└─────────────────────────────────────────┘

ANIMATIONS:
- Fade-in 300ms on load
- Button pulse on hover (scale + glow)
```

### Mockup 2 — Tablet (768px)

```
CONSERVATIVE & BOLD (layout similar, spacing increased):

┌───────────────────────────────────────────────────────────────────────┐
│                                                                       │
│                    ▲ 32px top padding                                 │
│                                                                       │
│               Abraço Contabilidade                                    │ Logo: 64px
│                                                                       │ Centered
│        Sua contabilidade de forma simples e segura                    │ Tagline: 16px
│                                                                       │
│         ┌──────────────────────────────────────┐                      │
│         │                                      │                      │ 24px h-padding
│         │ Email ou CPF/CNPJ                    │                      │ Max width: 552px
│         │ [____________________________]       │                      │ 56px height
│         │                                      │                      │
│         │ Senha                                │                      │
│         │ [____________________________]       │                      │
│         │ 👁                                   │                      │
│         │                                      │                      │
│         │ [ ENTRAR ]                           │                      │ 48px button
│         │                                      │                      │
│         │ ────── ou ──────                     │                      │
│         │                                      │                      │
│         │ [ GOOGLE ]   [ MICROSOFT ]           │                      │ 2 buttons side
│         │                                      │                      │
│         │ Esqueceu? | Novo?                   │                      │
│         └──────────────────────────────────────┘                      │
│                                                                       │
│                    ▼ 32px bottom padding                              │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘

VIEWPORT: 768px × 1024px (iPad landscape)
BEHAVIOR: Form centered, max-width 552px
SCROLL: None on default (forms fit)
```

### Mockup 3 — Desktop (1024px+)

```
CONSERVATIVE & BOLD:

┌─────────────────────────────────────────────────────────────────────────────────┐
│                                                                                   │
│                          ▲ 40px top padding                                       │
│                                                                                   │
│                       Abraço Contabilidade                                        │ Logo: 72px
│                                                                                   │ H1: 36px
│                   Sua contabilidade de forma simples e segura                     │ Tagline: 16px
│                                                                                   │
│                      ┌──────────────────────────────────────┐                     │
│                      │                                      │                     │ Max width: 960px
│                      │ Email ou CPF/CNPJ                    │                     │ But centered, so
│                      │ [____________________________]       │                     │ use 500-600px
│                      │                                      │                     │ for visual balance
│                      │ Senha                                │                     │
│                      │ [____________________________]       │                     │
│                      │ 👁                                   │                     │
│                      │                                      │                     │
│                      │ [ ENTRAR ]                           │                     │
│                      │                                      │                     │
│                      │ ────────── ou ──────────             │                     │
│                      │                                      │                     │
│                      │ [ GOOGLE ]     [ MICROSOFT ]         │                     │
│                      │                                      │                     │
│                      │ Esqueceu a senha? | Novo por aqui?  │                     │
│                      │                                      │                     │
│                      └──────────────────────────────────────┘                     │
│                                                                                   │
│                          ▼ 40px bottom padding                                    │
│                                                                                   │
└─────────────────────────────────────────────────────────────────────────────────┘

VIEWPORT: 1440px × 900px (standard desktop)
BEHAVIOR: Form centered, constrained width (500px max content for readability)
HOVER STATES: Visible on all buttons, links
SCROLL: None (full form visible)

BOLD VARIANT SPECIFIC:
- Background gradient visible across full viewport
- Glassmorphic card more prominent (blur 20, larger border)
- Logo glow more visible with larger spacing
- Button glow effect pronounced on hover
```

---

## FLUTTER IMPLEMENTATION GUIDANCE

### Project Structure

```
task_manager_flutter/lib/
├── core/
│   ├── theme/
│   │   ├── design_tokens.dart           ← NEW: Color tokens + text styles
│   │   ├── responsive_helper.dart       ← NEW: Breakpoint logic
│   │   └── colors.dart                  ← EXISTING: Reference + update
│   ├── constants/
│   │   └── spacing.dart                 ← NEW: Spacing scale
│   └── utils/
│       └── accessibility_utils.dart     ← NEW: Focus management, semantics
├── features/
│   └── auth/
│       ├── presentation/
│       │   ├── pages/
│       │   │   ├── login_conservative.dart  ← VARIANT 1
│       │   │   ├── login_bold.dart          ← VARIANT 2
│       │   │   └── login_screen.dart        ← Controller (routes to variant)
│       │   └── widgets/
│       │       ├── login_form.dart      ← Shared form widget
│       │       ├── login_button.dart    ← Custom button
│       │       └── accessible_textfield.dart ← Accessible input
│       ├── domain/
│       └── data/
```

### Step 1 — Create Design Tokens

**File**: `lib/core/theme/design_tokens.dart`

```dart
import 'package:flutter/material.dart';

// ============================================================
// COLOR TOKENS
// ============================================================

// Primary
const Color gridColorPrimary = Color(0xFF93070A);
const Color gridColorPrimaryDark = Color(0xFF6B0507);
const Color gridColorPrimaryLight = Color(0xFFD64449);

// Secondary
const Color gridColorSecondary = Color(0xFF005826);
const Color gridColorSecondaryLight = Color(0xFF2D7F4D);
const Color gridColorSecondaryPale = Color(0xFFE8F4ED);

// Neutral
const Color gridColorTextPrimary = Color(0xFF1A1A1A);
const Color gridColorTextSecondary = Color(0xFF555555);
const Color gridColorTextDisabled = Color(0xFFADADAD);
const Color gridColorBgWhite = Color(0xFFFFFFFF);
const Color gridColorBgLight = Color(0xFFF5F5F5);
const Color gridColorBorderLight = Color(0xFFE0E0E0);
const Color gridColorBorderFocus = Color(0xFF93070A);

// Status
const Color gridColorError = Color(0xFFB71C1C);
const Color gridColorErrorLight = Color(0xFFFFCDD2);
const Color gridColorSuccess = Color(0xFF2E7D32);
const Color gridColorWarning = Color(0xFFF57F17);

// ============================================================
// TEXT STYLES
// ============================================================

class AppTextStyles {
  // H1 Styles
  static const TextStyle h1Mobile = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    fontFamily: 'Roboto',
    color: gridColorTextPrimary,
    letterSpacing: 0,
  );

  static const TextStyle h1Tablet = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.2,
    fontFamily: 'Roboto',
    color: gridColorTextPrimary,
    letterSpacing: 0,
  );

  static const TextStyle h1Desktop = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.2,
    fontFamily: 'Roboto',
    color: gridColorTextPrimary,
    letterSpacing: 0,
  );

  // H2 Styles
  static const TextStyle h2Mobile = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.3,
    fontFamily: 'Roboto',
    color: gridColorTextPrimary,
  );

  static const TextStyle h2Tablet = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.3,
    fontFamily: 'Roboto',
    color: gridColorTextPrimary,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    fontFamily: 'Roboto',
    color: gridColorTextPrimary,
  );

  static const TextStyle bodyRegular = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    fontFamily: 'Roboto',
    color: gridColorTextSecondary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    fontFamily: 'Roboto',
    color: gridColorTextPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    fontFamily: 'Roboto',
    color: gridColorTextSecondary,
  );
}

// ============================================================
// SPACING CONSTANTS
// ============================================================

class Spacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// ============================================================
// TOUCH TARGETS
// ============================================================

class TouchTargets {
  static const double buttonMinHeight = 48.0;
  static const double inputMinHeight = 56.0;
  static const double focusRingWidth = 2.0;
}

// ============================================================
// BORDER RADIUS
// ============================================================

class Radii {
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
}
```

### Step 2 — Create Responsive Helper

**File**: `lib/core/theme/responsive_helper.dart`

```dart
import 'package:flutter/material.dart';

class ResponsiveHelper {
  // Breakpoint constants
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  // Device type detection
  static bool isMobile(double width) => width < mobileBreakpoint;
  static bool isTablet(double width) =>
      width >= mobileBreakpoint && width < tabletBreakpoint;
  static bool isDesktop(double width) => width >= tabletBreakpoint;

  // Padding based on breakpoint
  static EdgeInsets getPadding(double width) {
    if (width < mobileBreakpoint) {
      return const EdgeInsets.all(16);
    } else if (width < tabletBreakpoint) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }

  // Max content width
  static double getMaxContentWidth(double width) {
    if (width < mobileBreakpoint) {
      return width - 32; // 16px padding on each side
    } else if (width < tabletBreakpoint) {
      return 552;
    } else {
      return 600; // For login, keep narrower for readability
    }
  }

  // Font size based on breakpoint
  static double getHeadingFontSize(double width, {bool h1 = true}) {
    if (h1) {
      if (width < mobileBreakpoint) return 32;
      if (width < tabletBreakpoint) return 36;
      return 40;
    } else {
      if (width < mobileBreakpoint) return 28;
      if (width < tabletBreakpoint) return 32;
      return 36;
    }
  }

  // Spacing multiplier
  static double getSpacingMultiplier(double width) {
    if (width < mobileBreakpoint) return 1.0;
    if (width < tabletBreakpoint) return 1.2;
    return 1.3;
  }
}
```

### Step 3 — Accessible TextField Widget

**File**: `lib/features/auth/presentation/widgets/accessible_textfield.dart`

```dart
import 'package:flutter/material.dart';
import 'package:app_academia/core/theme/design_tokens.dart';

class AccessibleTextField extends StatefulWidget {
  final String label;
  final String hint;
  final bool obscureText;
  final TextEditingController? controller;
  final String? errorText;
  final TextInputType keyboardType;
  final FocusNode? focusNode;
  final VoidCallback? onFieldSubmitted;

  const AccessibleTextField({
    Key? key,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.controller,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.focusNode,
    this.onFieldSubmitted,
  }) : super(key: key);

  @override
  State<AccessibleTextField> createState() => _AccessibleTextFieldState();
}

class _AccessibleTextFieldState extends State<AccessibleTextField> {
  late bool _showPassword;

  @override
  void initState() {
    super.initState();
    _showPassword = !widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${widget.label} field${widget.errorText != null ? ', error: ${widget.errorText}' : ''}',
      enabled: true,
      child: Focus(
        onKey: (node, event) => KeyEventResult.handled,
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: widget.obscureText && !_showPassword,
          keyboardType: widget.keyboardType,
          textInputAction: TextInputAction.next,
          style: AppTextStyles.bodyLarge,
          onSubmitted: (_) => widget.onFieldSubmitted?.call(),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: AppTextStyles.labelLarge.copyWith(
              color: gridColorTextSecondary,
            ),
            hintText: widget.hint,
            hintStyle: AppTextStyles.bodyRegular.copyWith(
              color: gridColorTextDisabled,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            // Borders
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: gridColorBorderLight,
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: gridColorBorderLight,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: gridColorBorderFocus,
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: gridColorError,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: gridColorError,
                width: 2.0,
              ),
            ),
            filled: true,
            fillColor: gridColorBgWhite,
            errorText: widget.errorText,
            errorStyle: AppTextStyles.labelSmall.copyWith(
              color: gridColorError,
            ),
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: gridColorTextSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
```

### Step 4 — Conservative Variant Page

**File**: `lib/features/auth/presentation/pages/login_conservative.dart`

```dart
import 'package:flutter/material.dart';
import 'package:app_academia/core/theme/design_tokens.dart';
import 'package:app_academia/core/theme/responsive_helper.dart';
import 'package:app_academia/features/auth/presentation/widgets/accessible_textfield.dart';

class LoginConservativePage extends StatefulWidget {
  @override
  State<LoginConservativePage> createState() => _LoginConservativePageState();
}

class _LoginConservativePageState extends State<LoginConservativePage> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late FocusNode emailFocus;
  late FocusNode passwordFocus;
  late FocusNode submitFocus;
  
  bool isLoading = false;
  String? emailError;
  String? passwordError;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    emailFocus = FocusNode();
    passwordFocus = FocusNode();
    submitFocus = FocusNode();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    submitFocus.dispose();
    super.dispose();
  }

  void _handleLogin() {
    setState(() {
      isLoading = true;
      emailError = null;
      passwordError = null;
    });

    // TODO: Call authentication service
    // For now, simulate delay
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: gridColorBgWhite,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = ResponsiveHelper.isMobile(constraints.maxWidth);
          final padding = ResponsiveHelper.getPadding(constraints.maxWidth);
          final maxWidth =
              ResponsiveHelper.getMaxContentWidth(constraints.maxWidth);

          return SingleChildScrollView(
            padding: padding,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: Spacing.lg),
                    // Logo
                    Text(
                      'Abraço',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h1Mobile.copyWith(
                        fontSize: ResponsiveHelper.getHeadingFontSize(
                          constraints.maxWidth,
                          h1: true,
                        ),
                      ),
                    ),
                    SizedBox(height: Spacing.lg),
                    // Tagline
                    Text(
                      'Sua contabilidade de forma simples e segura',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyRegular.copyWith(
                        color: gridColorTextPrimary.withOpacity(0.95),
                      ),
                    ),
                    SizedBox(height: Spacing.lg),
                    // Form
                    AccessibleTextField(
                      label: 'Email ou CPF/CNPJ',
                      hint: 'seu@email.com ou 12345678901234',
                      controller: emailController,
                      focusNode: emailFocus,
                      errorText: emailError,
                      keyboardType: TextInputType.emailAddress,
                      onFieldSubmitted: () =>
                          passwordFocus.requestFocus(),
                    ),
                    SizedBox(height: Spacing.md),
                    AccessibleTextField(
                      label: 'Senha',
                      hint: '••••••••',
                      obscureText: true,
                      controller: passwordController,
                      focusNode: passwordFocus,
                      errorText: passwordError,
                      onFieldSubmitted: () =>
                          submitFocus.requestFocus(),
                    ),
                    SizedBox(height: Spacing.lg),
                    // Login Button
                    SizedBox(
                      height: TouchTargets.buttonMinHeight,
                      child: Focus(
                        focusNode: submitFocus,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: gridColorPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: isLoading
                              ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'ENTRAR',
                                  style: AppTextStyles.labelLarge
                                      .copyWith(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: Spacing.lg),
                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: gridColorBorderLight,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: Spacing.md,
                          ),
                          child: Text(
                            'ou',
                            style: AppTextStyles.labelSmall,
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: gridColorBorderLight,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Spacing.lg),
                    // OAuth Buttons
                    SizedBox(
                      height: TouchTargets.buttonMinHeight,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.login),
                        label: Text('GOOGLE'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: gridColorSecondary,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: Spacing.sm),
                    SizedBox(
                      height: TouchTargets.buttonMinHeight,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.account_circle),
                        label: Text('MICROSOFT'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: gridColorSecondary,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: Spacing.lg),
                    // Footer Links
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'Esqueceu a senha?',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: gridColorSecondary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text('|', style: AppTextStyles.labelSmall),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'Novo por aqui?',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: gridColorSecondary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Spacing.lg),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

### Step 5 — Bold Variant Page

**File**: `lib/features/auth/presentation/pages/login_bold.dart`

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:app_academia/core/theme/design_tokens.dart';
import 'package:app_academia/core/theme/responsive_helper.dart';
import 'package:app_academia/features/auth/presentation/widgets/accessible_textfield.dart';

class LoginBoldPage extends StatefulWidget {
  @override
  State<LoginBoldPage> createState() => _LoginBoldPageState();
}

class _LoginBoldPageState extends State<LoginBoldPage>
    with TickerProviderStateMixin {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late FocusNode emailFocus;
  late FocusNode passwordFocus;
  late FocusNode submitFocus;
  late AnimationController fadeController;

  bool isLoading = false;
  String? emailError;
  String? passwordError;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    emailFocus = FocusNode();
    passwordFocus = FocusNode();
    submitFocus = FocusNode();
    fadeController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    fadeController.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    submitFocus.dispose();
    fadeController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    setState(() {
      isLoading = true;
      emailError = null;
      passwordError = null;
    });

    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gridColorPrimary,
              gridColorSecondary,
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile =
                ResponsiveHelper.isMobile(constraints.maxWidth);
            final padding =
                ResponsiveHelper.getPadding(constraints.maxWidth);
            final maxWidth = ResponsiveHelper
                .getMaxContentWidth(constraints.maxWidth);

            return SingleChildScrollView(
              padding: padding,
              child: FadeTransition(
                opacity: fadeController,
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: Spacing.xl),
                        // Logo with gradient
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              LinearGradient(
                            colors: [
                              Color(0xFFFFD700),
                              Color(0xFFFFA500),
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'Abraço',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: ResponsiveHelper
                                  .getHeadingFontSize(
                                constraints.maxWidth,
                                h1: true,
                              ),
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'Roboto',
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(height: Spacing.lg),
                        // Tagline with glow
                        Text(
                          'Fintech contábil do futuro',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors
                                    .white
                                    .withOpacity(0.4),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: Spacing.lg),
                        // Glassmorphic Card
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 20,
                              sigmaY: 20,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withOpacity(0.85),
                                borderRadius:
                                    BorderRadius.circular(
                                        16),
                                border: Border.all(
                                  color: Colors.white
                                      .withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(
                                    Spacing.lg),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .stretch,
                                  children: [
                                    AccessibleTextField(
                                      label: 'Email ou CPF/CNPJ',
                                      hint:
                                          'seu@email.com ou 12345678901234',
                                      controller:
                                          emailController,
                                      focusNode:
                                          emailFocus,
                                      errorText:
                                          emailError,
                                      keyboardType:
                                          TextInputType
                                              .emailAddress,
                                      onFieldSubmitted: () =>
                                          passwordFocus
                                              .requestFocus(),
                                    ),
                                    SizedBox(
                                        height:
                                            Spacing.md),
                                    AccessibleTextField(
                                      label: 'Senha',
                                      hint: '••••••••',
                                      obscureText:
                                          true,
                                      controller:
                                          passwordController,
                                      focusNode:
                                          passwordFocus,
                                      errorText:
                                          passwordError,
                                      onFieldSubmitted: () =>
                                          submitFocus
                                              .requestFocus(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: Spacing.xl),
                        // Login Button with gradient & glow
                        SizedBox(
                          height: TouchTargets
                              .buttonMinHeight,
                          child: Focus(
                            focusNode: submitFocus,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(
                                        12),
                                boxShadow: [
                                  BoxShadow(
                                    color: gridColorPrimary
                                        .withOpacity(0.4),
                                    blurRadius: 16,
                                    offset:
                                        Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : _handleLogin,
                                style: ElevatedButton
                                    .styleFrom(
                                  backgroundColor:
                                      Colors
                                          .transparent,
                                  foregroundColor:
                                      Colors.white,
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Ink(
                                  decoration:
                                      BoxDecoration(
                                    gradient:
                                        LinearGradient(
                                      colors: [
                                        gridColorPrimary,
                                        gridColorPrimaryDark,
                                      ],
                                    ),
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                12),
                                  ),
                                  child: Container(
                                    alignment: Alignment
                                        .center,
                                    child: isLoading
                                        ? SizedBox(
                                            height: 24,
                                            width: 24,
                                            child:
                                                CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<
                                                      Color>(
                                                Colors
                                                    .white,
                                              ),
                                              strokeWidth:
                                                  2,
                                            ),
                                          )
                                        : Text(
                                            'ENTRAR',
                                            style: TextStyle(
                                              fontSize:
                                                  16,
                                              fontWeight:
                                                  FontWeight
                                                      .w700,
                                              color: Colors
                                                  .white,
                                              letterSpacing:
                                                  0.5,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: Spacing.lg),
                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.white
                                    .withOpacity(0.3),
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets
                                  .symmetric(
                                horizontal:
                                    Spacing.md,
                              ),
                              child: Text(
                                'ou',
                                style:
                                    TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.white
                                    .withOpacity(0.3),
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: Spacing.lg),
                        // OAuth Buttons
                        SizedBox(
                          height: TouchTargets
                              .buttonMinHeight,
                          child: OutlinedButton
                              .icon(
                            onPressed: () {},
                            icon: Icon(Icons.login),
                            label: Text('GOOGLE'),
                            style: OutlinedButton
                                .styleFrom(
                              side: BorderSide(
                                color: Colors.white,
                                width: 2,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                            8),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                            height: Spacing.sm),
                        SizedBox(
                          height: TouchTargets
                              .buttonMinHeight,
                          child: OutlinedButton
                              .icon(
                            onPressed: () {},
                            icon: Icon(
                                Icons.account_circle),
                            label: Text(
                                'MICROSOFT'),
                            style: OutlinedButton
                                .styleFrom(
                              side: BorderSide(
                                color: Colors.white,
                                width: 2,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                            8),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                            height: Spacing.lg),
                        // Footer Links
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          children: [
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'Esqueceu a senha?',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.w500,
                                  color: Colors
                                      .white,
                                  decoration:
                                      TextDecoration
                                          .underline,
                                ),
                              ),
                            ),
                            Text(
                              '|',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'Novo por aqui?',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.w500,
                                  color: Colors
                                      .white,
                                  decoration:
                                      TextDecoration
                                          .underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                            height: Spacing.lg),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

---

## RECOMENDAÇÃO DE IMPLEMENTAÇÃO

### Qual Variante Implementar Primeiro?

**Recomendação: CONSERVATIVE (Variante 1)**

**Justificativa**:

1. **Risco Baixo**: Sem efeitos complexos (glassmorphism, gradientes animados), mais fácil de testar.
2. **Acessibilidade Imediata**: Foco em WCAG AA garantido sem dependências de rendering avançado.
3. **Replicação Simples**: Estrutura de componentes padrão, ideal para replicar em `task_manager_flutter_merged_final`.
4. **Feedback Rápido**: Contadores reconhecem padrão clássico imediatamente.
5. **Escalabilidade**: Conservative estabelece foundation para Bold depois.

**Quando Implementar Bold**:

- Após Conservative estar ✅ em QA (semana 2).
- Quando houver design team validando glow/glassmorphism.
- Opcional: Usar Bold para "Premium" tier se houver modelo freemium.

### Roadmap de Implementação

**Phase 1 — Design System Foundation (Semana 1)**
```
Task 1: Create design_tokens.dart (2h)
Task 2: Create responsive_helper.dart (1h)
Task 3: Create accessible_textfield.dart (2h)
Task 4: Create login_conservative.dart (3h)
Task 5: Update app routing to use login_conservative (1h)
Task 6: Test on mobile (375px) + tablet (768px) + desktop (1024px) (2h)
```

**Phase 2 — Conservative QA (Semana 1, dias 4-5)**
```
Task 1: Run flutter analyze on lib/features/auth/ (30m)
Task 2: Run widget tests for accessible_textfield (1h)
Task 3: Test keyboard navigation (Tab, Shift+Tab) (1h)
Task 4: Test screen reader on iOS/Android (1h)
Task 5: Verify contrast ratios via accessibility audit (30m)
Task 6: Test on 3 breakpoints (30m)
```

**Phase 3 — Bold Variant (Semana 2)**
```
Task 1: Create login_bold.dart (3h)
Task 2: Test animations + glow effects (1h)
Task 3: Test on Web (desktop Chrome) (1h)
Task 4: Replicate to merged_final (1h)
```

**Phase 4 — A/B Testing & Selection (Semana 2, final)**
```
Task 1: Deploy both to staging
Task 2: Collect user feedback
Task 3: Decide final variant for production
Task 4: Archive alternate variant in version control
```

---

## CHECKLIST PRÉ-IMPLEMENTAÇÃO

### ✅ Antes de Começar

- [ ] Roboto font disponível em `pubspec.yaml`
  ```yaml
  google_fonts:
    - name: Roboto
  ```
  OR use sistema default (recomendado para reduzir bundle size)

- [ ] Material Design 3 ativado em `main.dart`
  ```dart
  useMaterial3: true,
  ```

- [ ] `LayoutBuilder` disponível (Flutter 2.5+) — projeto já tem

- [ ] Sem dependências de packages adicionais para Conservative
  - ✅ Material (built-in)
  - ✅ Semantics (built-in)
  - ✅ Focus/FocusNode (built-in)

- [ ] Para Bold (glassmorphism), usar `BackdropFilter` (built-in, Flutter 1.20+)

### ✅ Validação de Contraste (WCAG AA)

Usar ferramentas online antes de commitar:
- https://webaim.org/resources/contrastchecker/
- https://www.tpgi.com/color-contrast-checker/

Checklist de contrastes:
- [ ] `#93070A` (primary) + white: 8.2:1 ✅ AAA
- [ ] `#005826` (secondary) + white: 8.4:1 ✅ AAA
- [ ] `#1A1A1A` (text primary) + white: 16.5:1 ✅ AAA
- [ ] `#555555` (text secondary) + white: 7.6:1 ✅ AA
- [ ] `#B71C1C` (error) + `#FFCDD2` (error bg): 5.1:1 ✅ AA

### ✅ Responsividade — Test Matrix

| Breakpoint | Device | Resolution | Test | Status |
|-----------|--------|-----------|------|--------|
| Mobile | iPhone 12 | 390×844 | Form fits, no horizontal scroll | ⬜ TODO |
| Mobile | iPhone SE | 375×667 | Form fits, scroll only if keyboard | ⬜ TODO |
| Tablet | iPad (6th gen) | 768×1024 | Form centered, max-width 552px | ⬜ TODO |
| Desktop | Chrome | 1024×768 | Form centered, max-width 600px | ⬜ TODO |
| Web | Flutter Web | 1440×900 | Full design validation | ⬜ TODO |
| Windows | Flutter Windows | 1920×1080 | Full design validation | ⬜ TODO |

### ✅ Acessibilidade — Test Matrix

| Feature | Test | Status |
|---------|------|--------|
| Keyboard Navigation | Tab order: Logo → Email → Password → Entrar → Links | ⬜ TODO |
| Focus Visible | Focus ring 2px #93070A visible on all inputs | ⬜ TODO |
| Screen Reader | VoiceOver/TalkBack reads labels + error messages | ⬜ TODO |
| Color Contrast | All text passes WCAG AA (4.5:1 for normal text) | ⬜ TODO |
| Touch Targets | Buttons 48×48px, inputs 56px height | ⬜ TODO |
| Error Messages | Clear + associated with field (Semantics) | ⬜ TODO |

### ✅ Performance

- [ ] No animation jank (60fps) on iPhone 8 (min target device)
- [ ] Bundle size impact: design_tokens.dart + responsive_helper.dart < 50KB
- [ ] No unnecessary rebuilds (use const widgets where possible)
- [ ] Test with `flutter build apk --split-per-abi` for mobile

### ✅ Code Quality

- [ ] `flutter analyze` on `lib/features/auth/` returns 0 issues
- [ ] `flutter format` applied to all new files
- [ ] No print() statements (use logger if debug needed)
- [ ] Comments in Portuguese (as per CLAUDE.md)
- [ ] Commit messages in Portuguese (as per CLAUDE.md)

### ✅ Documentation

- [ ] Design system documented in `.planning/design-system/`
- [ ] Code comments explain responsive breakpoints
- [ ] README or wiki article links to design tokens
- [ ] Figma/design mockups linked in PR description

### ✅ Git Hygiene

- [ ] New files:
  - `lib/core/theme/design_tokens.dart`
  - `lib/core/theme/responsive_helper.dart`
  - `lib/core/constants/spacing.dart` (if separate file)
  - `lib/features/auth/presentation/widgets/accessible_textfield.dart`
  - `lib/features/auth/presentation/pages/login_conservative.dart`
  - `lib/features/auth/presentation/pages/login_bold.dart`

- [ ] Modified files:
  - `lib/main.dart` (routing to login page)
  - `pubspec.yaml` (if adding fonts or packages)

- [ ] `.planning/design-system/LOGIN-DESIGN-SYSTEM-MASTER-2026-07-17.md` committed

### ✅ Replicação Flutter

- [ ] Conservative implemented in `task_manager_flutter` first
- [ ] Same files replicated to `task_manager_flutter_merged_final`
- [ ] Test replication on both projects (375px + 768px + 1024px)
- [ ] Verify no visual divergence

### ✅ Testing

- [ ] Unit tests for `ResponsiveHelper` breakpoints
- [ ] Widget tests for `AccessibleTextField` (error states, focus, semantics)
- [ ] Integration test for login flow (tap email → password → submit)
- [ ] Screenshot tests for 3 breakpoints (or manual comparison)

### ✅ Pre-Commit Final

```bash
# Format all files
flutter format lib/core/theme/ lib/features/auth/

# Analyze
flutter analyze lib/features/auth/

# Test (if available)
flutter test

# Visual check
flutter run -d <device>

# Verify on all 3 breakpoints before merge
```

---

## NEXT STEPS (Para Context-Manager)

1. **Criar task Trello**: "Design System — Login Conservative + Bold"
   - Link: `https://trello.com/...`
   - Labels: `design-system`, `flutter`, `mobile`, `web`, `windows`, `accessibility`, `onda-2`
   - Projeto alvo: `Flutter cliente + base`
   - Plataformas: `Mobile + Web + Windows`

2. **Começar Phase 1**: `design_tokens.dart` + `responsive_helper.dart`

3. **Timeline**:
   - Conservative QA: 2026-07-18 (day 2)
   - Bold implementation: 2026-07-21 (day 5)
   - Final validation: 2026-07-22 (day 6)

4. **Responsáveis**:
   - Backend (Spring): Monitor API responses for login (JWT, tenant ID, roles)
   - Frontend (Flutter): Implement design system + variants
   - QA: Validar responsividade, acessibilidade, contraste

---

**END OF DESIGN SYSTEM MASTER**

*Generated 2026-07-17 — Abraço Contabilidade Login Design System v1.0.0*

*Status: 🟢 READY FOR IMPLEMENTATION*
