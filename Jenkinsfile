pipeline {
    agent any

    environment {
        FIREBASE_PROJECT_ID = "test-integration-app-4e52e"
        SERVICE_ACCOUNT_CREDENTIALS_ID = "firebase-service-account-key"
        IMAGE_NAME = "test-integration-app/flutter-builder:${env.BUILD_NUMBER}"
        FIREBASE_APP_ID="1:424599350937:android:5c7fd412fffd453bcb5208"
    }

    stages {
        stage('Checkout & Build Image') {
            steps {
                checkout scm
                script {
                    echo "Construindo imagem de build..."
                    docker.build(IMAGE_NAME, '.')
                }
            }
        }

        stage('Build APKs inside Container') {
            steps {
                script {
                    echo "Construindo APKs com comando 'docker run' manual..."
                    bat """
                        docker run --rm --workdir /home/flutterdev/app ^
                            -v "%cd%":/home/flutterdev/app ^
                            ${IMAGE_NAME} ^
                            sh -c "cd android && chmod +x ./gradlew && ./gradlew clean && ./gradlew app:assembleDebug assembleDebugAndroidTest"
                    """
                }
            }
        }

        // Os estágios seguintes permanecem os mesmos
        stage('Run Tests on Firebase Test Lab') {
            steps {
                withCredentials([file(credentialsId: SERVICE_ACCOUNT_CREDENTIALS_ID, variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    bat '''
                        echo "Autenticando com o Google Cloud..."
                        gcloud auth activate-service-account --key-file="%GOOGLE_APPLICATION_CREDENTIALS%"
                        gcloud config set project %FIREBASE_PROJECT_ID%

                        echo "Enviando APKs para o Firebase Test Lab..."
                        gcloud firebase test android run ^
                          --type instrumentation ^
                          --app android/app/build/outputs/apk/debug/app-debug.apk ^
                          --test android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk ^
                          --device model=pixel6,version=34,locale=pt_BR,orientation=portrait ^
                          --timeout 15m
                    '''
                }
            }
        }

        stage('Deploy to Firebase App Distribution') {
            steps {
                withCredentials([file(credentialsId: SERVICE_ACCOUNT_CREDENTIALS_ID, variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    bat '''
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
            echo "Pipeline finalizado. Limpando..."
            cleanWs()
            script {
                try {
                    bat "docker rmi ${IMAGE_NAME}"
                } catch (err) {
                    echo "Imagem ${IMAGE_NAME} não encontrada ou não pôde ser removida."
                }
            }
        }
    }
}