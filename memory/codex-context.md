# Codex Context

## Project Facts
- 2026-05-29: Empresa cadastro backend stores `centro_custo_obrigatorio` as non-null boolean; `Empresa` now defaults/null-guards it to `false`, and Flyway migration `V20260612__fix_empresa_centro_custo_default.sql` backfills/defaults existing rows.
- 2026-05-28: The mobile Flutter app now uses `lib/customization/dynamic_grid_dynamic_screen.dart` as the preferred dynamic CRUD screen for dictionary-driven mobile grids/forms.
- 2026-05-28: Dynamic mobile grids remain mobile-native card lists, not web-style data tables. Related dictionary tabs now open mobile dynamic grids on narrow screens through `GenericDetailFormScreen`.
- 2026-05-28: `GenericMobileGridScreen` must render only one app bar. The inner `GridListScreen` should run without its own app bar/fab when wrapped by `grid_page.dart`; otherwise screens like Comunicado show duplicated headers and actions.
- 2026-05-29: Mobile dynamic tabs using the same widget type must provide a distinct `ValueKey` per `telaNome`; otherwise Flutter can reuse the previous dynamic screen state when switching from Comunicado to Solicitacoes.
- 2026-05-29: `BottomNavBarScreen` owns the mobile `AppLoggerOverlay` so console history survives tab changes. Dynamic screens should not add their own overlay.

## Decisions
- 2026-05-28: Mobile CRUD screens that have a backend `TelaConfig` should prefer `DynamicGridDynamicScreen` with `Map<String, dynamic>` instead of model-specific grid widgets. This matches the web/windows dynamic dictionary pattern while keeping special screens such as Dashboard, Trading, PDV, GED, Ponto and Mensalidades as dedicated screens.
- 2026-05-28: Do not force the web grid layout onto Android. Mobile should use scannable cards, bottom/modal forms, filters, and tabbed detail screens.
- 2026-05-28: Server actions with `:id` are per-row actions on mobile and should not appear as global top buttons.
- 2026-05-29: `chamado`, `comunicado`, `alvara`, `conta_pagar`, `conta_receber`, `parceiro`, `produto`, `conta_bancaria`, and `funcionario` have local mobile fallback `TelaConfig`s to avoid a fatal error when `/api/telas/{nome}` returns 403/not found. Data endpoints can still return 403 if backend authorization denies the logged-in user.
- 2026-05-29: For BlueStacks validation against the same backend as the deployed web app, build with `--dart-define=BACKEND_URL=https://appacademia-production-be7e.up.railway.app` and clear app data before logging in again so the token is issued by that backend.
- 2026-05-29: Mobile bottom navigation must render tab content through `IndexedStack(index: safeIndex, children: screens)`. A direct `Positioned.fill(child: screens[safeIndex])` in the shell caused blank-looking tabs after navigation/build changes; `IndexedStack` restored Calendar, Chat, GED, and dynamic grid rendering and preserves tab state.

## Validated Commands
- `dart analyze lib\customization\generic_grid_card.dart lib\customization\generic_grid\grid_form.dart lib\customization\generic_grid_card_1_1.dart`: passed on 2026-05-29 after boolean payload and copy-error fixes.
- `$env:JAVA_HOME='C:\Program Files\Java\jdk-17'; $env:PATH="$env:JAVA_HOME\bin;$env:PATH"; .\mvnw.cmd -q -DskipTests compile`: passed on 2026-05-29 for AppAcademia backend after Empresa default fixes.
- `dart analyze lib\mobile\screens\bottom_navbar_screen.dart lib\customization\dynamic_grid_dynamic_screen.dart`: passed on 2026-05-28.
- `$env:GRADLE_USER_HOME="$env:USERPROFILE\.gradle"; flutter build apk --debug --dart-define=BACKEND_URL=http://10.0.2.2:9001`: passed on 2026-05-28.
- `dart analyze lib\customization\dynamic_grid_dynamic_screen.dart lib\customization\generic_grid\grid_page.dart lib\widgets\generic_detail_form_screen.dart`: passed on 2026-05-28.
- `$env:GRADLE_USER_HOME="$env:USERPROFILE\.gradle"; flutter build apk --debug --dart-define=BACKEND_URL=http://192.168.100.113:9001`: passed on 2026-05-28.
- `dart analyze lib\customization\generic_grid\grid_page.dart lib\customization\generic_grid\grid_list.dart lib\customization\dynamic_grid_dynamic_screen.dart lib\mobile\screens\file_upload_screen.dart lib\windows\screens\documento_screen.dart`: passed on 2026-05-28.
- `dart analyze lib\customization\dynamic_grid_dynamic_screen.dart`: passed on 2026-05-29 after adding local fallbacks.
- `$env:GRADLE_USER_HOME="$env:USERPROFILE\.gradle"; flutter build apk --debug --dart-define=BACKEND_URL=https://appacademia-production-be7e.up.railway.app`: passed on 2026-05-29.
- `dart analyze lib\mobile\screens\bottom_navbar_screen.dart`: passed on 2026-05-29 after the `IndexedStack` mobile shell fix.
- `$env:GRADLE_USER_HOME="$env:USERPROFILE\.gradle"; flutter build apk --debug --dart-define=BACKEND_URL=http://192.168.100.113:9001`: passed on 2026-05-29 after the mobile shell fix.

## Open Items
- Verify at runtime with an authenticated production-login user that the deployed backend returns data for the dynamic mobile screens and no longer returns the local-backend 403.
