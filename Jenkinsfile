// Jenkinsfile (Declarative Pipeline)
// Este pipeline automatiza o build, teste e deploy de um app Flutter.

// Define o agente do pipeline. Usamos 'dockerfile true' para que o Jenkins
// construa uma imagem a partir do Dockerfile na raiz do projeto e execute
// os estágios dentro de um container dessa imagem.
pipeline {
    agent { dockerfile true }

//     environment {
//         FIREBASE_PROJECT_ID = "test-integration-app-4e52e"
//         SERVICE_ACCOUNT_CREDENTIALS_ID = "firebase-service-account-key"
//         FIREBASE_APP_ID="1:424599350937:android:5c7fd412fffd453bcb5208"
//         IMAGE_NAME = "test-integration-app/flutter-builder:${env.BUILD_NUMBER}"
//         BUILD_CONTAINER_NAME = "apk-builder-${env.BUILD_NUMBER}"
//     }

    // Variáveis de ambiente globais para o pipeline.
    // Substitua os valores 'your-gcp-project-id' e 'your-firebase-app-id'.
    environment {
        // ID do seu projeto no Google Cloud.
        GCP_PROJECT_ID = 'test-integration-app-4e52e'
        // ID do seu App no Firebase (encontrado nas configurações do projeto).
        FIREBASE_APP_ID = '1:424599350937:android:5c7fd412fffd453bcb5208'
        // ID da credencial criada no Jenkins para a chave da Conta de Serviço.
        GCP_CREDENTIALS_ID = 'firebase-service-account-key'
    }

    stages {
        // Estágio 1: Checkout
        // Clona o repositório do código-fonte.
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        // Estágio 2: Build & Test
        // Este estágio compila o app e os testes, e os executa no Firebase Test Lab.
        stage('Build & Test on Firebase Test Lab') {
            steps {
                // 'withCredentials' injeta o arquivo secreto (chave JSON) em uma variável.
                // O Jenkins gerencia a segurança deste arquivo.
                withCredentials([file(credentialsId: GCP_CREDENTIALS_ID, variable: 'GCP_KEY_FILE')]) {
                    script {
                        try {
                            echo "Authenticating with Google Cloud..."
                            // Autentica no gcloud usando a conta de serviço.
                            sh "gcloud auth activate-service-account --key-file=${GCP_KEY_FILE}"
                            // Define o projeto alvo para os comandos gcloud.
                            sh "gcloud config set project ${GCP_PROJECT_ID}"

                            echo "Installing dependencies..."
                            // Baixa as dependências do projeto Flutter.
                            sh "flutter pub get"

                            echo "Building Android APKs (App and Test)..."
                            // O comando 'build apk' gera tanto o APK do app quanto o de teste.
                            // app-debug.apk (app)
                            // app-debug-androidTest.apk (testes)
                            sh "flutter build apk --debug"

                            echo "Running Integration Tests on Firebase Test Lab..."
                            // Envia os APKs para o Test Lab.
                            // --type instrumentation: especifica que são testes de instrumentação.
                            // --app: caminho para o APK do app.
                            // --test: caminho para o APK dos testes.
                            // --device: especifica o dispositivo virtual para o teste.
                            //   model=Pixel6,version=33 -> Android 13 em um Pixel 6.
                            sh """
                                gcloud firebase test android run \\
                                    --type instrumentation \\
                                    --app build/app/outputs/apk/debug/app-debug.apk \\
                                    --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk \\
                                    --device model=Pixel6,version=33,locale=pt_BR,orientation=portrait
                            """
                        } catch (e) {
                            echo "Error during Build & Test stage: ${e.message}"
                            currentBuild.result = 'FAILURE'
                            error("Pipeline failed in Build & Test stage.")
                        }
                    }
                }
            }
        }

        // Estágio 3: Deploy to QA
        // Se o estágio anterior for bem-sucedido, este distribui o APK para o time de QA.
        stage('Deploy to Firebase App Distribution') {
            steps {
                withCredentials([file(credentialsId: GCP_CREDENTIALS_ID, variable: 'GCP_KEY_FILE')]) {
                    script {
                        try {
                            echo "Authenticating with Google Cloud..."
                            sh "gcloud auth activate-service-account --key-file=${GCP_KEY_FILE}"
                            sh "gcloud config set project ${GCP_PROJECT_ID}"

                            echo "Distributing APK to QA team..."
                            // Distribui o APK para um grupo de testadores no Firebase.
                            // --app: ID do app no Firebase.
                            // --release-notes: Mensagem para os testadores.
                            // --groups: Nome do grupo de testadores (crie este grupo no console do Firebase).
                            sh """
                                gcloud firebase app-distribution distribute build/app/outputs/apk/debug/app-debug.apk \\
                                    --app ${FIREBASE_APP_ID} \\
                                    --release-notes "Build #${env.BUILD_NUMBER} - Testes de integração aprovados." \\
                                    --groups "qa-team"
                            """
                        } catch (e) {
                            echo "Error during Deploy stage: ${e.message}"
                            currentBuild.result = 'FAILURE'
                            error("Pipeline failed in Deploy stage.")
                        }
                    }
                }
            }
        }
    }

    // Bloco Post-Execution: executado no final do pipeline, independentemente do resultado.
    post {
        always {
            // Limpa o workspace do Jenkins para economizar espaço em disco.
            echo "Cleaning up workspace..."
            cleanWs()
        }
    }
}

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

