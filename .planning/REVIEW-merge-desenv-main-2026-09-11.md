---
repo: task_manager_flutter
revisao: merge desenv -> main
base: origin/main (ffe9d9b6)
alvo: origin/desenv (2a52068a)
reviewed: 2026-09-11T00:00:00-03:00
depth: standard (foco nos 2 commits do usuario + areas de tenant/permissao; commits cosmeticos/.bat nao revisados exaustivamente)
files_reviewed: 12 (dos 45 alterados no diff completo)
files_reviewed_list:
  - lib/auth_screens/login_screen.dart
  - test/auth_screens/login_showcase_test.dart
  - lib/widgets/sessoes_screen.dart
  - test/widgets/sessoes_screen_test.dart
  - lib/utils/api_links.dart
  - lib/utils/menu_config.dart
  - lib/services/permission_service.dart
  - lib/widgets/app_sidebar.dart
  - lib/web/screens/bottom_navbar_screen.dart
  - lib/windows/screens/bottom_navbar_screen.dart
  - lib/widgets/login_empresas_acesso_detail.dart
  - test/widgets/login_empresas_acesso_detail_test.dart
  - lib/web/screens/role_permissao_screen.dart (parcial)
  - lib/widgets/searchable_dropdown.dart (parcial, ~1000 linhas de diff)
  - lib/widgets/generic_detail_form_screen.dart (parcial)
  - lib/web/screens/dashboard_financeiro_screen.dart (parcial)
findings:
  bloqueante: 0
  importante: 4
  menor: 4
  total: 8
status: issues_found
---

# Revisao de Codigo: merge `desenv` -> `main` (task_manager_flutter)

**Revisado em:** 2026-09-11
**Escopo do diff:** `git diff origin/main origin/desenv` — 45 arquivos, 12 commits (10 de sessao concorrente + 2 do usuario: `12d7dc1a`, `2a52068a`).
**flutter analyze:** ja confirmado limpo pelo usuario antes desta revisao (nao refeito).

## Resumo

O diff acumula trabalho de multiplas sessoes. Nao encontrei nenhum problema
que eu classifique como **BLOQUEANTE** para este merge especifico —
os dois pontos de maior risco potencial (tela nova "Sessoes" com acao
destrutiva global, e remocao de uma restricao de acesso multi-empresa
para logins com parceiro) sao mitigados no lado do backend (verifiquei
`SessaoAdminController` e `LoginEmpresaAcessoServiceImpl` em
`C:\App_Academia\AppAcademia`). Ainda assim, marco como **IMPORTANTE**
porque o Flutter, isoladamente, nao tem nenhuma barreira propria contra
esses dois cenarios — a seguranca hoje depende 100% do backend estar
correto, sem redundancia client-side nem teste que prove isso.

Os dois commits proprios do usuario (`12d7dc1a` login sem scroll/logo SVG,
`2a52068a` tela de Sessoes) estao tecnicamente corretos e cobertos por
teste automatizado. O maior debito de qualidade esta em
`generic_detail_form_screen.dart` (commit de sessao concorrente), que
acumulou dezenas de aliases de campo hardcoded dentro de um widget que
deveria ser generico.

## Importante

### IMP-01: Tela "Sessoes" sem guarda de visibilidade explicita no Flutter (depende 100% do backend)

**Arquivos:** `lib/widgets/sessoes_screen.dart`, `lib/utils/menu_config.dart:627-632`, `lib/services/permission_service.dart`, `lib/widgets/app_sidebar.dart:60-80`

O novo item de menu `id: 'sessoes'` (Sistema > Sessoes) **nao** foi adicionado
ao mapa de `PermissionService._getTelaNomeForMenuItem` (os outros itens
novos do mesmo commit — `certificado_digital`, `agendamento_nfe`,
`relatorio_dp_rh`, `alertas`, `permissoes_multi_empresa` — foram, mas
`sessoes` nao). Isso faz `PermissionService().canViewScreen('sessoes')`
retornar `false` sempre (linha 28-30 de `permission_service.dart`: "MenuItem
nao mapeado para telaNome — denegar por padrao"), e a visibilidade do item
cai inteiramente no fallback legado em `app_sidebar.dart:76-79`
(`_allowedIds == null` = MASTER/anti-lockout mostra tudo; senao, compara
`camelCaseId` contra o catalogo dinamico do backend).

Hoje isso e seguro porque `SessaoAdminController` (backend) tem
`@PreAuthorize("@tenantSecurity.isMaster()")` em **todos** os 4 endpoints
(`/api/sessoes`, `/{id}/matar`, `/matar-todas`, `/matar-ociosas`) —
confirmado lendo o controller. Mas o Flutter nao tem nenhuma barreira
propria (nem no estilo do `ownerOnly` hardcoded que ja existe em
`app_sidebar.dart:66-71` para `match`/`timeline`/`instagram_monitor`, nem
mapeamento explicito de tela): se o catalogo dinamico de telas
(`tela_permissao`) algum dia ganhar uma linha "Sessoes" com `podeVer=true`
para outra role (ex.: seed de dados, importacao, ou erro humano no
Controle de Acesso), o item de menu e o botao "Matar todas as sessoes"
ficam visiveis/clicaveis para essa role — a chamada so falharia com 403 no
momento do clique, sem feedback preventivo.

**Fix sugerido:** adicionar `'sessoes'` ao conjunto `ownerOnly`-like (ou um
novo guard explicito `masterOnly`) em `app_sidebar.dart`, ou mapear
`'sessoes'` para uma tela no `PermissionService` com um teste que garanta
que ela nunca aparece para uma role nao-master, mesmo que o catalogo
dinamico mude.

### IMP-02: `generic_detail_form_screen.dart` (widget generico) acumulou dezenas de aliases hardcoded de campos especificos de entidade

**Arquivo:** `lib/widgets/generic_detail_form_screen.dart:188-274` (metodo `_resolveItemValue`) e `:385-451` (sincronizacao de aliases no payload de salvamento)

Este widget e reusado por praticamente todas as telas de detalhe do
sistema (grid/form generico). O commit `cb7c9f5e` (sessao concorrente)
adicionou uma cascata de `if`s com nomes de campo especificos de Parceiro/
ContaBancaria/etc. (`razaoSocial`, `valorMensal`,
`diaVencimentoMensalidade`, `tiposParceiro`, `regime`, `tipoCliente`,
`ambiente`, `moduloServicos`) tanto na leitura (`_resolveItemValue`) quanto
na escrita (bloco de "Sincroniza aliases comuns no payload" perto da
linha 213 do diff). Isso:

- Viola responsabilidade unica: um componente generico agora "conhece"
  campos de negocio de telas especificas.
- E fragil/duplicado: o mesmo alias (`razaoSocial`/`razao_social`) precisa
  ser mantido em pelo menos 2 lugares (leitura e escrita) e crescera a
  cada nova tela com convencao de nome diferente.
- Cria risco de colisao entre entidades diferentes que compartilham o
  componente (ex.: se uma tela futura usar `regime` com outro significado,
  o alias generico aplica sem contexto).

**Fix sugerido:** mover essa tabela de aliases para uma configuracao por
`TelaConfig`/`fieldOverrides` (já existe o mecanismo de override no mesmo
arquivo) em vez de constantes hardcoded no widget generico; ou, melhor,
padronizar o backend para sempre devolver/aceitar um unico casing
(camelCase) e eliminar a necessidade do alias no Flutter.

### IMP-03: Remocao da restricao "login com parceiro nao usa multi-empresa" sem referencia a decisao documentada

**Arquivo:** `lib/widgets/login_empresas_acesso_detail.dart` (commit `f9912b07`)

Antes: `if (loginId == null || loginId <= 0 || widget.loginTemParceiro)` — a
aba "Empresas com acesso"/"Solicitar acesso a outra empresa" ficava oculta
para qualquer login vinculado a um parceiro. O commit `f9912b07` remove a
condicao `widget.loginTemParceiro`, liberando a aba (e a possibilidade de
*solicitar* acesso a outra empresa) para todos os logins, inclusive os
vinculados a parceiro. O teste correspondente foi invertido de "login com
parceiro nao libera solicitacao multiempresa" para "login com parceiro
tambem acessa e solicita empresas multiempresa" — ou seja, e uma mudanca
deliberada de regra de negocio, nao um ajuste cosmetico.

O CLAUDE.md do workspace exige "Consulta Obrigatoria ao Historico de
Decisoes em bugs.md" antes de alterar logica compartilhada que envolva
exibicao de parceiro vs empresa. Nao encontrei essa mudanca documentada em
`C:\App_Academia\bugs.md` (fora do escopo deste diff Flutter, mas e um
pre-requisito do workspace antes do merge).

**Mitigacao confirmada no backend:** verifiquei
`LoginEmpresaAcessoServiceImpl.solicitarAcesso`/`trocarEmpresaAtiva`
(`C:\App_Academia\AppAcademia`) — logins com `parceiro != null` continuam
restritos a solicitar/trocar apenas para empresas do mesmo grupo
matriz/filiais/raiz-de-CNPJ (`listarEmpresasDoGrupoDoParceiro` +
`ForbiddenException` quando fora do grupo). Ou seja, o risco de vazamento
cross-tenant via esse fluxo especifico esta coberto no backend hoje.

**Recomendacao:** registrar a decisao em `bugs.md` antes do merge (ou
confirmar que ja foi pedida explicitamente pelo usuario) e adicionar um
teste que comprove que um login-parceiro so aparece com empresas do
proprio grupo na aba (o teste atual so verifica que a aba fica visivel,
nao que a lista de empresas disponiveis esta corretamente restrita).

### IMP-04 (achado correlato de backend, fora do diff Flutter — reportado por sustentar a analise de risco do IMP-03)

**Arquivo:** `AppAcademia/src/main/java/br/com/appAcademia/service/implementation/LoginEmpresaAcessoServiceImpl.java:341-362` (`garantirGestorDaEmpresa`)

O ultimo fallback desse metodo permite que **qualquer** usuario logado que
tenha um acesso `APROVADO` previo aquela empresa aprove/negue solicitacoes
de **outros** logins para a mesma empresa — sem checar nenhuma role de
gestor/admin (`ROLE_GERENTE`, `ROLE_ESCRITORIO`, etc., que sao verificadas
nos outros ramos do metodo). Isso nao faz parte do diff do
`task_manager_flutter` revisado aqui, mas e a peca de seguranca que
sustenta a mudanca do IMP-03 (agora que qualquer login-parceiro pode abrir
a aba e ver solicitacoes pendentes de aprovar). Recomendo abrir um
apontamento separado para o repositorio `AppAcademia` confirmando se esse
fallback e intencional (ex.: "colega da mesma empresa aprova colega") ou e
um gap de autorizacao.

## Menor

### MEN-01: Mensagem de commit de `12d7dc1a` nao corresponde exatamente ao diff daquele commit

**Commits:** `256fd0ba` e `12d7dc1a`

A mensagem de `12d7dc1a` descreve 3 mudancas, incluindo "logo do header:
Image.asset(logo_contabilidade.jpg) trocado por SvgPicture.asset(logo.svg)".
Na pratica essa troca de logo ja tinha sido feita no commit anterior do
mesmo dia (`256fd0ba`, que tambem introduziu o `FittedBox`/`IntrinsicHeight`
inicial). `12d7dc1a` apenas corrige o "RenderBox was not laid out" causado
por `256fd0ba` ter colocado `GridView`/`ListView`/`LayoutBuilder` dentro do
`IntrinsicHeight`. Nao e um bug funcional (o estado final em `desenv` esta
correto), mas dificulta auditoria: quem le so o commit `12d7dc1a` acha que
a troca de logo aconteceu ali.

### MEN-02: `SessoesScreen._matarSessao` faz cast `as int` sem validar antes

**Arquivo:** `lib/widgets/sessoes_screen.dart:93`

```dart
final res = await _caller.postRequest(ApiLinks.matarSessao(loginId as int), {});
```

Se o backend devolver um registro sem `loginId` (ou tipo inesperado), o
cast lanca `TypeError` — capturado pelo `catch (e)` generico do mesmo
metodo, entao nao quebra a tela, mas a mensagem ao usuario
("Erro ao encerrar sessao: type 'Null' is not a subtype of type 'int'")
e pouco amigavel. Sugestao: validar `loginId is int` antes de montar o
dialogo de confirmacao e mostrar mensagem especifica se vier invalido.

### MEN-03: Erro parcial de pagina (`PaginaDropdown.erro`) e descartado quando ha itens

**Arquivo:** `lib/widgets/searchable_dropdown.dart` (`_carregarPrimeiraPagina`/`_carregarProximaPagina`)

`_erro` (vindo de `PaginaDropdown.erro`) só é renderizado no branch em que
`_filtered.isEmpty`. Se uma pagina vier com `items` preenchido mas
`erro != null` (ex.: falha ao calcular `total` mas paginacao parcial
funcionou), o erro fica silenciosamente descartado — o usuario nao ve
nenhum aviso de que o resultado pode estar incompleto.

### MEN-04: Estado estatico mutavel `_instanciaComOverlayAberto` como coordenador global de overlay

**Arquivo:** `lib/widgets/searchable_dropdown.dart:128` (`_SearchableDropdownFieldState._instanciaComOverlayAberto`)

Um campo `static` guarda a instancia do `State` que possui o overlay
inline aberto, usado para fechar overlays concorrentes quando outro campo
e aberto. Funciona para o caso de uso atual (um unico overlay por vez na
tela), mas e um code smell de estado global mutavel dentro de um widget
que deveria ser independente por instancia — dificulta testes paralelos
de widget e pode gerar comportamento inesperado se duas arvores de widget
distintas (ex.: dois `MaterialApp` em teste) compartilharem o mesmo
processo Dart. Nao bloqueante, mas vale documentar a limitacao ou migrar
para um `InheritedWidget`/coordinator escopado por `Overlay` local.

## Pontos positivos observados

- `12d7dc1a`: troca de `GridView`/`ListView`/`LayoutBuilder` por
  `Wrap`/`Column` dentro do `IntrinsicHeight` esta correta e documentada;
  novo teste (`login_showcase_test.dart`) cobre 1920x1080 e 1024x700 sem
  exception.
- `2a52068a`: tratamento de erro explicito com `AppLogger.i.warn/error` em
  todos os caminhos de rede de `sessoes_screen.dart` (carregar, matar uma,
  matar todas), com feedback via `SnackBar` — segue a regra de
  "Monitoramento de Logs" do CLAUDE.md do workspace.
- Backend `SessaoAdminController` restringe corretamente todos os 4
  endpoints a MASTER via `@PreAuthorize`.
- Backend `LoginEmpresaAcessoServiceImpl` mantem o escopo de
  matriz/filial/grupo-CNPJ para logins-parceiro mesmo apos a liberacao de
  UI feita em `f9912b07`.
- Padrao de "token" (`_searchToken`/`token != _searchToken`) usado
  consistentemente em `searchable_dropdown.dart` para invalidar respostas
  tardias de busca — evita a classe de bug "resposta antiga sobrescreve
  busca atual" em pelo menos 4 lugares distintos do arquivo.

---

_Revisado em: 2026-09-11_
_Revisor: Claude (revisao adversarial de codigo)_
_Escopo: diff origin/main..origin/desenv de C:\App_Academia\task_manager_flutter, com verificacao cruzada pontual no backend AppAcademia para confirmar mitigacoes de seguranca_
