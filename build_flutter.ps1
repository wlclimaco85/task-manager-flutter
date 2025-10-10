# build_flutter.ps1
# Script completo para limpar, atualizar e buildar Flutter AppBundle no Windows

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

# 4️⃣ Atualizar Android Gradle Plugin (AGP) via settings.gradle/plugins block
Write-Host "Verifique se android/settings.gradle está configurado para AGP 8.5.2..."
# (O usuário precisa garantir manualmente se não estiver usando Flutter template atualizado)

# 5️⃣ Limpar Flutter e baixar dependências
Write-Host "Executando flutter clean e flutter pub get..."
flutter clean
flutter pub get

# 6️⃣ Buildar AppBundle
Write-Host "Gerando AppBundle (.aab) em modo --profile..."
flutter build appbundle --profile

Write-Host "✅ Build finalizado!"
