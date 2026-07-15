# Erros do Playwright — task_manager_flutter (Web)

## 2026-07-14 — DWDS injected client.js: TypeError de deserialização

**Contexto:** `flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8090 --dart-define=BACKEND_URL=http://127.0.0.1:9001`, acessado via Playwright/Browser pane em `http://localhost:8090`.

**Erro (console do navegador):**
```
Unhandled error detected in the injected client.js script.
TypeError: Instance of '_JsonMap': type '_JsonMap' is not a subtype of type 'List<Object?>'
    at BuiltJsonSerializers._deserialize$3 (dwds/src/injected/client.js:20953:36)
    at Object._deserializeEvent (dwds/src/injected/client.js:9920:35)
    ...
```

**Causa provável:** erro de metadados/deserialização no serviço de debug do DWDS (Dart Web Debug Service, usado para hot-reload/DevTools), não no código da aplicação em si — ocorre na ponte de comunicação entre o Chrome DevTools Protocol e o VM Service, não em `main.dart`.

**Impacto:** o app pode continuar carregando normalmente apesar desse erro (é do canal de debug, não do runtime da aplicação); só desabilita hot-reload/DevTools nesse cenário. Se a tela realmente não carregar depois disso, é preciso investigar separadamente — não presumir que é a causa raiz de uma tela em branco sem confirmar.

**Ação tomada:** documentado aqui conforme instrução do CLAUDE.md; app testado seguir mesmo assim para verificar se a tela carrega apesar do erro.
