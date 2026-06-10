@echo off
setlocal enabledelayedexpansion
title Hub Apps - Menu Unico
color 0B

set "APP_ROOT=C:\App_Academia"
set "BACKEND_DIR=%APP_ROOT%\AppAcademia"
set "FLUTTER_DIR=%APP_ROOT%\task_manager_flutter"
set "FLUTTER_CLIENT_DIR=%APP_ROOT%\task_manager_flutter"
set "FLUTTER_BASE_DIR=%APP_ROOT%\task_manager_flutter_merged_final"
set "FLUTTER_V003_DIR=%APP_ROOT%\task_manager_AppAcademiaV003"
set "FLUTTER_DANIEL_DIR=%APP_ROOT%\task_manager_appDaniel"
set "SELENIUM_DIR=%APP_ROOT%\.selenium-app-academia-e2e"
set "DESKTOP=%USERPROFILE%\Desktop"
set "ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
set "JAVA_HOME=C:\Program Files\Java\jdk-17"
set "PATH=%JAVA_HOME%\bin;C:\flutter\bin;%PATH%"
set "GRADLE_USER_HOME=%USERPROFILE%\.gradle"
set "JWT_SECRET=Fay2t4wrmmRaYYzxPACdwA/O3w+co8MwuGw/3XfPRWU="
set "ACCOUNT_SECRET=Zm9vYmFyYmF6cXV4eW9sby1rZXktMTIzNDU2Nzg="
set "BACKEND_PORT=9001"
set "DEPLOY_BACKEND_URL=https://appacademia-production-be7e.up.railway.app"
set "BACKEND_URL=http://127.0.0.1:9001"
set "HOST_IP=127.0.0.1"
set "ANDROID_BACKEND_URL=http://127.0.0.1:9001"
set "ANDROID_WS_BACKEND_URL=ws://127.0.0.1:9001/boletobancos"
set "APP_PACKAGE_ABRACO=br.com.abracocontabilidade.app"
set "APP_PACKAGE_PORTAL=br.com.portalcont.app"
set "APP_PACKAGE_MEU_TREINO=com.washingtonclimaco.task_manager_appacademia"
set "APP_PACKAGE_SAFRA=br.com.safradireto.app"

rem Temp curto para o backend: o pipe NIO do Tomcat (Unix Domain Socket) falha
rem com "Unable to establish loopback connection" usando o temp do perfil do usuario.
if not exist "C:\Temp" mkdir "C:\Temp" >nul 2>&1
set "TMP=C:\Temp"
set "TEMP=C:\Temp"

call :DETECT_HOST_IP

:MENU
cls
echo ============================================
echo  Hub Apps - Menu Unico
echo ============================================
echo.
echo  [1] Subir backend + Abraco Contabilidade (Chrome)
echo  [2] Reiniciar backend + Abraco (matar e subir)
echo  [3] Rodar testes Selenium
echo  [4] Rodar testes Flutter HTTP
echo  [5] Rodar todos os testes
echo  [6] Build Android APK Abraco Contabilidade
echo  [7] Build + instalar Meu Treino e Safra Direto no BlueStacks (local)
echo  [8] Rodar tudo (backend + 2 Chrome + BlueStacks)
echo  [9] Matar backend + Flutter
echo  [A] Subir backend + Abraco + Portal (ambos Chrome)
echo  [B] Testar backend para BlueStacks
echo  [C] Subir um Flutter especifico no Chrome
echo  [D] Subir um Flutter especifico no Android/simulador
echo  [E] Subir tudo: backend + 2 Chrome + Meu Treino/Safra no BlueStacks
echo  [F] Build 4 APKs com backend deployado + instalar no BlueStacks
echo  [G] Build Android APK de um projeto (backend local)
echo  [H] Atualizar todos os repositorios (git pull)
echo  [P] Build APK unico com backend deployado
echo  [0] Sair
echo.
set "OP="
set /p "OP=Escolha: "

if /i "%OP%"=="0" exit /b 0
if /i "%OP%"=="1" (
    call :START_APP 0
    goto END_MENU
)
if /i "%OP%"=="2" (
    call :START_APP 1
    goto END_MENU
)
if /i "%OP%"=="3" (
    call :RUN_TESTS selenium
    goto END_MENU
)
if /i "%OP%"=="4" (
    call :RUN_TESTS flutter
    goto END_MENU
)
if /i "%OP%"=="5" (
    call :RUN_TESTS all
    goto END_MENU
)
if /i "%OP%"=="6" (
    call :BUILD_ANDROID
    goto END_MENU
)
if /i "%OP%"=="7" (
    call :BUILD_INSTALL_BLUESTACKS_APPS
    goto END_MENU
)
if /i "%OP%"=="8" (
    call :START_ALL_WITH_ANDROID
    goto END_MENU
)
if /i "%OP%"=="9" (
    call :KILL_APP
    goto END_MENU
)
if /i "%OP%"=="A" (
    call :START_ALL_FLUTTER_WEB 0
    goto END_MENU
)
if /i "%OP%"=="B" (
    call :TEST_BLUESTACKS_BACKEND
    goto END_MENU
)
if /i "%OP%"=="C" (
    call :START_ONE_FLUTTER_WEB
    goto END_MENU
)
if /i "%OP%"=="D" (
    call :START_ONE_FLUTTER_ANDROID
    goto END_MENU
)
if /i "%OP%"=="E" (
    call :START_ALL_WITH_ANDROID
    goto END_MENU
)
if /i "%OP%"=="F" (
    call :BUILD_ALL_APKS_DEPLOY
    goto END_MENU
)
if /i "%OP%"=="G" (
    call :BUILD_ONE_ANDROID_LOCAL
    goto END_MENU
)
if /i "%OP%"=="H" (
    call :GIT_PULL_ALL
    goto END_MENU
)
if /i "%OP%"=="P" (
    call :BUILD_ANDROID_DEPLOY
    goto END_MENU
)
goto MENU

:END_MENU
echo.
echo ============================================
echo  Finalizado.
echo ============================================
echo.
pause
goto MENU

:CHECK_PATHS
if not exist "%BACKEND_DIR%" (
    echo [ERRO] Pasta do backend nao encontrada: %BACKEND_DIR%
    exit /b 1
)
if not exist "%FLUTTER_DIR%" (
    echo [ERRO] Pasta do Flutter nao encontrada: %FLUTTER_DIR%
    exit /b 1
)
if not exist "%FLUTTER_BASE_DIR%" (
    echo [ERRO] Pasta do Flutter base nao encontrada: %FLUTTER_BASE_DIR%
    exit /b 1
)
if not exist "%FLUTTER_V003_DIR%" (
    echo [ERRO] Pasta do Flutter V003 nao encontrada: %FLUTTER_V003_DIR%
    exit /b 1
)
if not exist "%FLUTTER_DANIEL_DIR%" (
    echo [ERRO] Pasta do Flutter Daniel nao encontrada: %FLUTTER_DANIEL_DIR%
    exit /b 1
)
exit /b 0

:CHECK_SELENIUM
if not exist "%SELENIUM_DIR%\run_tests.bat" (
    echo [ERRO] Harness Selenium nao encontrado: %SELENIUM_DIR%
    exit /b 1
)
exit /b 0

:KILL_APP
echo.
echo Matando backend na porta %BACKEND_PORT%...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$procIds = Get-NetTCPConnection -LocalPort %BACKEND_PORT% -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique; foreach ($procId in $procIds) { if ($procId -and $procId -ne 0) { Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue; Write-Host ('  PID ' + $procId + ' encerrado') } }"

echo Matando processos Flutter/Dart ligados aos projetos...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$currentPid = $pid; $items = Get-CimInstance Win32_Process | Where-Object { $_.ProcessId -ne $currentPid -and ($_.Name -match 'flutter|dart|cmd') -and ($_.CommandLine -like '*task_manager_flutter*' -or $_.CommandLine -like '*task_manager_AppAcademiaV003*' -or $_.CommandLine -like '*task_manager_appDaniel*' -or $_.CommandLine -like '*AppAcademia*') }; foreach ($p in $items) { Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue; Write-Host ('  PID ' + $p.ProcessId + ' encerrado: ' + $p.Name) }"
timeout /t 2 /nobreak >nul
exit /b 0

:START_APP
call :CHECK_PATHS
if errorlevel 1 (
    echo [ERRO] CHECK_PATHS falhou - veja acima qual pasta nao existe.
    pause
    exit /b 1
)

set "RESTART=%~1"
if "%RESTART%"=="1" call :KILL_APP

echo.
echo [DIAG] JAVA_HOME = %JAVA_HOME%
echo [DIAG] Java:
java -version
echo [DIAG] Dir: %BACKEND_DIR%

echo.
echo [1/3] Compilando backend...
cd /d %BACKEND_DIR%
call mvnw.cmd clean package -DskipTests
if errorlevel 1 (
    echo.
    echo [ERRO] Falha na compilacao do backend! Veja o erro acima.
    pause
    exit /b 1
)
echo Backend compilado com sucesso.

echo.
echo [2/3] Iniciando backend na porta %BACKEND_PORT%...
echo ATENCAO: o Spring Boot leva ~45 segundos para subir.
echo Acompanhe o progresso na janela "AppAcademia-Backend" que vai abrir.
echo Aguarde a mensagem: Started AppAcademiaApplication
echo.

start "AppAcademia-Backend" cmd /k "cd /d %BACKEND_DIR% && java -Djava.io.tmpdir=C:\Temp -Djdk.net.unixdomain.tmpdir=C:\Temp -Dspring.devtools.restart.enabled=false -DJWT_SECRET=%JWT_SECRET% -DACCOUNT_SECRET=%ACCOUNT_SECRET% -jar target\AppAcademia.jar --server.port=%BACKEND_PORT% --server.address=0.0.0.0 --app.base-url=%ANDROID_BACKEND_URL%/boletobancos --spring.profiles.active=dev --spring.datasource.url=jdbc:postgresql://localhost:5432/boletobancos --spring.datasource.username=postgres --spring.datasource.password=admin --logging.level.root=INFO --logging.level.br.com.appAcademia=INFO"

:SET_FLUTTER_PROJECT
set "PROJECT_KEY=%~1"
set "PROJECT_NAME="
set "PROJECT_DIR="
set "PROJECT_PORT="
if "%PROJECT_KEY%"=="1" (
    set "PROJECT_NAME=task_manager_AppAcademiaV003"
    set "PROJECT_DIR=%FLUTTER_V003_DIR%"
    set "PROJECT_PORT=8081"
)
if "%PROJECT_KEY%"=="2" (
    set "PROJECT_NAME=task_manager_appDaniel"
    set "PROJECT_DIR=%FLUTTER_DANIEL_DIR%"
    set "PROJECT_PORT=8082"
)
if "%PROJECT_KEY%"=="3" (
    set "PROJECT_NAME=task_manager_flutter"
    set "PROJECT_DIR=%FLUTTER_CLIENT_DIR%"
    set "PROJECT_PORT=8083"
)
if "%PROJECT_KEY%"=="4" (
    set "PROJECT_NAME=task_manager_flutter_merged_final"
    set "PROJECT_DIR=%FLUTTER_BASE_DIR%"
    set "PROJECT_PORT=8084"
)
if not defined PROJECT_DIR (
    echo [ERRO] Projeto invalido: %PROJECT_KEY%
    exit /b 1
)
exit /b 0

:PICK_FLUTTER_PROJECT
echo.
echo Escolha o projeto Flutter:
echo  [1] task_manager_appAcademiaV003
echo  [2] task_manager_app_daniel
echo  [3] task_manager_flutter
echo  [4] task_manager_flutter_merged_final
echo  [0] Voltar
choice /c 12340 /n /m "Projeto: "
if "%ERRORLEVEL%"=="5" exit /b 1
call :SET_FLUTTER_PROJECT %ERRORLEVEL%
exit /b %ERRORLEVEL%

:START_ONE_FLUTTER_WEB
call :CHECK_PATHS
if errorlevel 1 exit /b 1
call :PICK_FLUTTER_PROJECT
if errorlevel 1 exit /b 1
call :START_FLUTTER_WEB "%PROJECT_NAME%" "%PROJECT_DIR%" "%PROJECT_PORT%"
exit /b %ERRORLEVEL%

:START_ALL_FLUTTER_WEB
call :CHECK_PATHS
if errorlevel 1 exit /b 1
set "RESTART=%~1"
if "%RESTART%"=="1" call :KILL_APP
call :START_BACKEND_ONLY
if errorlevel 1 exit /b 1
call :START_FLUTTER_WEB "Abraco-Contabilidade" "%FLUTTER_CLIENT_DIR%" "8083"
call :START_FLUTTER_WEB "Portal-Cont" "%FLUTTER_BASE_DIR%" "8084"
echo.
echo Portas web:
echo  Abraco Contabilidade : http://localhost:8083
echo  Portal Cont          : http://localhost:8084
exit /b 0

:START_ALL_WITH_ANDROID
call :START_ALL_FLUTTER_WEB 0
if errorlevel 1 exit /b 1
echo.
echo BlueStacks: buildando e instalando Meu Treino e Safra Direto com backend local.
call :BUILD_INSTALL_BLUESTACKS_APPS
exit /b %ERRORLEVEL%

:START_ONE_FLUTTER_ANDROID
call :CHECK_PATHS
if errorlevel 1 exit /b 1
call :PICK_FLUTTER_PROJECT
if errorlevel 1 exit /b 1
call :START_BACKEND_ONLY
if errorlevel 1 exit /b 1
call :START_FLUTTER_ANDROID "%PROJECT_NAME%" "%PROJECT_DIR%"
exit /b %ERRORLEVEL%

:BUILD_ONE_ANDROID_LOCAL
call :CHECK_PATHS
if errorlevel 1 exit /b 1
call :DETECT_HOST_IP
call :PICK_FLUTTER_PROJECT_FULL
if errorlevel 1 exit /b 1
call :ENSURE_BLUESTACKS_ADB
if errorlevel 1 exit /b 1
call :BUILD_ANDROID_PROJECT_LOCAL "%PROJECT_LABEL%" "%PROJECT_DIR%" "%PROJECT_APK_PREFIX%" "%PROJECT_PACKAGE%"
exit /b %ERRORLEVEL%

:PICK_FLUTTER_PROJECT_FULL
echo.
echo Escolha o projeto Flutter:
echo  [1] Abraco Contabilidade (task_manager_flutter)
echo  [2] Portal Contabilidade (task_manager_flutter_merged_final)
echo  [3] Meu Treino (task_manager_AppAcademiaV003)
echo  [4] Safra Direto (task_manager_appDaniel)
echo  [0] Voltar
choice /c 12340 /n /m "Projeto: "
if "%ERRORLEVEL%"=="5" exit /b 1
call :SET_FLUTTER_PROJECT_FULL %ERRORLEVEL%
exit /b %ERRORLEVEL%

:SET_FLUTTER_PROJECT_FULL
set "PROJECT_KEY=%~1"
set "PROJECT_LABEL="
set "PROJECT_DIR="
set "PROJECT_APK_PREFIX="
set "PROJECT_PACKAGE="
if "%PROJECT_KEY%"=="1" (
    set "PROJECT_LABEL=Abraco Contabilidade"
    set "PROJECT_DIR=%FLUTTER_CLIENT_DIR%"
    set "PROJECT_APK_PREFIX=Abraco"
    set "PROJECT_PACKAGE=%APP_PACKAGE_ABRACO%"
)
if "%PROJECT_KEY%"=="2" (
    set "PROJECT_LABEL=Portal Contabilidade"
    set "PROJECT_DIR=%FLUTTER_BASE_DIR%"
    set "PROJECT_APK_PREFIX=Portal"
    set "PROJECT_PACKAGE=%APP_PACKAGE_PORTAL%"
)
if "%PROJECT_KEY%"=="3" (
    set "PROJECT_LABEL=Meu Treino"
    set "PROJECT_DIR=%FLUTTER_V003_DIR%"
    set "PROJECT_APK_PREFIX=MeuTreino"
    set "PROJECT_PACKAGE=%APP_PACKAGE_MEU_TREINO%"
)
if "%PROJECT_KEY%"=="4" (
    set "PROJECT_LABEL=Safra Direto"
    set "PROJECT_DIR=%FLUTTER_DANIEL_DIR%"
    set "PROJECT_APK_PREFIX=SafraDireto"
    set "PROJECT_PACKAGE=%APP_PACKAGE_SAFRA%"
)
if not defined PROJECT_DIR (
    echo [ERRO] Projeto invalido: %PROJECT_KEY%
    exit /b 1
)
exit /b 0

:BUILD_ANDROID_PROJECT_LOCAL
set "BUILD_APP_LABEL=%~1"
set "BUILD_APP_DIR=%~2"
set "BUILD_APK_PREFIX=%~3"
set "BUILD_APP_PACKAGE=%~4"
set "BUILD_APK_DEST=%DESKTOP%\%BUILD_APK_PREFIX%_local.apk"

if not exist "%BUILD_APP_DIR%" (
    echo [ERRO] Pasta Flutter nao encontrada: %BUILD_APP_DIR%
    exit /b 1
)

echo.
echo ============================================
echo  Build Android - %BUILD_APP_LABEL% (backend local)
echo ============================================
echo Backend: %ANDROID_BACKEND_URL%
cd /d "%BUILD_APP_DIR%"
call flutter pub get
if errorlevel 1 (
    echo [ERRO] flutter pub get falhou em %BUILD_APP_LABEL%.
    exit /b 1
)
call flutter build apk --debug --dart-define=BACKEND_URL=%ANDROID_BACKEND_URL% --dart-define=WS_BACKEND_URL=%ANDROID_WS_BACKEND_URL%
if errorlevel 1 (
    echo [ERRO] Build falhou em %BUILD_APP_LABEL%.
    exit /b 1
)
copy /y "build\app\outputs\flutter-apk\app-debug.apk" "%BUILD_APK_DEST%" >nul
if errorlevel 1 (
    echo [ERRO] Falha ao copiar APK %BUILD_APP_LABEL% para o Desktop.
    exit /b 1
)
echo.
echo APK gerado: %BUILD_APK_DEST%
echo Backend: %ANDROID_BACKEND_URL% (local)
call :INSTALL_APK_FILE "%BUILD_APK_DEST%" "%BUILD_APP_PACKAGE%" "%BUILD_APP_LABEL%"
exit /b %ERRORLEVEL%

:START_BACKEND_ONLY
echo.
echo Backend na porta %BACKEND_PORT%...
powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Get-NetTCPConnection -LocalPort %BACKEND_PORT% -State Listen -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }"
if errorlevel 1 (
    start "AppAcademia-Backend" cmd /k "cd /d %BACKEND_DIR% && java -Djava.io.tmpdir=C:\Temp -Djdk.net.unixdomain.tmpdir=C:\Temp -Dspring.devtools.restart.enabled=false -DJWT_SECRET=%JWT_SECRET% -DACCOUNT_SECRET=%ACCOUNT_SECRET% -jar target\AppAcademia.jar --server.port=%BACKEND_PORT% --server.address=0.0.0.0 --app.base-url=%ANDROID_BACKEND_URL%/boletobancos --spring.profiles.active=dev --spring.datasource.url=jdbc:postgresql://localhost:5432/boletobancos --spring.datasource.username=postgres --spring.datasource.password=admin"
    echo Backend iniciando em janela propria.
) else (
    echo Backend ja esta rodando.
)
exit /b 0

:START_FLUTTER_WEB
set "RUN_NAME=%~1"
set "RUN_DIR=%~2"
set "RUN_PORT=%~3"
if not exist "%RUN_DIR%" (
    echo [ERRO] Pasta Flutter nao encontrada: %RUN_DIR%
    exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$needle = '%RUN_DIR:\=\\%'; $items = Get-CimInstance Win32_Process | Where-Object { ($_.Name -match 'flutter|dart|cmd') -and ($_.CommandLine -like ('*' + $needle + '*')) }; if ($items) { exit 0 } else { exit 1 }"
if errorlevel 1 (
    start "AppAcademia-%RUN_NAME%-Web" cmd /k "cd /d %RUN_DIR% && set GRADLE_USER_HOME=%GRADLE_USER_HOME% && flutter pub get && flutter run -d chrome --web-port %RUN_PORT% --dart-define=BACKEND_URL=%BACKEND_URL%"
    echo %RUN_NAME% iniciando no Chrome em http://localhost:%RUN_PORT%
) else (
    echo %RUN_NAME% parece ja estar rodando.
)
exit /b 0

:ENSURE_ANDROID_DEVICE
flutter devices | findstr /i "android" >nul
if not errorlevel 1 exit /b 0
echo.
echo Nenhum Android conectado. Tentando iniciar o emulador flutter_emulator...
flutter emulators --launch flutter_emulator
echo Aguardando Android aparecer...
set /a ANDROID_WAIT=0
:WAIT_ANDROID_DEVICE
set /a ANDROID_WAIT+=1
flutter devices | findstr /i "android" >nul
if not errorlevel 1 exit /b 0
if %ANDROID_WAIT% GEQ 24 (
    echo [ERRO] Nenhum Android/simulador ficou disponivel em 2 minutos.
    exit /b 1
)
timeout /t 5 /nobreak >nul
goto WAIT_ANDROID_DEVICE

:START_FLUTTER_ANDROID
set "RUN_NAME=%~1"
set "RUN_DIR=%~2"
call :ENSURE_ANDROID_DEVICE
if errorlevel 1 exit /b 1
start "AppAcademia-%RUN_NAME%-Android" cmd /k "cd /d %RUN_DIR% && set GRADLE_USER_HOME=%GRADLE_USER_HOME% && flutter pub get && flutter run -d android --device-timeout 120 --dart-define=BACKEND_URL=%ANDROID_BACKEND_URL%"
echo %RUN_NAME% iniciando no Android/simulador.
exit /b 0

:TEST_BLUESTACKS_BACKEND
call :DETECT_HOST_IP
echo.
echo Testando backend pelo endereco usado no BlueStacks:
echo %ANDROID_BACKEND_URL%
echo.
curl -s --max-time 5 %ANDROID_BACKEND_URL%/boletobancos/rest/auth/login >nul 2>&1
if errorlevel 1 (
    echo [ERRO] O Windows nao respondeu nesse IP/porta.
    echo Confira se o backend esta rodando e se o Firewall liberou a porta %BACKEND_PORT%.
    exit /b 1
)
echo Backend acessivel pelo IP da maquina.
exit /b 0

:WAIT_BACKEND
echo.
echo Aguardando backend em %BACKEND_URL% ...
set /a TENTATIVA=0
:WAIT_BACKEND_LOOP
set /a TENTATIVA+=1
curl -s --max-time 3 %BACKEND_URL%/boletobancos/rest/auth/login >nul 2>&1
if not errorlevel 1 (
    echo Backend OK.
    exit /b 0
)
if %TENTATIVA% GEQ 24 (
    echo [ERRO] Backend nao respondeu em 2 minutos.
    exit /b 1
)
echo [%TENTATIVA%/24] Backend ainda iniciando... aguardando 5s
timeout /t 5 /nobreak >nul
goto WAIT_BACKEND_LOOP

:START_FLUTTER_WEB_HEADLESS
echo Iniciando Flutter Web servidor (porta 5200) para testes Selenium...
start "AppAcademia-Flutter-Selenium" cmd /k "cd /d "%FLUTTER_DIR%" && flutter run -d web-server --web-port 5200 --web-hostname 0.0.0.0"
exit /b 0

:WAIT_FLUTTER_WEB
echo.
echo Aguardando Flutter Web em http://localhost:5200 ...
set /a FWAIT=0
:WAIT_FLUTTER_WEB_LOOP
set /a FWAIT+=1
curl -s --max-time 3 http://localhost:5200 >nul 2>&1
if not errorlevel 1 (
    echo Flutter Web OK na porta 5200.
    exit /b 0
)
if %FWAIT% GEQ 36 (
    echo [ERRO] Flutter Web nao respondeu em 3 minutos - verifique se compilou corretamente.
    exit /b 1
)
echo [%FWAIT%/36] Flutter Web ainda compilando... aguardando 5s
timeout /t 5 /nobreak >nul
goto WAIT_FLUTTER_WEB_LOOP

:RUN_TESTS
call :CHECK_PATHS
if errorlevel 1 exit /b 1
call :CHECK_SELENIUM
if errorlevel 1 exit /b 1
call :WAIT_BACKEND
if errorlevel 1 exit /b 1

set "MODE=%~1"
set "FLUTTER_STATUS=N/A"
set "SELENIUM_STATUS=N/A"

if /i "%MODE%"=="flutter" goto TEST_FLUTTER
if /i "%MODE%"=="selenium" goto TEST_SELENIUM
if /i "%MODE%"=="all" goto TEST_FLUTTER
echo [ERRO] Modo de teste invalido: %MODE%
exit /b 1

:TEST_FLUTTER
echo.
echo ============================================
echo  Testes Flutter HTTP
echo ============================================
cd /d "%FLUTTER_DIR%"
call flutter test full_system_crud_test.dart --dart-define=BACKEND_URL=%BACKEND_URL% --reporter=expanded --timeout=60s
if errorlevel 1 (
    set "FLUTTER_STATUS=FALHOU"
) else (
    set "FLUTTER_STATUS=PASSOU"
)
if /i "%MODE%"=="flutter" goto TEST_SUMMARY

:TEST_SELENIUM
echo.
echo ============================================
echo  Testes Selenium UI
echo ============================================
where python >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Python nao encontrado no PATH.
    set "SELENIUM_STATUS=ERRO-PYTHON"
    goto TEST_SUMMARY
)
rem — Verifica se Flutter Web ja esta rodando na porta 5200 (necessario para Selenium)
set "FLUTTER_WEB_STARTED=0"
curl -s --max-time 3 http://localhost:5200 >nul 2>&1
if errorlevel 1 (
    echo Flutter Web nao detectado na porta 5200 - iniciando automaticamente...
    call :START_FLUTTER_WEB_HEADLESS
    call :WAIT_FLUTTER_WEB
    if errorlevel 1 (
        echo [AVISO] Flutter Web nao subiu - testes Selenium vao falhar com ERR_CONNECTION_REFUSED
        echo [AVISO] Inicie manualmente: flutter run -d web-server --web-port 5200
    ) else (
        set "FLUTTER_WEB_STARTED=1"
    )
) else (
    echo Flutter Web ja esta rodando na porta 5200.
)
set "APP_ACADEMIA_BASE_URL=http://localhost:5200"
call "%SELENIUM_DIR%\run_tests.bat"
if errorlevel 1 (
    set "SELENIUM_STATUS=FALHOU"
) else (
    set "SELENIUM_STATUS=PASSOU"
)

:TEST_SUMMARY
echo.
echo ============================================
echo  Resultado dos testes
echo ============================================
if not "%FLUTTER_STATUS%"=="N/A" echo Flutter HTTP : %FLUTTER_STATUS%
if not "%SELENIUM_STATUS%"=="N/A" echo Selenium UI : %SELENIUM_STATUS%

if "%FLUTTER_STATUS%"=="FALHOU" exit /b 1
if "%SELENIUM_STATUS%"=="FALHOU" exit /b 1
if "%SELENIUM_STATUS%"=="ERRO-PYTHON" exit /b 1
exit /b 0

:BUILD_ANDROID
call :CHECK_PATHS
if errorlevel 1 exit /b 1
set "BUILD_BACKEND_URL=%ANDROID_BACKEND_URL%"
set "BUILD_PROFILE=local"
goto BUILD_ANDROID_WITH_PROFILE

:BUILD_ANDROID_DEPLOY
call :CHECK_PATHS
if errorlevel 1 exit /b 1
set "BUILD_BACKEND_URL=%DEPLOY_BACKEND_URL%"
set "BUILD_PROFILE=deployado"

:BUILD_ANDROID_WITH_PROFILE

cd /d "%FLUTTER_DIR%"
set "VERSION=unknown"
set "FULL_VER="
for /f "tokens=2 delims=: " %%V in ('findstr /b "version:" pubspec.yaml') do set "FULL_VER=%%V"
for /f "tokens=1 delims=+" %%V in ("!FULL_VER!") do set "VERSION=%%V"

set "APK_NAME=AppAcademia_%VERSION%.apk"
set "APK_DEST=%DESKTOP%\%APK_NAME%"

echo.
echo Versao  : %VERSION%
echo APK     : %APK_NAME%
echo Perfil  : %BUILD_PROFILE%
echo Backend : %BUILD_BACKEND_URL%
echo.

echo [1/2] flutter pub get...
call flutter pub get
if errorlevel 1 (
    echo [ERRO] flutter pub get falhou.
    exit /b 1
)

echo.
echo [2/2] Buildando APK debug...
call flutter build apk --debug --dart-define=BACKEND_URL=%BUILD_BACKEND_URL%
if errorlevel 1 (
    echo [ERRO] Build falhou.
    exit /b 1
)

copy /y "build\app\outputs\flutter-apk\app-debug.apk" "%APK_DEST%" >nul
if errorlevel 1 (
    echo [ERRO] Falha ao copiar APK para o Desktop.
    exit /b 1
)

echo APK gerado: %APK_DEST%
exit /b 0

:BUILD_INSTALL_BLUESTACKS_APPS
call :CHECK_PATHS
if errorlevel 1 exit /b 1
call :DETECT_HOST_IP
call :START_BACKEND_ONLY
if errorlevel 1 exit /b 1
call :ENSURE_BLUESTACKS_ADB
if errorlevel 1 exit /b 1
call :BUILD_ANDROID_PROJECT "MeuTreino" "%FLUTTER_V003_DIR%" "MeuTreino" "%APP_PACKAGE_MEU_TREINO%"
if errorlevel 1 exit /b 1
call :BUILD_ANDROID_PROJECT "SafraDireto" "%FLUTTER_DANIEL_DIR%" "SafraDireto" "%APP_PACKAGE_SAFRA%"
if errorlevel 1 exit /b 1
echo.
echo BlueStacks atualizado com Meu Treino e Safra Direto.
exit /b 0

:BUILD_ANDROID_PROJECT
set "BUILD_APP_LABEL=%~1"
set "BUILD_APP_DIR=%~2"
set "BUILD_APK_PREFIX=%~3"
set "BUILD_APP_PACKAGE=%~4"
set "BUILD_APK_DEST=%DESKTOP%\%BUILD_APK_PREFIX%_local.apk"

if not exist "%BUILD_APP_DIR%" (
    echo [ERRO] Pasta Flutter nao encontrada: %BUILD_APP_DIR%
    exit /b 1
)

echo.
echo ============================================
echo  Build Android - %BUILD_APP_LABEL%
echo ============================================
echo Backend Android: %ANDROID_BACKEND_URL%
cd /d "%BUILD_APP_DIR%"
call flutter pub get
if errorlevel 1 (
    echo [ERRO] flutter pub get falhou em %BUILD_APP_LABEL%.
    exit /b 1
)
call flutter build apk --debug --dart-define=BACKEND_URL=%ANDROID_BACKEND_URL% --dart-define=WS_BACKEND_URL=%ANDROID_WS_BACKEND_URL%
if errorlevel 1 (
    echo [ERRO] Build falhou em %BUILD_APP_LABEL%.
    exit /b 1
)
copy /y "build\app\outputs\flutter-apk\app-debug.apk" "%BUILD_APK_DEST%" >nul
if errorlevel 1 (
    echo [ERRO] Falha ao copiar APK %BUILD_APP_LABEL% para o Desktop.
    exit /b 1
)
call :INSTALL_APK_FILE "%BUILD_APK_DEST%" "%BUILD_APP_PACKAGE%" "%BUILD_APP_LABEL%"
exit /b %ERRORLEVEL%

:BUILD_ALL_APKS_DEPLOY
call :CHECK_PATHS
if errorlevel 1 exit /b 1
call :DETECT_HOST_IP
call :ENSURE_BLUESTACKS_ADB
if errorlevel 1 exit /b 1

set "BUILD_BACKEND_URL=%DEPLOY_BACKEND_URL%"
set "BUILD_WS_URL=wss://%DEPLOY_BACKEND_URL%/boletobancos"

echo.
echo ============================================
echo  Build 4 APKs com backend DEPLOYADO
echo ============================================
echo Backend : %BUILD_BACKEND_URL%
echo.
echo Os APKs serao copiados para o Desktop e instalados no BlueStacks.
echo.

call :BUILD_ANDROID_PROJECT_DEPLOY "Abraco" "%FLUTTER_CLIENT_DIR%" "Abraco" "%APP_PACKAGE_ABRACO%"
if errorlevel 1 exit /b 1
call :BUILD_ANDROID_PROJECT_DEPLOY "Portal" "%FLUTTER_BASE_DIR%" "Portal" "%APP_PACKAGE_PORTAL%"
if errorlevel 1 exit /b 1
call :BUILD_ANDROID_PROJECT_DEPLOY "MeuTreino" "%FLUTTER_V003_DIR%" "MeuTreino" "%APP_PACKAGE_MEU_TREINO%"
if errorlevel 1 exit /b 1
call :BUILD_ANDROID_PROJECT_DEPLOY "SafraDireto" "%FLUTTER_DANIEL_DIR%" "SafraDireto" "%APP_PACKAGE_SAFRA%"
if errorlevel 1 exit /b 1

echo.
echo ============================================
echo  4 APKs buildados e instalados no BlueStacks!
echo ============================================
exit /b 0

:BUILD_ANDROID_PROJECT_DEPLOY
set "BUILD_APP_LABEL=%~1"
set "BUILD_APP_DIR=%~2"
set "BUILD_APK_PREFIX=%~3"
set "BUILD_APP_PACKAGE=%~4"
set "BUILD_APK_DEST=%DESKTOP%\%BUILD_APK_PREFIX%_deploy.apk"

if not exist "%BUILD_APP_DIR%" (
    echo [ERRO] Pasta Flutter nao encontrada: %BUILD_APP_DIR%
    exit /b 1
)

echo.
echo ============================================
echo  Build Android - %BUILD_APP_LABEL% (deployado)
echo ============================================
echo Backend: %BUILD_BACKEND_URL%
cd /d "%BUILD_APP_DIR%"
call flutter pub get
if errorlevel 1 (
    echo [ERRO] flutter pub get falhou em %BUILD_APP_LABEL%.
    exit /b 1
)
call flutter build apk --debug --dart-define=BACKEND_URL=%BUILD_BACKEND_URL% --dart-define=WS_BACKEND_URL=%BUILD_WS_URL%
if errorlevel 1 (
    echo [ERRO] Build falhou em %BUILD_APP_LABEL%.
    exit /b 1
)
copy /y "build\app\outputs\flutter-apk\app-debug.apk" "%BUILD_APK_DEST%" >nul
if errorlevel 1 (
    echo [ERRO] Falha ao copiar APK %BUILD_APP_LABEL% para o Desktop.
    exit /b 1
)
echo APK gerado: %BUILD_APK_DEST%
call :INSTALL_APK_FILE "%BUILD_APK_DEST%" "%BUILD_APP_PACKAGE%" "%BUILD_APP_LABEL%"
exit /b %ERRORLEVEL%

:ENSURE_BLUESTACKS_ADB
if not exist "%ADB%" (
    echo [ERRO] ADB nao encontrado: %ADB%
    exit /b 1
)
echo.
echo Verificando BlueStacks 5...
tasklist /fi "imagename eq HD-Player.exe" 2>nul | find "HD-Player.exe" >nul
if errorlevel 1 (
    echo BlueStacks nao esta rodando. Iniciando...
    start "" "C:\Program Files\BlueStacks_nxt\HD-Player.exe"
    echo Aguardando BlueStacks inicializar...
    timeout /t 30 /nobreak >nul
) else (
    echo BlueStacks ja esta rodando.
)
echo.
echo Conectando ADB ao BlueStacks...
echo Se necessario, no BlueStacks ative: Configuracoes ^> Avancado ^> ADB.
set /a TENTATIVA=0
:TENTA_BS_ADB
set /a TENTATIVA+=1
"%ADB%" connect 127.0.0.1:5555 >nul 2>&1
"%ADB%" devices 2>nul | find "5555" >nul
if not errorlevel 1 goto BS_ADB_OK
if %TENTATIVA% GEQ 6 (
    echo [ERRO] Nao foi possivel conectar ao BlueStacks via ADB.
    exit /b 1
)
echo Tentativa %TENTATIVA%/6 - aguardando 5s...
timeout /t 5 /nobreak >nul
goto TENTA_BS_ADB

:BS_ADB_OK
echo BlueStacks conectado via ADB.
call :CLEANUP_LEGACY_APPS
exit /b 0

:CLEANUP_LEGACY_APPS
rem O app "Abraco Contabilidade" trocou de applicationId em algum momento
rem (de com.washingtonclimaco.task_manager_flutter para br.com.abracocontabilidade.app).
rem O Android trata isso como apps DIFERENTES: "adb install -r" nunca substitui
rem o app antigo, que fica esquecido no BlueStacks com o icone generico
rem "task_manager_flutter" e codigo/backend antigos (causa de "Incorrect email or
rem password" ao tentar logar nele em vez do app novo). Remove o residuo aqui,
rem antes de qualquer instalacao, para nao confundir o usuario com 2 icones iguais.
"%ADB%" -s 127.0.0.1:5555 shell pm uninstall com.washingtonclimaco.task_manager_flutter >nul 2>&1
exit /b 0

:INSTALL_APK_FILE
set "INSTALL_APK=%~1"
set "INSTALL_PACKAGE=%~2"
set "INSTALL_LABEL=%~3"
if not exist "%INSTALL_APK%" (
    echo [ERRO] APK nao encontrado: %INSTALL_APK%
    exit /b 1
)
echo.
echo Instalando %INSTALL_LABEL% no BlueStacks...
"%ADB%" -s 127.0.0.1:5555 install -r "%INSTALL_APK%"
if errorlevel 1 (
    echo [ERRO] Falha na instalacao de %INSTALL_LABEL%.
    exit /b 1
)
echo Iniciando %INSTALL_LABEL%...
"%ADB%" -s 127.0.0.1:5555 shell monkey -p %INSTALL_PACKAGE% -c android.intent.category.LAUNCHER 1 >nul 2>&1
exit /b 0

:INSTALL_BLUESTACKS
set "APK="
set "APK_NAME="
for /f "delims=" %%F in ('dir /b /o-d "%DESKTOP%\AppAcademia_*.apk" 2^>nul') do (
    if not defined APK (
        set "APK=%DESKTOP%\%%F"
        set "APK_NAME=%%F"
    )
)

if not defined APK (
    echo [ERRO] Nenhum APK AppAcademia_*.apk encontrado no Desktop.
    echo Rode a opcao 6 primeiro.
    exit /b 1
)

if not exist "%ADB%" (
    echo [ERRO] ADB nao encontrado: %ADB%
    exit /b 1
)

echo.
echo APK encontrado: %APK_NAME%
echo.
echo [1/4] Verificando BlueStacks...
tasklist /fi "imagename eq HD-Player.exe" 2>nul | find "HD-Player.exe" >nul
if errorlevel 1 (
    echo BlueStacks nao esta rodando. Iniciando...
    start "" "C:\Program Files\BlueStacks_nxt\HD-Player.exe"
    echo Aguardando BlueStacks inicializar...
    timeout /t 30 /nobreak >nul
) else (
    echo BlueStacks ja esta rodando.
)

echo.
echo [2/4] Conectando ADB ao BlueStacks...
echo Se necessario, no BlueStacks ative: Configuracoes ^> Avancado ^> ADB.
set /a TENTATIVA=0
:TENTA_ADB
set /a TENTATIVA+=1
"%ADB%" connect 127.0.0.1:5555 >nul 2>&1
"%ADB%" devices 2>nul | find "5555" >nul
if not errorlevel 1 goto ADB_OK
if %TENTATIVA% GEQ 6 (
    echo [ERRO] Nao foi possivel conectar ao BlueStacks via ADB.
    exit /b 1
)
echo Tentativa %TENTATIVA%/6 - aguardando 5s...
timeout /t 5 /nobreak >nul
goto TENTA_ADB

:ADB_OK
echo BlueStacks conectado via ADB.

echo.
echo [3/4] Instalando %APK_NAME%...
"%ADB%" -s 127.0.0.1:5555 install -r "%APK%"
if errorlevel 1 (
    echo [ERRO] Falha na instalacao.
    exit /b 1
)

echo.
echo [4/4] Iniciando app...
"%ADB%" -s 127.0.0.1:5555 shell monkey -p %APP_PACKAGE_ABRACO% -c android.intent.category.LAUNCHER 1 >nul 2>&1
echo App iniciado.
exit /b 0

:GIT_PULL_ALL
echo.
echo ============================================
echo  Atualizando todos os repositorios
echo ============================================
echo.
set "REPOS=%APP_ROOT%\AppAcademia %APP_ROOT%\task_manager_flutter %APP_ROOT%\task_manager_flutter_merged_final %APP_ROOT%\task_manager_AppAcademiaV003 %APP_ROOT%\task_manager_appDaniel %APP_ROOT%\entusiasta-tributario"
for %%R in (%REPOS%) do (
    if exist "%%R\.git" (
        echo ----------------------------------------
        echo Repositorio: %%~nxR
        echo ----------------------------------------
        cd /d "%%R"
        git checkout main 2>nul || git checkout master 2>nul
        git pull --rebase
        if errorlevel 1 (
            echo [ATENCAO] Falha ao atualizar %%~nxR - pode haver conflitos.
        ) else (
            echo OK
        )
        echo.
    ) else (
        echo [AVISO] %%R nao e um repositorio git
    )
)
cd /d "%APP_ROOT%"
echo ============================================
echo  Todos os repositorios atualizados!
echo ============================================
exit /b 0

:RUN_ALL
call :KILL_APP
call :START_ALL_WITH_ANDROID
if errorlevel 1 exit /b 1
call :RUN_TESTS all
if errorlevel 1 exit /b 1
exit /b 0

:DETECT_HOST_IP
for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$ip = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '169.254*' -and $_.IPAddress -ne '127.0.0.1' -and $_.InterfaceAlias -notmatch 'vEthernet|VMware|VirtualBox|Tailscale|Loopback' } | Sort-Object InterfaceMetric | Select-Object -First 1 -ExpandProperty IPAddress; if (-not $ip) { $ip = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '169.254*' -and $_.IPAddress -ne '127.0.0.1' } | Select-Object -First 1 -ExpandProperty IPAddress }; Write-Output $ip"`) do set "HOST_IP=%%I"
if not defined HOST_IP set "HOST_IP=127.0.0.1"
set "BACKEND_URL=http://127.0.0.1:%BACKEND_PORT%"
set "ANDROID_BACKEND_URL=http://%HOST_IP%:%BACKEND_PORT%"
set "ANDROID_WS_BACKEND_URL=ws://%HOST_IP%:%BACKEND_PORT%/boletobancos"
exit /b 0
