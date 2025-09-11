plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

configurations.all {
    resolutionStrategy {
        // força versões compatíveis para evitar conflitos entre integration_test e espresso/runner
        force("androidx.test:runner:1.2.0")
        force("androidx.test:rules:1.2.0")
        force("androidx.test.espresso:espresso-core:3.2.0")
    }
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
        //        testInstrumentationRunner = "dev.flutter.plugins.integration_test.FlutterTestRunner"
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
    // Firebase Bill of Materials (BoM) - Gerencia as versões das bibliotecas do Firebase
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))

    // Dependência principal do Analytics, que já inclui as extensões KTX.
    implementation("com.google.firebase:firebase-analytics")

    // garante que as classes do integration_test (incluindo FlutterTestRunner) estejam
    // embaladas no APK de teste
    androidTestImplementation(project(":integration_test"))

    // Dependências de Teste (versões modernas e consistentes)
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test:runner:1.2.0")
    androidTestImplementation("androidx.test:rules:1.2.0")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.2.0")

//    androidTestImplementation("androidx.test.ext:junit-ktx:1.2.1")
//    androidTestImplementation("androidx.test.espresso:espresso-core:3.6.1")
//
//    // Dependências para o Orquestrador de Testes
//    androidTestUtil("androidx.test:orchestrator:1.5.0")
}

