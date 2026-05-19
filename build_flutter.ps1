# build_flutter.ps1
# Roda os testes de integração e só faz o build se todos passarem.

Write-Host "🧪 Rodando testes antes do build..."
flutter test test/services/ --reporter expanded

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "❌ Testes falharam! Build cancelado." -ForegroundColor Red
    Write-Host "   Corrija os erros acima e tente novamente." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "✅ Todos os testes passaram! Iniciando build..." -ForegroundColor Green
Write-Host ""

# 1️⃣ Fechar possíveis processos travados
Write-Host "Matando processos Java e Gradle..."
Stop-Process -Name "java" -ErrorAction SilentlyContinue
Stop-Process -Name "gradle" -ErrorAction SilentlyContinue

# 2️⃣ Limpar caches e builds antigos
Write-Host "Limpando caches e builds..."
$pathsToClean = @(
    "build",
    ".dart_tool",
    "android\.gradle",
    "android\build"
)

foreach ($p in $pathsToClean) {
    if (Test-Path $p) {
        Remove-Item -Recurse -Force $p
        Write-Host "Limpou: $p"
    }
}

# 3️⃣ Atualizar gradle-wrapper.properties
Write-Host "Atualizando gradle-wrapper para Gradle 8.7..."
$gradleWrapper = "android\gradle\wrapper\gradle-wrapper.properties"
if (Test-Path $gradleWrapper) {
    (Get-Content $gradleWrapper) -replace "distributionUrl=.*", "distributionUrl=https\://services.gradle.org/distributions/gradle-8.7-bin.zip" | Set-Content $gradleWrapper
    Write-Host "Gradle-wrapper atualizado."
}

# 4️⃣ Limpar Flutter e baixar dependências
Write-Host "Executando flutter clean e flutter pub get..."
flutter clean
flutter pub get

# 5️⃣ Buildar AppBundle
Write-Host "Gerando AppBundle (.aab) em modo --profile..."
flutter build appbundle --profile

Write-Host ""
Write-Host "🚀 Build finalizado com sucesso!" -ForegroundColor Green
