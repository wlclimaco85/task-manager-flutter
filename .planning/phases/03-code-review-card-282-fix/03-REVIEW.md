---
phase: 03-code-review-card-282-fix
reviewed: 2026-08-07T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - lib/web/screens/pedido_venda_grid_screen.dart
  - lib/windows/screens/pedido_venda_grid_screen.dart
findings:
  critical: 1
  warning: 4
  info: 2
  total: 7
status: issues_found
---

# Code Review Report — Commit 44ed1b32 (remediação Card 282)

**Reviewed:** 2026-08-07
**Depth:** standard (diff-focused, com leitura completa dos 2 arquivos alterados para contexto)
**Commit:** `44ed1b321ba45f8efa8803699e90acf9ecae8f6b`
**Files Reviewed:** 2
**Status:** issues_found

## Nota metodológica

O arquivo `.planning/phases/02-code-review-card-282/02-REVIEW.md` referenciado pela tarefa **não existe** neste worktree (confirmado via `find`/`glob` — diretório `02-code-review-card-282` nunca foi criado ou não foi commitado). Reconstruí os 7 achados originais (CR-01, CR-02, CR-03, WR-01..04) a partir de duas fontes primárias e cruzadas:
1. `scripts/card_282_qa_to_backlog_blocker.py` — contém o texto literal do comentário de blocker postado no Trello (`comment_id 6a74e9ef5a668e8c6adcdf20`), com arquivo/linha de cada CR.
2. `.agents/memory/appacademia-trello-operational-log.md` (linha 49/52) — confirma a mesma descrição.
3. A própria mensagem do commit `44ed1b32`, que declara explicitamente o que cada item deveria corrigir.

Isso é suficiente para validar a remediação com precisão de arquivo/linha, mas registro como achado de processo (IN-02 abaixo) o fato do artefato `02-REVIEW.md` não existir no worktree onde o fix foi commitado.

## Resumo

O commit remedia corretamente 5 dos 7 achados (CR-01, CR-02, WR-01, WR-02, e metade de WR-03/CR-03/WR-04). Porém a correção de **CR-03 (stack trace exposto ao usuário) é incompleta**: o mesmo padrão de vulnerabilidade que foi corrigido em 3 pontos do arquivo web e em `_showConfirm` do arquivo windows continua presente, sem qualquer alteração, em `_showFaturarDialog` do arquivo **windows** — no mesmo arquivo que este commit já tocou para remediar o findings idêntico algumas linhas abaixo. Isso é inconsistente: o dev claramente sabia do padrão (`GridTexts.actionFailure(title)` sem `$e`) e aplicou em um lugar mas não no outro método do mesmo arquivo. Também identifiquei que WR-03 (catch bare silencioso) só foi corrigido no arquivo web; a função gêmea duplicada no arquivo windows mantém `catch (_) {}` sem log.

## Critical Issues

### CR-01: CR-03 (stack trace exposto) não foi totalmente remediado — persiste em `_showFaturarDialog` (windows)

**File:** `lib/windows/screens/pedido_venda_grid_screen.dart:212-219`
**Issue:** O achado original CR-03 apontava exposição de stack trace/mensagem de exceção ao usuário final em SnackBars (Web L128/161 e Windows). O commit corrigiu isso em `_showConfirm` do arquivo windows (removeu `'$title: $e'`, ver diff em `lib/windows/screens/pedido_venda_grid_screen.dart` linha ~181-189) e em 3 pontos do arquivo web. Mas o método `_showFaturarDialog`, no **mesmo arquivo windows**, não foi tocado e continua expondo a mensagem de exceção bruta diretamente na UI:
```dart
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Erro ao faturar parcialmente: $e'),   // linha 215 — mesma vulnerabilidade do CR-03
      backgroundColor: GridColors.error,
    ),
  );
}
```
Este é exatamente o padrão que o próprio commit corrigiu duas dezenas de linhas acima, no `_showConfirm`. Confirmado via `git show 44ed1b32~1` que este trecho já existia antes e não foi alterado por este commit — não é regressão nova, mas é remediação incompleta de um achado CRITICAL declarado como resolvido na mensagem do commit ("CR-03/WR-04: mensagens de erro não expõem mais stack trace ao usuário"). Essa afirmação é falsa para este método.
Além disso, o bloco falta `if (!context.mounted) return;` antes de usar `ScaffoldMessenger.of(context)` — o mesmo tipo de proteção adicionada em outros pontos deste commit (CR-02) não foi replicada aqui.
**Fix:**
```dart
void _showFaturarDialog(BuildContext context, PedidoVenda pedido) {
  if (pedido.id == null) return;
  final itens = pedido.itens?.map((i) => i.toJson()).toList() ?? [];
  try {
    showDialog(
      context: context,
      builder: (_) => FaturarDialog(
        pedidoId: pedido.id!,
        itens: itens,
        onSaved: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(GridTexts.completedAction('Faturamento')),
              backgroundColor: GridColors.success,
            ),
          );
        },
      ),
    );
  } catch (e) {
    debugPrint('Falha ao abrir faturamento parcial: $e');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(GridTexts.actionFailure('Faturar Parcial')),
        backgroundColor: GridColors.error,
      ),
    );
  }
}
```
Isso espelha exatamente a correção já aplicada em `_showFaturarParcial` (web, linhas 85-97).

## Warnings

### WR-01: WR-03 (catch bare silencioso) corrigido só no web; duplicata em windows continua sem log

**File:** `lib/windows/screens/pedido_venda_grid_screen.dart:130-143`
**Issue:** `_fetchOrcamentosAprovados` existe de forma quase idêntica em ambos os arquivos (mais um sintoma da duplicação ~95% já registrada em achados de QA anteriores). O commit adicionou `debugPrint` ao `catch` do arquivo web (linha 131-133), mas a versão windows continua:
```dart
} catch (_) {}
return [];
```
Erros de rede seguem sendo engolidos silenciosamente nesta tela, dificultando debug de produção.
**Fix:**
```dart
} catch (e) {
  debugPrint('Falha ao buscar orcamentos aprovados: $e');
}
return [];
```

### WR-02: Duas classes `GridColors` com valores divergentes coexistem no projeto

**File:** `lib/web/screens/pedido_venda_grid_screen.dart:6` (import trocado para `utils/grid_colors.dart`)
**Issue:** A mensagem do commit descreve o IN-01 como "mesmos valores, remove import duplicado", mas isso não é verdade em geral: `lib/constants/custom_colors.dart` e `lib/utils/grid_colors.dart` definem duas classes `GridColors` com o mesmo nome e valores divergentes em `link` (`0xFFFF0000` vs `0xFF93070A`), `hover` (`0x1A000000` vs `0x1A93070A`), `shadow` (`0x26000000` vs `0x2693070A`), e a classe derivada `CustomColors` diverge fortemente em `_darkBlue` (`GridColors.background` claro vs `GridColors.shellBackground` vermelho escuro) e `_textColorDesc`. Para esta tela específica não há impacto visual, pois só são usados `primary/secondary/error/success/warning/info`, que são idênticos nos dois arquivos — então a troca de import em si é segura aqui. Mas a alegação de equivalência total é incorreta e o projeto mantém duas fontes de verdade para a mesma paleta de cores, risco real para qualquer edição futura que use um campo divergente.
**Fix:** Abrir tarefa de consolidação: eliminar `constants/custom_colors.dart` como definidor de cores (fazer `CustomColors` reexportar de `utils/grid_colors.dart` sem redefinir `GridColors`), ou documentar explicitamente por que os dois arquivos existem e quais campos são intencionalmente diferentes.

### WR-03: Replicação para `task_manager_flutter_merged_final` não realizada

**File:** N/A (regra de projeto, `CLAUDE.md`)
**Issue:** CLAUDE.md exige que toda alteração em `task_manager_flutter` seja avaliada para replicação em `task_manager_flutter_merged_final` (exceto branding/tema — não é o caso aqui, pois os fixes são lógica de estado/erro, não cor de UI). Não há evidência de que os mesmos 2 arquivos em `task_manager_flutter_merged_final` tenham recebido os mesmos fixes (commit `44ed1b32` só toca `task_manager_flutter`).
**Fix:** Aplicar o mesmo diff (adaptando imports/paths) em `task_manager_flutter_merged_final/lib/web/screens/pedido_venda_grid_screen.dart` e `.../windows/screens/pedido_venda_grid_screen.dart` antes do merge para `desenv`.

### WR-04: Botões "Cancelar" e "Histórico" seguem sem `GatedButton` (gating de status)

**File:** `lib/web/screens/pedido_venda_grid_screen.dart:395-396`
**Issue:** Achado de QA anterior (log operacional, 2026-08-06) apontava "botão Cancelar sem gating de status" como problema pendente na tela. Esse item não estava nos 7 achados remediados por este commit (fora do escopo declarado), mas continua presente sem alteração: `_actionIcon(Icons.block, 'Cancelar', ...)` e `_actionIcon(Icons.history, 'Histórico', ...)` não são envolvidos por `GatedButton`, ao contrário de Editar/Aprovar/Rejeitar/Faturar. Um pedido `CANCELADO` ou `FATURADO_TOTAL` ainda exibe o botão "Cancelar" ativo na UI.
**Fix:** Fora do escopo deste commit — registrar como card/achado separado para não bloquear esta remediação específica, mas sinalizar ao QA que este item segue pendente.

## Info

### IN-01: Artefato `02-REVIEW.md` referenciado não existe no worktree

**File:** `.planning/phases/02-code-review-card-282/02-REVIEW.md` (ausente)
**Issue:** A tarefa de review cita este arquivo como fonte dos 7 achados originais, mas ele nunca foi criado/commitado neste worktree. A reconstrução foi feita via Trello (script `card_282_qa_to_backlog_blocker.py`) e log operacional, o que é suficiente para este review, mas quebra a rastreabilidade esperada do processo GSD.
**Fix:** Gerar/commitar o `02-REVIEW.md` retroativamente (ou linkar o card Trello + comment_id como referência oficial) para manter o histórico completo do card 282.

### IN-02: `_openPedidoById` duplica lookup O(n) que já existia implicitamente

**File:** `lib/web/screens/pedido_venda_grid_screen.dart:349-354`
**Issue:** Não é bug (fora de escopo de performance), mas nota de manutenção: `_findPedidoById` percorre `_pedidos` linearmente a cada clique em "Visualizar"/"Editar". Aceitável para o volume esperado da tela, apenas registrando para não ser confundido com um achado de performance intencional.
**Fix:** Nenhuma ação necessária agora; considerar `Map<int, ...>` apenas se a lista crescer para milhares de itens.

## Validação Executada

- `flutter analyze lib/web/screens/pedido_venda_grid_screen.dart lib/windows/screens/pedido_venda_grid_screen.dart` → **No issues found!** (8.0s)
- Comparação linha a linha do diff `44ed1b32~1..44ed1b32` para os 2 arquivos em escopo.
- Confirmação via `git show 44ed1b32~1:...` de que `_showFaturarDialog` (windows) e `catch (_) {}` (windows `_fetchOrcamentosAprovados`) já existiam antes do commit e não foram alterados — não são regressões novas, são remediação incompleta dos achados declarados como corrigidos.

## Veredito Final

**REPROVADO** — não pronto para retornar a QA/merge em `desenv`.

Achados que bloqueiam o merge:
- **CRITICAL (1)**: CR-03 permanece parcialmente presente em `lib/windows/screens/pedido_venda_grid_screen.dart:215` (`_showFaturarDialog` expõe `$e` cru ao usuário) — o mesmo achado que o commit afirma ter resolvido ("mensagens de erro não expõem mais stack trace ao usuário") continua falso para este método.

Recomendação: aplicar o fix de CR-01 (deste review) em `_showFaturarDialog`, reavaliar WR-01 (bare catch windows) e WR-03 (replicação merged_final) antes de nova tentativa de code review/QA. Os demais 5 achados originais (CR-01, CR-02, WR-01, WR-02, e a metade web de WR-03/WR-04) estão corretamente remediados e podem ser considerados fechados.

---

_Reviewed: 2026-08-07_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
