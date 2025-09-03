pipeline {
    agent any

    environment {
        FIREBASE_PROJECT_ID = "test-integration-app-4e52e"
        SERVICE_ACCOUNT_CREDENTIALS_ID = "firebase-service-account-key"
        IMAGE_NAME = "test-integration-app/flutter-builder:${env.BUILD_NUMBER}"
        FIREBASE_APP_ID="1:424599350937:android:5c7fd412fffd453bcb5208"
    }

    stages {
        stage('Build Image With App Code') {
            steps {
                // Nesta etapa, nós fazemos o checkout E construímos a imagem.
                // O comando COPY no Dockerfile irá copiar o código para dentro da imagem.
                checkout scm
                script {
                    echo "Construindo imagem de build já com o código do app..."
                    docker.build(IMAGE_NAME, '.')
                }
            }
        }

        stage('Build APKs inside Container') {
            steps {
                script {
                    echo "Construindo APKs..."
                    // ==================== CORREÇÃO APLICADA AQUI ====================
                    // Removemos a flag de volume '-v'. O container agora usa sua cópia interna do código.
                    bat """
                        docker run --rm --workdir /home/flutterdev/app ^
                            ${IMAGE_NAME} ^
                            sh -c "cd android && chmod +x ./gradlew && ./gradlew clean && ./gradlew app:assembleDebug assembleDebugAndroidTest"
                    """
                }
            }
        }

        // Os estágios seguintes precisam dos APKs, que ainda não estão no workspace do Jenkins.
        // Precisamos copiá-los do container para o host.
        stage('Copy APKs from Container') {
            steps {
                script {
                    echo "Copiando APKs do container para o workspace do Jenkins..."
                    // Primeiro, precisamos descobrir o ID do container recém-construído.
                    // Uma maneira mais simples é construir os APKs e depois copiá-los.
                    // Vamos refatorar o estágio anterior para facilitar isso.

                    // A melhor abordagem é executar o build e o copy em um único passo.
                    // Vamos criar um container, copiar os resultados e depois removê-lo.
                    bat """
                        docker create --name temp_builder_${BUILD_NUMBER} ${IMAGE_NAME}
                        docker cp temp_builder_${BUILD_NUMBER}:/home/flutterdev/app/android/app/build/outputs/apk/debug/app-debug.apk android/app/build/outputs/apk/debug/app-debug.apk
                        docker cp temp_builder_${BUILD_NUMBER}:/home/flutterdev/app/android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk
                        docker rm temp_builder_${BUILD_NUMBER}
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