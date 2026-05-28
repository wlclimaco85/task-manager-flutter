# Selenium para as telas Flutter Web

Esta pasta sobe o `task_manager_flutter` como Flutter Web e executa testes Selenium em navegador real.

## Rodar tudo

```powershell
.\tools\selenium\run_selenium_tests.ps1
```

Por padrao o script:

- cria um `.venv` local em `tools/selenium/.venv`;
- instala `pytest` e `selenium`;
- usa o target `tools/selenium/selenium_web_app.dart`, que abre a shell web ja autenticada com um usuario local de teste;
- gera `flutter build web` para esse target;
- serve `build/web` em HTTP local na porta `5200`;
- executa os testes em Chrome headless.

## Opcoes uteis

```powershell
.\tools\selenium\run_selenium_tests.ps1 -Headed
.\tools\selenium\run_selenium_tests.ps1 -Browser edge
.\tools\selenium\run_selenium_tests.ps1 -Port 5300
.\tools\selenium\run_selenium_tests.ps1 -BaseUrl http://127.0.0.1:5200
```

## Rodar todas as telas do menu

```powershell
.\tools\selenium\run_selenium_tests.ps1 -AllScreens
```

Esse modo le automaticamente os `MenuItem` de `lib/utils/menu_config.dart`, abre cada indice navegavel com `?screen=...` e valida que a tela renderiza conteudo visual. Ele demora mais que o smoke test porque percorre todos os itens navegaveis do menu.

Para uma rodada parcial durante desenvolvimento:

```powershell
$env:SELENIUM_ALL_SCREENS_LIMIT = "10"
.\tools\selenium\run_selenium_tests.ps1 -AllScreens
```

Para apontar para outro Flutter:

```powershell
$env:FLUTTER_BIN = "C:\caminho\para\flutter.bat"
.\tools\selenium\run_selenium_tests.ps1
```

Para forcar um renderer em versoes antigas do Flutter que ainda aceitam a flag:

```powershell
$env:SELENIUM_WEB_RENDERER = "html"
.\tools\selenium\run_selenium_tests.ps1
```

Para testar o app real com `lib/main_web.dart`, suba o app em outra janela e informe a URL:

```powershell
flutter run -d chrome --web-hostname 127.0.0.1 --web-port 5201 -t lib/main_web.dart
$env:SELENIUM_LOGIN_BASE_URL = "http://127.0.0.1:5201"
.\tools\selenium\run_selenium_tests.ps1 -BaseUrl http://127.0.0.1:5200
```

Screenshots e logs ficam em `tools/selenium/.artifacts`.
