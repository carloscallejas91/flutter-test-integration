pipeline {
    agent any

    environment {
        FIREBASE_PROJECT_ID = "test-integration-app-4e52e"
        SERVICE_ACCOUNT_CREDENTIALS_ID = "firebase-service-account-key"
        IMAGE_NAME = "test-integration-app/flutter-builder:${env.BUILD_NUMBER}"
        FIREBASE_APP_ID="1:424599350937:android:5c7fd412fffd453bcb5208"
    }

    stages {
        stage('Build Docker Image') {
            steps {
                checkout scm
                script {
                    echo "Construindo imagem de build já com o código do app..."
                    docker.build(IMAGE_NAME, '.')
                }
            }
        }

        stage('Build APKs') {
            steps {
                script {
                    echo "Construindo APKs..."
                    // ==================== CORREÇÃO FINAL ====================
                    // Nós não montamos o código fonte inteiro. Em vez disso, montamos
                    // apenas a pasta de 'build' para que os resultados do container
                    // apareçam no nosso workspace do Jenkins.
                    bat """
                        docker run --rm --workdir /home/flutterdev/app ^
                            -v "%cd%/android/app/build":/home/flutterdev/app/android/app/build ^
                            ${IMAGE_NAME} ^
                            sh -c "cd android && chmod +x ./gradlew && ./gradlew clean && ./gradlew app:assembleDebug assembleDebugAndroidTest"
                    """
                }
            }
        }

        stage('Run Tests and Deploy') {
            steps {
                withCredentials([file(credentialsId: SERVICE_ACCOUNT_CREDENTIALS_ID, variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    bat '''
                        echo "Autenticando com o Google Cloud..."
                        gcloud auth activate-service-account --key-file="%GOOGLE_APPLICATION_CREDENTIALS%"
                        gcloud config set project %FIREBASE_PROJECT_ID%

                        echo "Verificando se os APKs existem..."
                        dir android\\app\\build\\outputs\\apk\\debug

                        echo "Enviando APKs para o Firebase Test Lab..."
                        gcloud firebase test android run ^
                          --type instrumentation ^
                          --app android/app/build/outputs/apk/debug/app-debug.apk ^
                          --test android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk ^
                          --device model=pixel6,version=34,locale=pt_BR,orientation=portrait ^
                          --timeout 15m

                        echo "Testes passaram! Distribuindo APK para o grupo de QA..."
                        gcloud firebase appdistribution apps distribute android/app/build/outputs/apk/debug/app-debug.apk ^
                          --app %FIREBASE_APP_ID% ^
                          --release-notes "Build %BUILD_NUMBER% via Jenkins. Testes de integração passaram." ^
                          --groups "qa-testers"
                    '''
                }
            }
        }
    }

    post {
        always {
            // ... (seção post permanece a mesma)
        }
    }
}