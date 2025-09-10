plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // O plugin do google-services é aplicado aqui
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

        // Configuração para o executor de testes de instrumentação.
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
    // Importa o Firebase Bill of Materials (BoM)
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))

    // Adiciona as dependências do Firebase que você precisa, sem especificar a versão
    implementation("com.google.firebase:firebase-analytics")

    // Adiciona as dependências de teste necessárias com as versões corrigidas
    testImplementation("junit:junit:4.13.2")
    // Adiciona a dependência core-ktx para resolver o problema do manifesto
    androidTestImplementation("androidx.test:runner:1.2.0")
    androidTestImplementation("androidx.test:core-ktx:1.6.1")
//    androidTestImplementation("androidx.test.ext:junit:1.1.1")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.2.0")
}

