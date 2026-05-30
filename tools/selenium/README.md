# Selenium AppAcademia

Os testes Selenium foram centralizados no harness da workspace:

```text
C:\App_Academia\.selenium-app-academia-e2e
```

Esta pasta do projeto Flutter mantem apenas:

- `selenium_web_app.dart`: target local usado pelo `flutter build web`;
- `run_selenium_tests.ps1`: atalho de compatibilidade para chamar o harness central.

## Rodar somente o projeto cliente

```powershell
cd C:\App_Academia\task_manager_flutter
.\tools\selenium\run_selenium_tests.ps1
```

## Rodar cliente e base

```powershell
cd C:\App_Academia
$env:APP_ACADEMIA_PROJECTS = "client,base"
python -m pytest .selenium-app-academia-e2e\tests
```

Artefatos, logs, screenshots, baselines e diffs ficam em:

```text
C:\App_Academia\.selenium-app-academia-e2e\artifacts
```
