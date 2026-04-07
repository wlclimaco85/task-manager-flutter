plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.washingtonclimaco.task_manager_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.washingtonclimaco.task_manager_flutter"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 9
        versionName = "1.0.9"
    }

    signingConfigs {
        create("release") {
            storeFile     = file(System.getenv("ANDROID_KEYSTORE_PATH") ?: "keystore.jks")
            storePassword = System.getenv("ANDROID_STORE_PASSWORD") ?: ""
            keyAlias      = System.getenv("ANDROID_KEY_ALIAS") ?: "upload"
            keyPassword   = System.getenv("ANDROID_KEY_PASSWORD") ?: ""
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig    = signingConfigs.getByName("release")
            isMinifyEnabled  = false
            isShrinkResources = false
        }
        getByName("debug") {
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    androidTestImplementation("tools.fastlane:screengrab:2.1.1")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test:rules:1.5.0")
}
