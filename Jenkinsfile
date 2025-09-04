pipeline {
    // Definimos um agente genérico no topo.
    agent any

    environment {
        FIREBASE_PROJECT_ID = "test-integration-app-4e52e"
        SERVICE_ACCOUNT_CREDENTIALS_ID = "firebase-service-account-key"
        FIREBASE_APP_ID="1:424599350937:android:5c7fd412fffd453bcb5208"
        IMAGE_NAME = "test-integration-app/flutter-builder:${env.BUILD_NUMBER}"
        BUILD_CONTAINER_NAME = "apk-builder-${env.BUILD_NUMBER}"
    }

    stages {
        stage('Build Image With App Code') {
            steps {
                // Etapa 1: Baixa o código e constrói a imagem com o código dentro.
                checkout scm
                script {
                    echo "Construindo imagem de build com o código do app..."
                    docker.build(IMAGE_NAME, '.')
                }
            }
        }

        stage('Build & Extract APKs') {
            steps {
                // (CORRIGIDO) Usamos 'bat' para ter controle total e evitar os erros de caminho.
                bat """
                    echo "Passo 1: Construindo APKs dentro de um container temporário..."
                    docker run --name ${BUILD_CONTAINER_NAME} ${IMAGE_NAME} sh -c "cd android && chmod +x ./gradlew && ./gradlew clean && ./gradlew app:assembleDebug assembleDebugAndroidTest"

                    echo "Passo 2: Criando diretórios de saída no workspace do Jenkins..."
                    mkdir android\\app\\build\\outputs\\apk\\debug
                    mkdir android\\app\\build\\outputs\\apk\\androidTest\\debug

                    echo "Passo 3: Copiando APKs do container para o workspace..."
                    docker cp ${BUILD_CONTAINER_NAME}:/home/flutterdev/app/android/app/build/outputs/apk/debug/app-debug.apk android/app/build/outputs/apk/debug/app-debug.apk
                    docker cp ${BUILD_CONTAINER_NAME}:/home/flutterdev/app/android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk
                """
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
            // (CORRIGIDO) Envolvemos a limpeza em um bloco 'node' para garantir o contexto.
            node {
                echo "Pipeline finalizado. Limpando..."
                // Limpa o container temporário, caso ele ainda exista por algum erro
                script {
                    bat "docker rm -f ${BUILD_CONTAINER_NAME} || true"
                }
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
}

