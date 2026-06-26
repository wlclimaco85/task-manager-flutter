---
commit: de38320c4f0c8ece280fc3c9756391e09eabb297
repo: task_manager_flutter (branch main)
reviewed: 2026-06-25
depth: standard
files_reviewed: 5
files_reviewed_list:
  - lib/services/solicitacao_acesso_caller.dart
  - lib/widgets/solicitacao_acesso_aprovacao_screen.dart
  - lib/web/screens/bottom_navbar_screen.dart
  - lib/windows/screens/bottom_navbar_screen.dart
  - lib/utils/menu_config.dart
findings:
  critical: 1
  warning: 3
  info: 2
  total: 6
status: issues_found
---

# Review: de38320 — Tela de aprovação de solicitações de acesso

**Reviewed:** 2026-06-25
**Depth:** standard
**Files Reviewed:** 5 (Flutter) + leitura cruzada de 3 arquivos do backend (AppAcademia) para validar o achado crítico
**Status:** issues_found

## Summary

O commit em si (Flutter) está bem escrito: mascaramento de documento robusto, dialogs de confirmação, estado vazio/skeleton, e o item de menu sem gating é consistente com o padrão (nenhum `MenuItem` no projeto tem campo de permissão). **O achado crítico real está no backend (`AppAcademia`), fora deste commit**, mas afeta diretamente os dados que esta tela Flutter consome: o endpoint `GET /api/solicitacao-acesso/pendentes` está vazando `senhaHash` no JSON porque o controller serializa a entity JPA diretamente em vez do DTO `SolicitacaoResponse` que já existe no código (mas não é usado). O Flutter não exibe nem retém esse campo, mas o vazamento ocorre na rede/payload HTTP antes de chegar ao cliente, então não há mitigação possível só no Flutter.

## Critical Issues

### CR-01: Endpoint `/api/solicitacao-acesso/pendentes` (backend AppAcademia) expõe `senhaHash` no JSON — fora do escopo deste commit Flutter, mas a tela consome esse payload

**Arquivos (backend, repo `AppAcademia`, NÃO alterados neste commit):**
- `AppAcademia/src/main/java/br/com/appAcademia/persistence/entity/SolicitacaoAcesso.java:30-31` — `@Column(name = "senha_hash") private String senhaHash;` com `@Data` (Lombok) gerando `getSenhaHash()` público, sem `@JsonIgnore`.
- `AppAcademia/src/main/java/br/com/appAcademia/controller/SolicitacaoAcessoController.java:47-56` (`listarPendentes`) e também `:27-45` (`criar`), `:58-83` (`aprovar`), `:85-110` (`rejeitar`) — todos retornam `service.listarPendentes(...)`/`service.aprovar(...)`/etc. como a **entity `SolicitacaoAcesso` inteira** dentro de `Response.data`, em vez do DTO `SolicitacaoAcessoDTOs.SolicitacaoResponse` que já existe no código (`AppAcademia/src/main/java/br/com/appAcademia/persistence/dtos/SolicitacaoAcessoDTOs.java:13-24`) e **não é usado em lugar nenhum do controller**.

**Issue:** Jackson, por padrão, serializa todo getter público de uma classe anotada implicitamente como bean (sem `@JsonIgnoreProperties`/`@JsonIgnore` na entity). Como `@Data` gera `getSenhaHash()`, o JSON de resposta de `/pendentes`, `/aprovar` e `/rejeitar` inclui o hash da senha de cada solicitante. Isso é exposição de credencial (mesmo hasheada) para qualquer cliente autenticado que tenha acesso à tela — inclusive em qualquer outra integração futura que bata neste endpoint sem saber que isso ocorre. Hash exposto facilita ataque offline (rainbow table/crack) caso o algoritmo de hash seja fraco ou sem salt adequado — não foi auditado nesta revisão, mas o princípio de não expor é violado independentemente do algoritmo.

**Confirmação pedida no item 5 da revisão:** sim, `SolicitacaoAcessoItem.fromJson` (Flutter, `lib/services/solicitacao_acesso_caller.dart:23-32`) só lê `id`, `nome`, `email`, `cpfCnpj`, `status`, `parceiroIdResolvido`, `dataCriacao` — não referencia `senhaHash` em nenhum momento, não armazena em memória, não loga. O Flutter está correto e não amplifica o vazamento. O problema é 100% no payload de rede antes de chegar ao Flutter (visível em qualquer DevTools/proxy/log de acesso HTTP do backend).

**Fix (a aplicar no repo `AppAcademia`, não neste commit):**
```java
// Opção recomendada: usar o DTO que já existe e está órfão
@GetMapping("/pendentes")
public ResponseEntity<Response> listarPendentes() {
    List<SolicitacaoAcesso> lista = service.listarPendentes(tenantContext);
    List<SolicitacaoAcessoDTOs.SolicitacaoResponse> dtos = lista.stream()
        .map(e -> new SolicitacaoAcessoDTOs.SolicitacaoResponse(
            e.getId().longValue(), e.getNome(), e.getCpfCnpj(), e.getEmail(),
            null, e.getStatus().name(), null,
            e.getParceiroIdResolvido() == null, e.getDataCriacao()))
        .toList();
    return ResponseEntity.ok(Response.builder().data(dtos)
        .response(new ResponseError(false, "Lista de solicitações pendentes", HttpStatus.OK.value()))
        .build());
}
```
Alternativa mínima (mais rápida, menos limpa): anotar `@JsonIgnore` em `senhaHash` na entity. Mas isso é um band-aid — a entity ainda seria serializada diretamente em 4 endpoints (`criar`, `pendentes`, `aprovar`, `rejeitar`), repetindo o risco a cada novo campo sensível futuro. Recomenda-se migrar todos os 4 endpoints para o DTO.

**Ação recomendada:** abrir achado separado/urgente no repositório `AppAcademia` (fora deste commit Flutter). Verificar se o endpoint já está em produção e se há log de acesso HTTP retendo o payload (compliance/LGPD, já que é dado de credencial de pessoa física).

## Warnings

### WR-01: `_extrairMensagemErro` (caller) + comparação de string mágica `'já foi processada'` (tela) é frágil e tem fallback que mascara mensagens reais do backend

**Arquivo:** `lib/services/solicitacao_acesso_caller.dart:96-104` e `lib/widgets/solicitacao_acesso_aprovacao_screen.dart:113-118`

**Issue:** Dois problemas distintos aqui:
1. `_extrairMensagemErro` faz fallback para a string fixa `'Esta solicitação já foi processada por outro usuário.'` sempre que o parsing do JSON de erro falha OU quando `message` vem vazio/nulo — isso significa que **qualquer erro 403/404/500 que não tenha JSON parseável vira, para o usuário, uma mensagem de "concorrência"**, mesmo que a causa real seja outra (ex.: token expirado, erro 500 de banco). Isso é enganoso para o usuário e mascara o diagnóstico real.
2. A tela decide se deve recarregar a lista comparando `erro.contains('já foi processada')` — string mágica acoplada à mensagem do backend. Se a mensagem do backend mudar (ex.: revisão de copy, i18n), a auto-reload silenciosamente deixa de funcionar, sem erro visível, sem teste que pegue a regressão.

**Fix:** Usar o `statusCode` HTTP para decidir a ação, não o texto. O backend já diferencia: 404 = não encontrada (provável já processada/concorrência), 403 = sem permissão. Propagar o status code do caller:
```dart
// caller.dart
class SolicitacaoAcessoErro {
  final int? statusCode;
  final String mensagem;
  SolicitacaoAcessoErro(this.statusCode, this.mensagem);
}

static Future<SolicitacaoAcessoErro?> aprovar(int id) async {
  try {
    final response = await http.post(...);
    if (response.statusCode == 200) return null;
    return SolicitacaoAcessoErro(response.statusCode, _extrairMensagemErro(response.body));
  } catch (_) {
    return SolicitacaoAcessoErro(null, 'Erro de conexão ao aprovar solicitação.');
  }
}

// tela
if (erro.statusCode == 404) {
  _carregar(); // já processada / removida — recarrega de forma confiável
}
```
Isso elimina a dependência de string e cobre o caso real (404 = não encontrada, conforme o controller já documenta).

### WR-02: `_mascarar` retorna o documento sem máscara quando o tamanho não é 11 nem 14 dígitos — não é index-out-of-bounds, mas é vazamento de dado não tratado

**Arquivo:** `lib/widgets/solicitacao_acesso_aprovacao_screen.dart:267-276`

**Issue:** A função usa `digits.length == 11` / `== 14` como guarda antes de qualquer `substring`, então **não há crash/index-out-of-bounds** para documentos malformados (vazio, 9 dígitos, etc.) — esse risco foi descartado corretamente pela revisão de código. Porém o comportamento de fallback é `return doc;` — ou seja, se o backend enviar um CPF/CNPJ malformado (dado sujo, campo vazio, ou um valor com letras/formatação inesperada), **o documento é exibido SEM máscara nenhuma**, na tela que existe justamente para mascarar PII. Isso é uma falha silenciosa do propósito de mascaramento, não um crash, mas no contexto de uma tela cujo requisito é "mascarar CPF/CNPJ", o fallback inseguro (mostrar tudo) é o pior dos dois fallbacks possíveis.

**Fix:**
```dart
String _mascarar(String doc) {
  final digits = doc.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11) {
    return '${digits.substring(0, 3)}.***.**${digits.substring(8, 9)}-${digits.substring(9)}';
  }
  if (digits.length == 14) {
    return '${digits.substring(0, 2)}.***.***/****-${digits.substring(12)}';
  }
  if (digits.isEmpty) return '-';
  return '***'; // dado malformado: nunca exibir em claro
}
```

### WR-03: `listarPendentes()` engole silenciosamente qualquer erro de rede/parsing e retorna lista vazia — usuário não recebe feedback de falha, só vê "Nenhuma solicitação pendente"

**Arquivo:** `lib/services/solicitacao_acesso_caller.dart:39-54`

**Issue:** O `catch (_) { return []; }` no `listarPendentes` (e o `if (response.statusCode != 200) return [];`) faz com que qualquer falha — token expirado, 500 do backend, timeout de rede, JSON malformado — seja indistinguível de "não há solicitações pendentes" na UI (`_buildEstadoVazio()`, que mostra "Nenhuma solicitação pendente. Novas solicitações de acesso aparecerão aqui."). Isso é um falso negativo perigoso numa tela de aprovação: um operador pode achar que a fila está vazia quando, na verdade, houve uma falha de carregamento (ex.: sessão expirada), deixando solicitações pendentes sem revisão por tempo indeterminado.

**Fix:** Diferenciar "lista vazia real" de "falha ao carregar" propagando o erro (ou ao menos um booleano `sucesso`) para a tela mostrar um estado de erro com botão de retry, em vez de reaproveitar o estado vazio:
```dart
static Future<({List<SolicitacaoAcessoItem> itens, String? erro})> listarPendentesComStatus() async {
  try {
    final response = await http.get(...);
    if (response.statusCode != 200) {
      return (itens: <SolicitacaoAcessoItem>[], erro: 'Falha ao carregar (HTTP ${response.statusCode}).');
    }
    // ... parse
    return (itens: lista, erro: null);
  } catch (e) {
    return (itens: <SolicitacaoAcessoItem>[], erro: 'Erro de conexão ao carregar solicitações.');
  }
}
```

## Info

### IN-01: Item de menu "Solicitações de Acesso" sem gating de permissão — consistente com o padrão atual, não é regressão, mas é risco pré-existente que este commit herda e amplia

**Arquivo:** `lib/utils/menu_config.dart:333-337` (classe `MenuItem`, `lib/utils/menu_config.dart:4-16`)

**Issue:** Confirmado: `MenuItem` não tem nenhum campo de permissão/role (`id`, `label`, `icon`, `screenIndex` apenas). Nenhum outro item do menu, incluindo "Logins" (linha ~330, mesmo grupo Configurações), tem gating explícito nessa classe. Portanto **não é regressão introduzida por este commit** — é uma lacuna de arquitetura pré-existente em todo o `MenuConfig`. Vale registrar porque esta tela específica (aprovação de acesso, que cria logins novos) é mais sensível que a média dos itens de menu, e a falta de RBAC no nível de menu/rota significa que qualquer usuário autenticado com acesso ao layout Web/Windows enxerga e pode acionar aprovação/rejeição de acesso — a única barreira real de autorização está no backend (`SecurityException` → 403), o que é correto como defesa em profundidade, mas a ausência de uma camada de UI consistente é uma dívida arquitetural a considerar antes de mais módulos sensíveis adotarem o mesmo padrão.

**Fix (não bloqueante, sugestão de follow-up):** Avaliar introduzir um campo opcional `requiredPermission` em `MenuItem` numa fase futura dedicada a permissões de menu, em vez de resolver pontualmente neste commit.

### IN-02: `_executar` usa `setState` para mutar `_itens` via `removeWhere`, mas a lista pode ter sido alterada concorrentemente por uma chamada de `_carregar()` disparada por outro fluxo de erro — risco de condição de corrida de UI (não crítico, app single-thread de UI, mas vale nota)

**Arquivo:** `lib/widgets/solicitacao_acesso_aprovacao_screen.dart:78-110`

**Issue:** Em `_executar`, após uma falha que contém `'já foi processada'`, o código chama `_carregar()` **sem aguardar** (`await` ausente — é fire-and-forget, linha ~117: `_carregar();`). Se o usuário disparar uma segunda ação (aprovar/rejeitar outro item) enquanto esse `_carregar()` assíncrono ainda está em andamento, há uma janela onde `_itens` pode ser sobrescrita pelo `setState` de `_carregar` bem depois do `setState` de `_executar`, mas como ambos rodam na mesma thread de UI do Flutter (sem race real de memória), o pior cenário é apenas uma ordem de atualização de tela inesperada (ex.: item que acabou de ser removido reaparecer brevemente até o novo fetch completar) — não há corrupção de estado nem dois dialogs abertos simultaneamente (o `Set<int> _processando` é limpo corretamente em todos os caminhos, inclusive erro, então não há vazamento de estado de "processando" travado).

**Fix (cosmético):** Adicionar `await` no `_carregar()` dentro do bloco de erro de concorrência, para que a sequência de atualizações de tela seja determinística:
```dart
if (erro.contains('já foi processada')) {
  await _carregar();
}
```

---

_Reviewed: 2026-06-25_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
