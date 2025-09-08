plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.test_integration.test_integration_app"
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
        applicationId = "com.test_integration.test_integration_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Define o runner para os testes de instrumentação
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// Bloco de dependências que agrupa todas as bibliotecas necessárias.
dependencies {
    // Firebase Bill of Materials (BoM) para gerir as versões das bibliotecas Firebase
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))

    // Dependência do Firebase Analytics (que inclui o core)
    implementation("com.google.firebase:firebase-analytics")

    // Testes de unidade (locais)
    testImplementation("junit:junit:4.13.2")

    // Dependências para os testes de instrumentação (executados no dispositivo)
    androidTestImplementation("androidx.test:runner:1.5.2")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}

