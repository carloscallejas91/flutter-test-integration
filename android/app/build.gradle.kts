plugins {
    id("com.android.application")
    id("kotlin-android")
    // O Plugin Gradle do Flutter deve ser aplicado após os plugins Gradle do Android e Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
    // START: Configuração do FlutterFire
    // O plugin google-services deve ser o último plugin aplicado.
    id("com.google.gms.google-services")
    // END: Configuração do FlutterFire
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

        // Adicionado para testes de instrumentação
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

dependencies {
    // Firebase BoM (Bill of Materials) - Garante versões compatíveis
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))

    // Dependência do Firebase Analytics (versão KTX)
    implementation("com.google.firebase:firebase-analytics-ktx")

    // Adicionado de volta explicitamente para resolver problemas de referência
    implementation("com.google.firebase:firebase-common-ktx")

    // Dependências para testes de instrumentação
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test:runner:1.6.1")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.6.1")
}

