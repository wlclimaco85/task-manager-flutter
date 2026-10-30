# CLAUDE.md — task_manager_flutter (App Abraço Contabilidade)

> Regras globais da workspace estão em `C:\App_Academia\CLAUDE.md`. Em conflito, o pai prevalece.

## Project

**Flutter cliente principal — Escritório contábil específico (Abraço Contabilidade) e seus clientes.**

É o app **oficial e vitrine** do escritório Abraço: portal do escritório para seus clientes. Consome
o backend `AppAcademia`. Layout oficial com Tela de Login com vitrine/showcase lateral (módulos
inclusos/opcionais, link da Play Store, painel demonstrativo) — essa tela é a referência e **não pode
ser substituída por versões simplificadas**.

**Core Value:** é a origem da tríade Flutter. O que nasce aqui (correções, regras compartilhadas,
widgets genéricos) é replicado nos outros apps. É o "golden master" de comportamento.

## Stack & Plataformas

- **Flutter/Dart**, Material 3. Package Android: `com.washingtonclimaco.task_manager_flutter`.
- **Plataformas: android, ios, windows, web, macos, linux** (paridade multiplataforma obrigatória).
- **Fastlane configurado** (`android/fastlane/`, `fastlane/`): publicação Play Store via `PLAY_STORE_JSON_KEY_PATH`.
- Entradas: `main.dart`, `main_web.dart`, `main_windows.dart`.

## Tema (IDENTIDADE PRÓPRIA — NÃO MISTURAR)

- Tema em `lib/core/theme/` (`tokens.json` + `*_breakpoint_styles.dart`) e `lib/constants/custom_colors.dart`.
- Identidade: paleta clara verde/off-white (page `#F6FAF7`, texto `#17211B`) — linha "fitness/contábil" do Abraço.
- **PROIBIDO** importar/copiar tema de outro app da workspace. Cada projeto tem seu tema; `lib/core/theme/`,
  `lib/config/theme*` e arquivos com `color/theme/palette` no nome **não** se replicam entre projetos.

## Arquitetura

- `lib/` organizado por: `web/`, `windows/`, `mobile/` (telas por plataforma), `screens/`, `widgets/`
  (genéricos: GenericGrid, SearchableDropdownField, Dialogs, Inputs), `services/`, `models/`,
  `providers/`, `repositories/`, `core/`, `features/`.
- **Paridade multiplataforma OBRIGATÓRIA:** toda tela/ação criada em Web/Windows TEM que existir no
  Mobile (`lib/mobile/screens/` + `MobileBottomNavbarScreen`), com layout mobile nativo (Column
  vertical, alvos ≥44px, sem sidebar horizontal).
- **Dois sistemas de permissão distintos:** `SecurityMatrix`/`AppScreen` (bottom-nav mobile) e
  `PermissionService`/`RolePermissionCatalog`/`MenuConfig` (menu lateral Web/Windows + Controle de
  Acesso). Tela nova precisa aparecer nos dois e em `PermissionService._menuIdToTelaNome`.

## Replicação de Componentes (CRÍTICO)

- **Tríade:** `task_manager_flutter` ⇆ `task_manager_flutter_merged_final` ⇆ `task_manager_flutter_por_cliente`.
  Correção de bug, regra de negócio compartilhada, contrato de API, network caller, models universais,
  auth/tokens, helpers, formatters e widgets genéricos **DEVEM ser replicados nos 3** (e, para o sub
  menu "Sistema", também no `task_manager_admin_panel`).
- Ao replicar: adaptar imports/paths, **nunca** copiar tema/branding, manter comportamento equivalente.
- **NÃO replicar** para `por_cliente` telas de escritório contábil (Chat, Chamados, GED, Alvarás).

## UI/UX (OBRIGATÓRIO para mudança de layout)

- Toda alteração de **layout/design/experiência visual** DEVE envolver o agente de UI/UX
  (`ui-ux-pro-max` ou skill `frontend-design`). Correção funcional preserva 100% do layout existente
  (menor diff; proibido reescrever tela inteira).

## Componente de Cadastro / Detail + Abas de Relação (PONTO CRÍTICO — já reabriu várias vezes)

O insert pelo componente de *detail* e as abas de relação (ex.: Setores, Roles do Login) são o ponto
que mais reincide. Ao mexer em qualquer tela de detail/cadastro ou em vínculo (role, setor, aba de
relação), o teste do cenário é OBRIGATÓRIO e cobre o ciclo REAL ponta a ponta:
`inserir → salvar (confirmar sucesso) → reabrir o detail → conferir que persistiu → abrir a aba de
relação e conferir que o vínculo aparece`. Trocar a role de um usuário DEVE refletir na grid, sem
cache de roles antigas. Lembrar dos dois sistemas de permissão (`SecurityMatrix` e
`PermissionService`/`MenuConfig`). Proibido declarar pronto sem esse teste verde (ver Definition of
Done no CLAUDE.md pai).

## Testes & Code Review (OBRIGATÓRIO)

- **Criar e rodar o teste do cenário (`flutter test` focado) antes de concluir** — que reproduz o fluxo
  exato pedido. NÃO a suíte inteira (essa só antes de push pra `main`). `flutter analyze` é só apoio, não prova.
- Atenção: NUNCA find-replace em massa `const`→`final` (quebra `String.fromEnvironment` em runtime).
- **Commit + push para `main` → code review OBRIGATÓRIO** antes do merge. Branch base: `desenv`.
- Encoding UTF-8.
