---
commit: 010eaa3
repo: task_manager_flutter (branch main)
reviewed: 2026-06-25T13:40:00-03:00
depth: standard
files_reviewed: 2
files_reviewed_list:
  - lib/mobile/screens/login_grid_screen.dart
  - lib/mobile/screens/bottom_navbar_screen.dart
findings:
  critical: 0
  warning: 3
  info: 3
  total: 6
status: issues_found
---

# Review: feat: tela de Usuarios no mobile (paridade com Web/Windows)

**Reviewed:** 2026-06-25
**Depth:** standard
**Files Reviewed:** 2 (1 novo, 1 alterado)
**Status:** issues_found

## Summary

A tela mobile `LoginGridScreen` segue corretamente o padrao de `ParceiroGridScreen`
(mesmo componente generico `DynamicGridDynamicScreen`, mesma estrutura de
helpers estaticos `_extractList`/`_extractFrom`), e o gating de menu via
`AppScreen.logins` + `sec.canView()` esta implementado de forma consistente
com o resto do `bottom_navbar_screen.dart`. Nao ha mecanismo de rota nomeada
ou deep link no app que permita contornar o menu para chegar em
`LoginGridScreen` — a unica chamada ao construtor fora do arquivo proprio
esta dentro do `case "Usuários":`, que so existe atras da entrada de menu
gateada.

O campo `senha` esta protegido por heuristica generica de nome
(`_telaType`/`field_factory.dart`), entao nao ha exposicao de senha em texto
puro pelo grid generico — isso e tratamento automatico do componente, nao
algo que o autor do card precisasse declarar explicitamente.

Apesar disso, ha gaps reais de paridade funcional com Web/Windows (acao
"Permissões" com dialogo dedicado de roles, ausente no mobile) e duplicacao
de logica que o proprio padrao do projeto (`ParceiroGridScreen`) ja resolveu
de forma mais generica em outro ponto, mas que este commit nao reaproveitou
plenamente. Nenhum achado bloqueante de seguranca foi confirmado.

## Warnings

### WR-01: Gap de paridade funcional — falta acao "Permissões" com RoleDialog dedicado

**File:** `lib/mobile/screens/login_grid_screen.dart` (build(), linha ~108-150)
**Issue:** Web (`lib/web/screens/login_grid_screen.dart:147-169`) e Windows
(`lib/windows/screens/login_grid_screen.dart:146-165`) tem um `customActions`
com icone "Permissões" que abre `WebRoleDialog`/`RoleDialog` — um fluxo
dedicado de gerenciamento de roles por login, separado do campo `roles`
simples do formulario. O mobile so tem o campo `FieldConfig` multiselect
`roles` no formulario generico, sem `customActions` nem `detailScreenBuilder`
equivalentes. Isso pode nao ser apenas uma omissao de UI: se o dialogo de
roles do Web faz alguma logica adicional (ex.: validacao cruzada, chamada a
endpoint especifico de permissoes em vez do PUT generico do login), a
paridade alegada no commit ("mesmos fieldOverrides do Web") e parcial — falta
a feature de gerenciamento de permissoes, nao so o campo.
**Fix:** Confirmar com o dono do produto se a tela de Permissões e essencial
no mobile nesta fase. Se for, criar um `RoleDialog` mobile equivalente
(ou reusar o Web/Windows adaptando import) e adicionar `customActions` ao
`LoginGridScreen` mobile. Se for decisao consciente de adiar, documentar a
decisao no card/commit para nao ser confundido com bug.

### WR-02: Duplicacao de 4 helpers estaticos de dropdown ja resolvida em outro padrao do projeto

**File:** `lib/mobile/screens/login_grid_screen.dart:18-48`
**Issue:** `_loadEmpresas`, `_loadParceiros`, `_loadAplicativos` sao
estruturalmente identicos entre si (mesmo padrao: `getRequest` + `_extractList`
+ map para `{id, label}`), diferindo apenas no endpoint e no campo de label
(`nome`). `ParceiroGridScreen` (`lib/mobile/screens/parceiro_grid_screen.dart:106-110`)
ja tem um helper generico `_loadDropdown(String endpoint)` que faz a parte
de fetch+extract, reaproveitado para 5 dropdowns diferentes sem duplicar a
logica de fetch. `LoginGridScreen` poderia ter usado o mesmo
`_loadDropdown` (ou copiado a função genérica) e aplicado apenas o `.map`
especifico para cada um, reduzindo de 3 metodos quase-identicos para 1
generico + 3 maps curtos. `_loadRoles` tem logica de label mais complexa
(fallback description/key/id) e legitimamente precisa ser especial, mas os
outros 3 nao.
**Fix:**
```dart
// Reaproveitar o padrao de _loadDropdown (igual ParceiroGridScreen)
static Future<List<Map<String, dynamic>>> _loadEmpresas() =>
    _loadAndMap(ApiLinks.allEmpresas);
static Future<List<Map<String, dynamic>>> _loadParceiros() =>
    _loadAndMap(ApiLinks.allParceiros);
static Future<List<Map<String, dynamic>>> _loadAplicativos() =>
    _loadAndMap('${ApiLinks.baseUrl}/api/aplicativo');

static Future<List<Map<String, dynamic>>> _loadAndMap(String endpoint) async {
  final response = await NetworkCaller().getRequest(endpoint);
  return _extractList(response)
      .map((e) => {'id': e['id'].toString(), 'label': e['nome'].toString()})
      .toList();
}
```
Isso tambem reduz risco: se o tratamento de erro de rede precisar mudar
(ex.: logar falha em vez de silenciosamente retornar lista vazia), so um
lugar precisa ser tocado em vez de 3.

### WR-03: `_extractList`/`_extractFrom` duplicados byte-a-byte em terceiro arquivo

**File:** `lib/mobile/screens/login_grid_screen.dart:50-71`
**Issue:** Os metodos `_extractList` e `_extractFrom` sao copia identica dos
mesmos metodos em `lib/mobile/screens/parceiro_grid_screen.dart:112-136`
(confirmado linha a linha). Esta e a segunda vez que esta logica de
normalizacao de resposta de API (`data`/`dados`/`items`/`content`/`account`)
e duplicada em um arquivo de tela mobile. Se a API mudar o formato do
envelope de resposta (por exemplo adicionar uma chave nova `results`), sera
necessario editar N arquivos de tela em vez de 1 util compartilhado.
**Fix:** Extrair `_extractList`/`_extractFrom` para um helper compartilhado
(ex.: `lib/customization/generic_grid/api_response_extractor.dart` ou metodo
estatico em `NetworkCaller`/`NetworkResponse`) e fazer `ParceiroGridScreen` e
`LoginGridScreen` importarem dele, em vez de cada tela nova repetir a copia.
Nao e bloqueante porque segue o padrao ja estabelecido (ParceiroGridScreen
fez a mesma coisa antes), mas o problema cresce a cada tela nova copiada.

## Info

### IN-01: Campo `senha` depende inteiramente de heuristica de nome do componente generico — nao documentado no commit

**File:** `lib/mobile/screens/login_grid_screen.dart` (ausencia de `FieldConfig` para `senha`)
**Issue:** Confirmado por leitura do componente generico
(`lib/customization/dynamic_grid_dynamic_screen.dart:696-697` e
`lib/widgets/field_factory.dart:51`) que campos chamados `senha`/`*_senha`/
`password` recebem `FieldType.password` automaticamente, sem necessidade de
`fieldOverride` explicito — e por isso o card nao precisou declarar
tratamento para "senha". Isso e correto e seguro, mas e um comportamento
implicito do framework do qual o autor do commit depende silenciosamente.
Se algum dia o backend renomear o campo (ex.: `senhaHash` ou `senha_atual`),
a deteccao por sufixo `_senha` ainda cobre `senha_atual`-like, mas nao cobre
nomes sem o token `senha` (ex.: `credencial`). Nao e um bug deste commit,
mas vale registrar a dependencia para quem for alterar o backend de Login
no futuro.
**Fix:** Nenhuma acao necessaria agora. Se o backend renomear o campo,
validar manualmente que o novo nome ainda cai em uma das regras de
deteccao de `_telaType`, ou adicionar `FieldConfig` explicito com
`fieldType: FieldType.password` no override.

### IN-02: Inconsistencia de robustez entre `_loadRoles` e os demais 3 helpers (null-safety de campos remotos)

**File:** `lib/mobile/screens/login_grid_screen.dart:18-48`
**Issue:** `_loadEmpresas`/`_loadParceiros`/`_loadAplicativos` fazem
`e['nome'].toString()` sem checagem de nulo — se a API retornar um registro
sem campo `nome` (ou com `nome: null`), o `.toString()` em um valor `null`
do Dart retorna a string `"null"` (nao lanca exception, pois `null` em Dart
responde a `toString()`), entao o dropdown mostraria literalmente o texto
"null" como label em vez de falhar visivelmente. Isso e copiado
identicamente do Web (`lib/web/screens/login_grid_screen.dart:47-78`), logo
nao e regressao introduzida por este commit — e um padrao pre-existente
replicado.
**Fix:** Nao bloqueante para este commit especifico (segue o padrao
existente), mas se outra sessao for tocar esses helpers, considerar
`e['nome']?.toString() ?? '(sem nome)'` para evitar labels confusos no
dropdown.

### IN-03: `dropdownFutureBuilder: _loadRoles` no mobile referencia metodo privado, enquanto Web expõe `loadRoles` publico

**File:** `lib/mobile/screens/login_grid_screen.dart:18` vs `lib/web/screens/login_grid_screen.dart:17`
**Issue:** No Web, `loadRoles` e um metodo estatico publico (sem `_`), o que
sugere que outro arquivo do Web reaproveita esse carregamento de roles (por
exemplo, algum dialogo de permissoes). No mobile, `_loadRoles` e privado.
Isso e coerente *se* o mobile nao tiver (ainda) um RoleDialog equivalente
(ver WR-01) — mas se WR-01 for endereçado depois, sera necessario tornar o
metodo publico ou duplicar a logica de roles uma terceira vez.
**Fix:** Ao resolver WR-01, avaliar se vale a pena tornar `_loadRoles`
publico (`loadRoles`) desde ja, evitando mais uma duplicacao futura.

---

_Reviewed: 2026-06-25_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
