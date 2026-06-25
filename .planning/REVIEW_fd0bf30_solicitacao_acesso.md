---
commit: fd0bf30ff6c3422d53a09323ce942d6fb45026b9
repo: C:\App_Academia\task_manager_flutter
branch: main
reviewed: 2026-06-25
depth: standard
files_reviewed: 3
files_reviewed_list:
  - lib/auth_screens/solicitacao_acesso_screen.dart
  - lib/auth_screens/login_screen.dart
  - lib/utils/api_links.dart
findings:
  critical: 0
  high: 1
  medium: 3
  low: 4
  total: 8
status: issues_found
---

# Revisao do commit fd0bf30 — Tela "Solicitar Acesso"

**Revisado:** 2026-06-25
**Repo:** `C:\App_Academia\task_manager_flutter` (branch `main`)
**Arquivos:** `lib/auth_screens/solicitacao_acesso_screen.dart` (novo, 580 linhas), `lib/auth_screens/login_screen.dart` (so navegacao), `lib/utils/api_links.dart` (4 endpoints novos)

## Resumo

A tela substitui corretamente o `SignUpFormScreen` quebrado. Fluxo de envio (`_enviar()`), tratamento de erro 400/timeout/conexao e dispose dos controllers estao corretos na essencia. Nao ha log de senha em nenhum ponto (nenhum `print`/`debugPrint` no arquivo). A validacao de CPF/CNPJ por tamanho (11/14 digitos) **bate com o contrato real do backend** (`SolicitacaoAcessoServiceImpl.criar()` aceita ambos os tamanhos no mesmo campo `cnpj`), portanto nao e gap de validacao — e comportamento correto e intencional. Os achados abaixo sao de consistencia visual, robustez de erro de rede e dois pontos de codigo morto/nao utilizado.

## High

### H-01: Paleta nao e 100% `GridColors` como afirmado no commit — uso extensivo de `Colors.white*` no painel split (web/windows)

**Arquivo:** `lib/auth_screens/solicitacao_acesso_screen.dart:353,372,405,417,475,477,493`
**Issue:** A mensagem do commit diz "Paleta 100% GridColors, nenhuma cor nova" e o prompt de revisao cita `Colors.orange` (erro) como unica excecao aceita por ja ser padrao do `login_screen.dart`. No entanto a tela usa `Colors.white`, `Colors.white60`, `Colors.white70`, `Colors.white38`, `Colors.white54` e `Colors.white.withValues(alpha: 0.1)` repetidamente como cor de texto/icone/fundo quando `lightInputs == false` (variante escura usada no painel split web/windows, linha 475 e ramificacoes em `_field()`/suffix icons/botao "Voltar para o login"). Isso e uma inconsistencia real entre o que foi declarado e o que foi implementado: ou (a) deveriam existir tokens equivalentes em `GridColors` (ex.: `GridColors.textOnDark`, `GridColors.inputBackgroundDark`) e o codigo deveria usa-los, ou (b) o commit deveria deixar claro que ha uma segunda excecao alem do `Colors.orange`.
**Fix:** Adicionar tokens dedicados em `GridColors` (ex.: `onDarkPrimary`, `onDarkMuted`, `onDarkBorder`, `darkInputFill`) e substituir todas as ocorrencias de `Colors.white*` por esses tokens, mantendo a regra "nenhuma cor hex literal fora de `grid_colors.dart`" valida de fato.

## Medium

### M-01: `_buildCompact` sempre usa `lightInputs: false`, mas mobile puro tambem deveria revisar se o contraste de fundo bate com o tema claro do `Scaffold`

**Arquivo:** `lib/auth_screens/solicitacao_acesso_screen.dart:153-163`
**Issue:** `Scaffold.backgroundColor` e `GridColors.secondary` (cor escura, usada tambem como fundo do painel lateral do split). No layout compacto (`_buildCompact`), o card e centralizado sobre esse fundo escuro e usa `lightInputs: false` (mesma variante "dark" do painel lateral do split), entao os campos usam `Colors.white60/70/38/54` sobre `Colors.white.withValues(alpha: 0.1)`. Isso e consistente internamente, mas amplifica o problema do H-01: em mobile, 100% dos textos de label/hint/icone do formulario inteiro vem de `Colors.*` em vez de `GridColors.*`. Nao e so um detalhe do split-screen — e o caminho mais usado (mobile e a plataforma principal do app).
**Fix:** Mesma acao do H-01. Como a maior parte dos usuarios estara em mobile (`isCompact == true` quase sempre quando nao e web/windows), essa nao-conformidade afeta a maioria dos acessos a tela, nao um caso de borda.

### M-02: Erro de rede generico (`catch (_)`) engole qualquer exececao, incluindo bugs de parsing/codigo, sob a mesma mensagem "Sem conexao com o servidor"

**Arquivo:** `lib/auth_screens/solicitacao_acesso_screen.dart:177-184`
**Issue:** O catch-all `catch (_) { ... _erroServidor = GridTexts.loginNoConnection; }` captura `TimeoutException` (correto), `SocketException`/erro de conexao (correto), mas tambem qualquer exececao inesperada dentro do try (ex.: `FormatException` no `jsonEncode`, erro de tipo, exececao do proprio Flutter). O usuario sempre ve "Sem conexao com o servidor" mesmo quando o problema e outro (ex.: backend retornando um corpo nao-JSON em um 500, ja que so 400 e tratado explicitamente — ver M-03). Isso dificulta diagnostico em produção porque a mensagem de erro mascara a causa real, e não há nenhum log (nem mesmo via logger de debug) do erro original em modo debug.
**Fix:** Diferenciar ao menos `TimeoutException`/`SocketException`/`http.ClientException` (mensagem de conexao) de outras exececoes (mensagem generica "Erro inesperado, tente novamente" + log via `debugPrint('[SolicitacaoAcesso] erro: $e')` em modo debug apenas, sem incluir dados sensiveis como senha).

### M-03: Respostas de erro com status diferente de 400/201 (ex.: 500, 404, 503) caem na mensagem padrao sem diferenciar do 400, e o corpo nunca e logado para diagnostico

**Arquivo:** `lib/auth_screens/solicitacao_acesso_screen.dart:131-145`
**Issue:** Apenas `response.statusCode == 201` (sucesso) e `== 400` (erro de validacao, com parsing do JSON) sao tratados explicitamente. Qualquer outro codigo (500 do backend, 502/503 de proxy, 404 se a rota mudar) cai direto na mensagem padrao `'Erro ao enviar solicitação. Tente novamente.'`, sem tentar parsear o corpo (que pode conter informacao util) e sem nenhum log do `response.statusCode`/`response.body` para troubleshooting. Funcionalmente nao quebra a UI (o branch `setState` final sempre executa), mas reduz a capacidade de diagnostico em caso de erro real de servidor.
**Fix:** Logar (debug-only) `statusCode` e os primeiros N caracteres do `body` quando o status nao for 201/400, e opcionalmente diferenciar mensagem para 5xx ("Servidor indisponivel, tente novamente em alguns minutos").

## Low

### L-01: Tres endpoints novos em `api_links.dart` (`solicitacaoAcessoPendentes`, `solicitacaoAcessoAprovar`, `solicitacaoAcessoRejeitar`) sao adicionados neste commit mas nao sao usados por nenhum codigo Flutter

**Arquivo:** `lib/utils/api_links.dart:50-55`
**Issue:** Os 3 endpoints existem no backend (`SolicitacaoAcessoController`) para fluxo de aprovacao/rejeicao por um admin/contador, mas nenhuma tela Flutter neste commit (nem em outro lugar do repo, confirmado via grep) os consome. Sao "codigo morto" do ponto de vista do cliente — definicoes sem uso, plausivelmente adicionadas em preparacao para uma tela futura de aprovacao que ainda nao existe.
**Fix:** Se a tela de aprovacao esta planejada para outro commit/fase, registrar isso explicitamente (ex.: comentario `// TODO: usado pela tela de aprovacao do contador, fase X`) para nao ser confundido com lixo de copy-paste em revisao futura. Se nao houver plano confirmado, considerar remover até que sejam de fato necessários.

### L-02: `_validarConfirmarSenha` so revalida quando o proprio campo "confirmar senha" muda; se o usuario edita a "Senha" depois de ja ter preenchido "Confirmar senha", o erro de incompatibilidade nao e re-validado automaticamente

**Arquivo:** `lib/auth_screens/solicitacao_acesso_screen.dart:64-67,348-365`
**Issue:** `AutovalidateMode.onUserInteraction` re-executa o validator do campo quando o PRoprio campo recebe interacao do usuario. Se o fluxo for: usuario digita senha "123456", digita confirmacao "123456" (valida, sem erro), depois volta e edita a senha para "654321" sem tocar no campo de confirmacao novamente — o erro "As senhas nao coincidem" so aparecera quando o usuario clicar em "Enviar Solicitacao" (`_formKey.currentState!.validate()` revalida todos os campos), nao em tempo real. Isso e aceitavel (nao bloqueia o envio, o `_formKey.currentState!.validate()` final pega o caso), mas a UX e inconsistente com o resto do formulario que se anuncia como "validacao inline".
**Fix:** Opcional — adicionar um `_senhaCtrl.addListener` no `initState` que chama `_formKey.currentState?.validate()` (ou apenas revalida o campo de confirmacao) quando a senha mudar e o campo de confirmacao ja tiver conteudo. Severidade baixa porque o `_formKey.currentState!.validate()` no submit garante que o backend nunca recebe senha/confirmacao divergentes — é so um gap de feedback imediato.

### L-03: `_SafeLogoWidget` definido como classe privada de topo de arquivo (boa pratica), porem duplicada conceitualmente em relacao a um possivel widget equivalente em `login_screen.dart` — nao foi confirmado reuso

**Arquivo:** `lib/auth_screens/solicitacao_acesso_screen.dart:521-541`
**Issue:** Nao foi possivel confirmar nesta revisao (fora do escopo de arquivos do commit) se `login_screen.dart` ja possui um widget equivalente para exibir o logo com fallback gracioso. Se existir, ha duplicacao de codigo entre as duas telas de autenticacao.
**Fix:** Verificar se `login_screen.dart` tem widget de logo equivalente; se sim, extrair para um widget compartilhado em `lib/widgets/` (o proprio CLAUDE.md do projeto recomenda reutilizar `lib/widgets/` quando fizer sentido).

### L-04: `helperText`/`helperStyle` do CNPJ ficam vazios (`null`) para os demais campos, criando leve inconsistencia de altura do `TextFormField` entre campos com e sem helper

**Arquivo:** `lib/auth_screens/solicitacao_acesso_screen.dart:300-307` (na decoracao em `_field`)
**Issue:** Apenas o campo CNPJ recebe `helperText`. Isso e uma escolha de design plausivel (CNPJ realmente precisa de explicacao adicional), mas resulta em alturas de campo levemente diferentes entre os campos do formulario (com/sem linha de helper), o que pode causar a impressao de desalinhamento vertical sutil dependendo da plataforma/DPI. Achado puramente cosmético, registrado para visibilidade, sem necessidade de fix obrigatório.
**Fix:** Opcional — usar `helperText: ' '` (espaco) nos demais campos para reservar a mesma altura, se o efeito visual for perceptivel na pratica.

## Pontos verificados e considerados OK (sem achado)

- **Seguranca de senha:** nenhum `print`/`debugPrint`/log do valor de `_senhaCtrl.text` em todo o arquivo. `dispose()` chama `.dispose()` em todos os 6 controllers, incluindo `_senhaCtrl` e `_confirmarSenhaCtrl`. Envio via `jsonEncode` no corpo da requisicao HTTPS, nunca em query string/log.
- **Validacao de CPF/CNPJ por tamanho (sem digito verificador):** confirmado como aceitavel — o backend (`SolicitacaoAcessoServiceImpl.criar()`, `AppAcademia` repo) so valida `cnpjLimpo.length() != 11 && != 14`, ou seja, o contrato real da API e exatamente esse, nao ha gap de validacao a registrar como divida tecnica nesta fase.
- **Tratamento do branch 400:** o parsing do corpo (`jsonDecode(response.body) as Map<String,dynamic>`) esta protegido por `try/catch (_) {}` silencioso, o que evita crash se o backend mudar o formato do corpo de erro — comportamento correto, ainda que o catch silencioso normalmente seria penalizado, aqui o fallback (`mensagem` ja inicializada com texto generico) cobre o caso.
- **Estado de loading nunca preso:** todo caminho (sucesso, erro 400, erro generico, exececao) termina em um `setState(() => _enviando = false)` (exceto o caminho de sucesso que tambem zera `_enviando`), portanto o botao nunca fica preso em estado de loading indefinidamente. `mounted` e checado antes de cada `setState` apos o `await`.
- **Regressao do `SignUpFormScreen` removido:** grep confirmado em todo o repositorio — a unica referencia restante a `SignUpFormScreen`/`signup_form_screen` esta em `.lh/` (pasta de historico local do editor, nao e codigo-fonte rastreado/compilado). Nenhum import morto, nenhuma rota antiga referenciando o arquivo removido.
- **Convencao de nomes:** variaveis e metodos em portugues (`_enviar`, `_validarCpf`, `_apenasDigitos`, `_erroServidor`), consistente com o padrao do projeto.
- **`const` correctness:** uso correto de `const` em widgets estaticos (`Text`, `SizedBox`, `Icon` sem dependencia de estado); widgets que dependem de `lightInputs`/estado nao sao `const`, corretamente.

---

_Revisado: 2026-06-25_
_Revisor: Claude (gsd-code-reviewer)_
_Profundidade: standard_
