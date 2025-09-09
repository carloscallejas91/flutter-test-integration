plugins {
    id("com.android.application")
    id("kotlin-android")
    // O plugin do Flutter deve ser aplicado depois dos outros
    id("dev.flutter.flutter-gradle-plugin")
    // O plugin do Google Services deve ser o último
    id("com.google.gms.google-services")
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

        // Configuração do executor de testes do Android
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        testInstrumentationRunnerArguments["clearPackageData"] = "true"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Configuração para usar o Orquestrador de Testes
    testOptions {
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Importa o Firebase Bill of Materials (BoM)
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))

    // Adiciona as dependências do Firebase que a sua aplicação usa
    implementation("com.google.firebase:firebase-analytics")

    // Dependências para os testes de instrumentação e o Orquestrador
    androidTestImplementation("androidx.test:runner:1.6.1")
    androidTestImplementation("androidx.test:rules:1.6.1")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.6.1")
    androidTestUtil("androidx.test:orchestrator:1.5.0")
}

