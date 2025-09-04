pipeline {
    // A mágica acontece aqui: Jenkins irá construir e usar o Dockerfile como seu ambiente.
    agent { dockerfile true }

    environment {
        FIREBASE_PROJECT_ID = "test-integration-app-4e52e"
        SERVICE_ACCOUNT_CREDENTIALS_ID = "firebase-service-account-key"
        FIREBASE_APP_ID="1:424599350937:android:5c7fd412fffd453bcb5208"
//         IMAGE_NAME = "test-integration-app/flutter-builder:${env.BUILD_NUMBER}"
    }

    stages {
        stage('Build & Test') {
            steps {
                // Como estamos DENTRO do container, usamos 'sh' e os comandos rodam nativamente.
                withCredentials([file(credentialsId: SERVICE_ACCOUNT_CREDENTIALS_ID, variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh '''
                        echo "--- Passo 1: Preparando o ambiente Flutter ---"
                        # O código já está aqui, o 'checkout scm' do Jenkins cuida disso.
                        flutter pub get

                        echo "--- Passo 2: Construindo APKs ---"
                        cd android
                        chmod +x ./gradlew
                        ./gradlew clean
                        ./gradlew app:assembleDebug assembleDebugAndroidTest

                        echo "--- Passo 3: Autenticando com Google Cloud ---"
                        gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
                        gcloud config set project ${FIREBASE_PROJECT_ID}

                        echo "--- Passo 4: Rodando testes no Firebase Test Lab ---"
                        gcloud firebase test android run \
                          --type instrumentation \
                          --app app/build/outputs/apk/debug/app-debug.apk \
                          --test app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
                          --device model=pixel6,version=34,locale=pt_BR,orientation=portrait \
                          --timeout 15m
                    '''
                }
            }
        }

        stage('Deploy to App Distribution') {
            steps {
                 withCredentials([file(credentialsId: SERVICE_ACCOUNT_CREDENTIALS_ID, variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh '''
                        echo "--- Passo 5: Distribuindo APK para o grupo de QA ---"
                        gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
                        gcloud config set project ${FIREBASE_PROJECT_ID}
                        gcloud firebase appdistribution apps distribute android/app/build/outputs/apk/debug/app-debug.apk \
                          --app ${FIREBASE_APP_ID} \
                          --release-notes "Build ${BUILD_NUMBER} via Jenkins. Testes de integração passaram." \
                          --groups "qa-testers"
                    '''
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finalizado. Limpando workspace..."
            cleanWs()
        }
    }
}

