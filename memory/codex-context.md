# Codex Context

## Project Facts
- 2026-06-21: O dashboard generico atual mistura dominios. Em ambos os apps, `lib/mobile/screens/dashboard_screen.dart`, `models/dashboard_model.dart` e `services/dashboard_caller.dart` combinam indicadores financeiros (fluxo de caixa, saldos, tendencias, vencimentos e distribuicao por clientes) com Atendimento (chamados, tendencias de chamados, chats e atividade diaria).
- 2026-06-21: Ja existem dashboards dedicados que devem ser reaproveitados: Financeiro em `web/windows/screens/dashboard_financeiro_screen.dart` com `services/dashboard_financeiro_caller.dart`, e Departamento Pessoal em `widgets/dp/dp_dashboard_screen.dart` com `ApiLinks.dpDashboard`.
- 2026-06-21: Os dois apps Flutter divergiram no dashboard generico. `task_manager_flutter` acrescentou ao dashboard compartilhado o bloco de Departamento Pessoal, relatorios/exportacoes e `UserBannerAppBar`; `task_manager_flutter_merged_final` nao possui esse conjunto. A reorganizacao deve reconciliar a diferenca sem copiar novamente DP para Atendimento.
- 2026-05-29: Empresa cadastro backend stores `centro_custo_obrigatorio` as non-null boolean; `Empresa` now defaults/null-guards it to `false`, and Flyway migration `V20260612__fix_empresa_centro_custo_default.sql` backfills/defaults existing rows.
- 2026-05-28: The mobile Flutter app now uses `lib/customization/dynamic_grid_dynamic_screen.dart` as the preferred dynamic CRUD screen for dictionary-driven mobile grids/forms.
- 2026-05-28: Dynamic mobile grids remain mobile-native card lists, not web-style data tables. Related dictionary tabs now open mobile dynamic grids on narrow screens through `GenericDetailFormScreen`.
- 2026-05-28: `GenericMobileGridScreen` must render only one app bar. The inner `GridListScreen` should run without its own app bar/fab when wrapped by `grid_page.dart`; otherwise screens like Comunicado show duplicated headers and actions.
- 2026-05-29: Mobile dynamic tabs using the same widget type must provide a distinct `ValueKey` per `telaNome`; otherwise Flutter can reuse the previous dynamic screen state when switching from Comunicado to Solicitacoes.
- 2026-05-29: `BottomNavBarScreen` owns the mobile `AppLoggerOverlay` so console history survives tab changes. Dynamic screens should not add their own overlay.

## Decisions
- 2026-06-21: Dashboards serao separados por dominio: Atendimento concentra chamados, chats, fila, SLA, volume e produtividade; Financeiro concentra caixa, contas a pagar/receber, saldos, inadimplencia, projecoes e vencimentos financeiros; Comercial concentra leads, funil, propostas, conversao, clientes e receita prevista; Departamento Pessoal concentra folha, ponto, ferias, admissoes, desligamentos e obrigacoes trabalhistas; Fiscal concentra obrigacoes, documentos, escrituracoes, notas, guias e situacao fiscal.
- 2026-06-21: Fiscal pode exibir situacao e vencimento de guia, mas valor, pagamento e baixa pertencem ao Financeiro e devem ser acessados por referencia ou drill-down explicito. O dashboard existente sera reorganizado como Atendimento, retirando os blocos financeiros e o bloco de DP indevidamente incorporado no app do cliente.
- 2026-06-21: O planejamento foi dividido em sete cards, nesta ordem de dependencia: Fundacao primeiro; depois Atendimento, Financeiro, Comercial, DP e Fiscal podem evoluir sobre os contratos segregados; QA legado valida o conjunto ao final. Cada alteracao compartilhada deve manter `task_manager_flutter_merged_final` e `task_manager_flutter` funcionalmente equivalentes, com permissao por setor e isolamento por empresa/parceiro.
- 2026-06-21: Os dois cards financeiros antigos encontrados ja estao em `Done` e nao substituem a consolidacao atual: `Dashboard Financeiro com KPIs e Projecoes` (ID `6a20837162909d554eb832bc`, https://trello.com/c/saNPnR9n) e `Dashboard financeiro gerencial` (ID `6a08cc00c5c9576960004cce`, https://trello.com/c/3DMerdEa).

## Dashboard Backlog
- 2026-06-21: Fundacao/segregacao dos dashboards - ID `6a380fe450dc82a32c82b875` - https://trello.com/c/nYPnejcU
- 2026-06-21: Dashboard Atendimento - ID `6a380febc3b56b3ccb66b35f` - https://trello.com/c/93huyR3V
- 2026-06-21: Consolidacao do Dashboard Financeiro - ID `6a380ff060b63e476b9b5846` - https://trello.com/c/ikVog2FF
- 2026-06-21: Dashboard Comercial - ID `6a380ff6f644e62f144485cd` - https://trello.com/c/52zAz5SG
- 2026-06-21: Dashboard Departamento Pessoal - ID `6a380ffb44674115cafdee5c` - https://trello.com/c/NOYlWGQV
- 2026-06-21: Dashboard Fiscal - ID `6a381000b6274975059bfcc7` - https://trello.com/c/j6zbvXDN
- 2026-06-21: QA e regressao do dashboard legado - ID `6a381005001410c4cfa313f8` - https://trello.com/c/RjRmvZwX
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
- Implementar os sete cards de dashboards a partir do Backlog, respeitando a dependencia da fundacao e a validacao transversal de QA.
- Antes de remover blocos do dashboard generico, mapear rotas, permissoes e endpoints consumidos em web, Windows e mobile nos dois apps para evitar perda funcional durante a migracao.
- Verify at runtime with an authenticated production-login user that the deployed backend returns data for the dynamic mobile screens and no longer returns the local-backend 403.
