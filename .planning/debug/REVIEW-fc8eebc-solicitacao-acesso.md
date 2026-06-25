# REVIEW.md — Commit fc8eebc (solicitacao_acesso_screen.dart)

**Repo:** `C:\App_Academia\task_manager_flutter` (branch main)
**Commit revisado:** `fc8eebc`
**Arquivo:** `lib/auth_screens/solicitacao_acesso_screen.dart`
**Backend de referência:** `C:\App_Academia\AppAcademia` (DTO, Controller, Service, Response/ResponseError atuais no working tree)

---

## Resumo da verificação cruzada

| Item | Esperado (backend atual) | Encontrado no Flutter | OK? |
|---|---|---|---|
| Payload POST | `{nome, email, cpfCnpj, senha}` | `{nome, email, cpfCnpj, senha}` (linha 91-96) | Sim |
| Parsing de erro | `body['response']['message']` (Jackson serializa getters `data`/`response`, e dentro `error`/`message`/`status` minúsculos) | `body['response']['message']` (linha 116-117) | Sim |
| Status sucesso | 201 (`HttpStatus.CREATED`) | `response.statusCode == 201` | Sim |
| Status conflito | 409 (`IllegalStateException` → CONFLICT) | tratado com mensagem fixa de fallback (linha 111-113) | Sim |
| Status 400 | **Não existe no controller atual** (`criar()` só lança `IllegalStateException` → 409; não há `@Valid`/`MethodArgumentNotValidException` handler nem outro catch) | Mensagem fixa "CPF/CNPJ invalido" associada a 400 ainda presente (linha 110-113... ver achado HIGH-1) | Não — dead code |
| Validação de CPF/CNPJ | Backend só limpa dígitos e confere tamanho via `findByCpf` (sem dígito verificador) | Flutter também só confere 11/14 dígitos (`_validarCpfCnpj`), sem DV | Consistente (não é regressão) |
| Resíduos de controllers antigos | — | `_cpfCtrl`/`_cnpjCtrl` removidos, nenhum import morto encontrado | Sim |

---

## HIGH

### HIGH-1: Mensagem fixa de erro 400 é dead code — pode mascarar mensagem real do backend
**Linhas:** 110, 121-124

```dart
String mensagem = 'Erro ao enviar solicitação. Tente novamente.';
if (response.statusCode == 409) {
  mensagem = 'Já existe uma solicitação pendente para este email/CPF-CNPJ.';
}
...
if (response.statusCode != 400 && response.statusCode != 409) {
  debugPrint('[SolicitacaoAcessoScreen] erro inesperado statusCode=${response.statusCode} ...');
}
```

O `SolicitacaoAcessoController.criar()` atual **não tem nenhum caminho que retorne 400**. Os únicos retornos possíveis são 201 (sucesso) e 409 (`IllegalStateException`, duplicata). Qualquer outro erro (500 por exceção não tratada, erro de validação de bean se houver `@Valid` no futuro, timeout do proxy, etc.) cai no `else` genérico — mas o código trata 400 como um "caso conhecido e silencioso" (não loga, não é tratado como inesperado), quando na realidade **400 nunca deveria acontecer neste endpoint hoje**. Isso não é um bug funcional ativo (o app não quebra), mas é uma referência morta a um contrato antigo que não existe mais — se o backend evoluir para devolver 400 em outro cenário (ex: `@Valid` no DTO), o comportamento de log atual vai silenciar esse caso sem motivo, dificultando debug.

**Recomendação:** Remover a referência especial a 400, ou documentar explicitamente por que ela continua lá (ex: comentário "mantido por segurança até confirmar que 400 nunca ocorre"). Tratar qualquer status fora de {201, 409} como inesperado e logar.

---

## MEDIUM

### MEDIUM-1: Máscara de `_CpfCnpjInputFormatter` aplica formatação de CNPJ prematuramente com 12-14 dígitos incompletos (confusão visual)
**Linhas:** 530-556

```dart
final isCnpj = limited.length > 11;
```

Quando o usuário ultrapassa 11 dígitos (ex.: terminou de digitar um CPF de 11 dígitos mas por engano segue digitando, ou está no meio de digitar um CNPJ), a máscara muda IMEDIATAMENTE para o padrão CNPJ (`XX.XXX.XXX/XXXX-XX`) a partir do 12º dígito, mesmo que o CNPJ ainda esteja incompleto. Isso é esperado e correto para CNPJ real (14 dígitos), mas o ponto de transição (entre 11 e 14 dígitos) pode confundir o usuário: ao digitar o 12º dígito de um CPF errado (ex.: usuário digitou um dígito extra por engano), a tela já reformata tudo como CNPJ parcial, mudando os separadores (de `.` e `-` de CPF para `.`/`.`/`/`/`-` de CNPJ) no meio da digitação. Não é uma falha grave (a validação de tamanho final ainda impede submissão com 12-13 dígitos), mas é uma transição abrupta de UX que pode ser percebida como "bug" pelo usuário.

**Recomendação:** Considerar manter máscara de CPF até 11 dígitos completos e só mudar para CNPJ quando o usuário digitar o 12º dígito de forma consistente, ou adicionar um pequeno texto de ajuda dinâmico indicando "Digite mais X dígitos para CNPJ". Não bloqueante — comportamento aceitável para v1, mas vale revisão de UX.

### MEDIUM-2: Catch genérico `catch (_) {}` no parsing de erro suprime qualquer falha de parsing sem log
**Linhas:** 114-119

```dart
try {
  final body = jsonDecode(response.body) as Map<String, dynamic>;
  final msg = (body['response'] as Map<String, dynamic>?)?['message']?.toString();
  if (msg != null && msg.isNotEmpty) mensagem = msg;
} catch (_) {}
```

Se o backend devolver um body que não é JSON válido (ex.: erro 500 do Spring com página de erro HTML padrão, ou um proxy/load balancer interceptando a resposta), o `catch (_) {}` silencia completamente a falha de parsing sem nenhum log. Isso dificulta diagnosticar problemas de integração em produção (ex.: se o WAF ou Railway devolver um body diferente do esperado). Mensagem genérica final ainda é exibida ao usuário, então não é uma falha visível, mas é uma faixa cega para observabilidade.

**Recomendação:** Adicionar `debugPrint` dentro do catch para registrar a falha de parsing, similar ao que já é feito no catch externo (linha 130).

---

## LOW

### LOW-1: `_validarCpfCnpj` não distingue CPF de CNPJ para fins de mensagem de erro mais específica
**Linhas:** 51-58

A validação aceita genericamente 11 ou 14 dígitos e dispara a mesma mensagem para ambos os casos. Isso é coerente com o backend (que também não valida dígito verificador), mas para um campo que move dois domínios diferentes (CPF pessoal vs CNPJ empresa, agora unificados), a mensagem de erro "Informe um CPF (11 dígitos) ou CNPJ (14 dígitos) válido" pode ficar pouco clara se o usuário digitar, por exemplo, 12 ou 13 dígitos — não fica claro qual dos dois ele estava tentando preencher. Não bloqueante.

### LOW-2: Falta de teste/validação automatizada para o novo payload e parsing de erro
Não há testes de widget ou unitários cobrindo `_enviar()`, o payload enviado, ou o parsing do novo formato `Response`/`ResponseError`. Dado que este é exatamente o tipo de mudança de contrato que já quebrou silenciosamente uma vez (formato antigo vs novo), a ausência de teste de regressão é um risco para a próxima mudança de contrato do backend. Recomendação: ao menos um teste unitário puro para `_apenasDigitos`/`_validarCpfCnpj`/`_CpfCnpjInputFormatter`, e idealmente um teste de integração mockando `http.Client` para validar o payload exato enviado.

---

## Itens confirmados como corretos (sem achado)

1. **Payload exato** bate 100% com `SolicitacaoAcessoRequestDTO` (`nome`, `email`, `cpfCnpj`, `senha`) — sem campos extras, sem campos faltando.
2. **Estrutura de erro** bate com a serialização Jackson real de `Response`/`ResponseError`: ambas as classes usam getters Java Bean padrão (`getData()`, `getResponse()`, `getError()`, `getMessage()`, `getStatus()`), sem anotações `@JsonProperty` customizadas, portanto Jackson serializa como `{"data": ..., "response": {"error": bool, "message": "...", "status": int}}` — exatamente o que o Flutter espera em `body['response']['message']`.
3. **Código HTTP 201/409**: confirmado no `SolicitacaoAcessoController.criar()` — não existem outros `catch` blocks nesse método além de `IllegalStateException`→409. Tratamento do Flutter está alinhado (ver HIGH-1 para a ressalva sobre 400 morto).
4. **Falta de validação de dígito verificador**: confirmado que `SolicitacaoAcessoServiceImpl.resolverParceiro()` e `criar()` apenas limpam dígitos (`replaceAll("\\D","")`) e conferem por `findByCpf` (igualdade exata de string) — não há validação de DV em nenhum lugar do backend. O Flutter está consistente com esse nível de validação (não é regressão introduzida pelo commit).
5. **Limpeza de código**: nenhum import morto, nenhuma variável `_cpfCtrl`/`_cnpjCtrl` residual, nenhum controller duplicado. `dispose()` (linha 35-42) lista corretamente todos os 5 controllers atuais (`_nomeCtrl`, `_emailCtrl`, `_senhaCtrl`, `_confirmarSenhaCtrl`, `_cpfCnpjCtrl`).
6. **Mascara aplicada apenas para exibição**: o payload enviado usa `_apenasDigitos(_cpfCnpjCtrl.text)` (linha 94), então a formatação visual (pontos/barra/hífen) não contamina o valor enviado ao backend — correto.

---

_Revisado em 2026-06-25._
_Revisor: Claude (gsd-code-reviewer)._
