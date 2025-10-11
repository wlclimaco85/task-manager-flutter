# rebuild_flutter.ps1
# Script completo para corrigir Android e buildar Flutter AppBundle

Write-Host "🚀 Iniciando rebuild completo do projeto Flutter..."

# 1️⃣ Caminhos dos arquivos
$projectRoot = Resolve-Path "."
$androidRoot = Join-Path $projectRoot "android"
$appRoot = Join-Path $androidRoot "app"
$mainActivityPath = Join-Path $appRoot "src\main\kotlin\com\example\task_manager_flutter\MainActivity.kt"
$gradleWrapperPath = Join-Path $androidRoot "gradle\wrapper\gradle-wrapper.properties"
$settingsGradlePath = Join-Path $androidRoot "settings.gradle"
$buildGradleRootPath = Join-Path $androidRoot "build.gradle"
$buildGradleAppPath = Join-Path $appRoot "build.gradle"

# 2️⃣ Substituir arquivos essenciais

Write-Host "📄 Atualizando MainActivity.kt..."
$mainActivityContent = @"
package com.washingtonclimaco.task_manager_flutter

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
}
"@
New-Item -ItemType Directory -Force -Path (Split-Path $mainActivityPath)
Set-Content -Path $mainActivityPath -Value $mainActivityContent -Force

Write-Host "📄 Atualizando gradle-wrapper.properties..."
$gradleWrapperContent = "distributionUrl=https\://services.gradle.org/distributions/gradle-8.7-bin.zip"
Set-Content -Path $gradleWrapperPath -Value $gradleWrapperContent -Force

Write-Host "📄 Atualizando settings.gradle..."
$settingsGradleContent = @"
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
    plugins {
        id "com.android.application" version "8.5.2" apply false
        id "org.jetbrains.kotlin.android" version "1.9.22" apply false
        id "dev.flutter.flutter-gradle-plugin" version "1.0.0" apply false
    }
}
include(":app")
"@
Set-Content -Path $settingsGradlePath -Value $settingsGradleContent -Force

Write-Host "📄 Atualizando build.gradle (root)..."
$buildGradleRootContent = @"
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = "../build"
subprojects {
    project.buildDir = "\${rootProject.buildDir}/\${project.name}"
}

tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
"@
Set-Content -Path $buildGradleRootPath -Value $buildGradleRootContent -Force

Write-Host "📄 Atualizando app/build.gradle..."
$buildGradleAppContent = @"
plugins {
    id "com.android.application"
    id "org.jetbrains.kotlin.android"
    id "dev.flutter.flutter-gradle-plugin"
}

android {
    namespace "com.washingtonclimaco.task_manager_flutter"
    compileSdk 34

    defaultConfig {
        applicationId "com.washingtonclimaco.task_manager_flutter"
        minSdkVersion 21
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.22"
}
"@
Set-Content -Path $buildGradleAppPath -Value $buildGradleAppContent -Force

# 3️⃣ Limpeza completa de caches
Write-Host "🧹 Limpando caches e builds antigos..."
$pathsToClean = @(
    Join-Path $projectRoot "build",
    Join-Path $projectRoot ".dart_tool",
    Join-Path $androidRoot ".gradle",
    Join-Path $appRoot "build"
)

foreach ($p in $pathsToClean) {
    if (Test-Path $p) {
        Remove-Item -Recurse -Force $p
        Write-Host "Limpo: $p"
    }
}

# Passo 1: Entrar na pasta android e limpar o cache do Gradle
Write-Host "🧹 Limpando build do Gradle..." -ForegroundColor Yellow
Set-Location android
./gradlew clean

# Passo 2: Voltar para a raiz do projeto
Set-Location ..


Write-Host "⚡ Executando flutter clean..."
flutter clean

Write-Host "📦 Baixando dependências..."
flutter pub get

# 4️⃣ Build do AppBundle
Write-Host "🏗️ Buildando AppBundle (.aab) em modo --profile..."
flutter build appbundle --profile

Write-Host "✅ Rebuild completo finalizado!"
