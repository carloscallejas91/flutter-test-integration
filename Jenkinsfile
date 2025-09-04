// Jenkinsfile Declarativo para CI/CD de um projeto Flutter
// Constrói, Testa no Firebase Test Lab e Distribui para o Firebase App Distribution

pipeline {
    // 1. AGENTE DE EXECUÇÃO
    // Define que o agente principal será qualquer um disponível (neste caso, o Windows).
    agent any

    // 2. VARIÁVEIS DE AMBIENTE
    // Centraliza as configurações do projeto.
    environment {
        GCP_PROJECT_ID = 'test-integration-app-4e52e'
        FIREBASE_APP_ID = '1:424599350937:android:5c7fd412fffd453bcb5208'
        GCP_CREDENTIALS_ID = 'firebase-service-account-key'
        FIREBASE_TESTER_GROUP = 'qa-team'
        DOCKER_IMAGE_NAME = 'flutter-ci-agent:latest'
    }

    // 3. ESTÁGIOS DO PIPELINE
    stages {
        // Estágio de Checkout: Baixa o código-fonte.
        stage('Checkout') {
            steps {
                script {
                    echo "Baixando o código-fonte..."
                    checkout scm
                }
            }
        }

        // Estágio para construir a imagem Docker uma única vez.
        stage('Build Docker Image') {
            steps {
                script {
                    echo "Construindo a imagem Docker ${DOCKER_IMAGE_NAME}..."
                    docker.build(DOCKER_IMAGE_NAME)
                }
            }
        }

        // Estágio de Build e Teste: Compila os APKs e executa os testes de integração.
        stage('Build & Test') {
            steps {
                script {
                    // Injeta a credencial como um arquivo no host.
                    withCredentials([file(credentialsId: "${GCP_CREDENTIALS_ID}", variable: 'GCP_KEY_FILE')]) {
                        // CORREÇÃO: Altera o dispositivo para Pixel 5 (redfin) com API 30, conforme a lista fornecida.
                        bat """docker run --rm --pull=never -v "%WORKSPACE%:/app" -v "%GCP_KEY_FILE%:/key.json" -w /app ${DOCKER_IMAGE_NAME} sh -c "echo \\"==> Autenticando com Google Cloud...\\" && gcloud auth activate-service-account --key-file=/key.json && gcloud config set project ${GCP_PROJECT_ID} && echo \\"==> Preparando ambiente Flutter...\\" && flutter pub get && flutter clean && echo \\"==> Construindo APKs...\\" && flutter build apk --debug && flutter build apk -t lib/main.dart --debug && echo \\"==> Executando testes no Firebase Test Lab...\\" && gcloud firebase test android run --type instrumentation --app build/app/outputs/apk/debug/app-debug.apk --test build/app/outputs/apk/debug/app-debug.apk --device model=redfin,version=30,locale=pt_BR,orientation=portrait --timeout 15m" """
                    }
                }
            }
        }

        // Estágio de Deploy: Distribui o APK para a equipe de QA.
        stage('Deploy to QA') {
            steps {
                script {
                    bat """docker run --rm --pull=never -v "%WORKSPACE%:/app" -w /app ${DOCKER_IMAGE_NAME} sh -c "echo \\"==> Distribuindo APK para o grupo ${FIREBASE_TESTER_GROUP}...\\" && firebase appdistribution:distribute build/app/outputs/apk/debug/app-debug.apk --app ${FIREBASE_APP_ID} --release-notes \\"Build ${env.BUILD_NUMBER} - Nova versão para testes.\\" --groups \\"${FIREBASE_TESTER_GROUP}\\"" """
                }
            }
        }
    }

    // 4. AÇÕES PÓS-EXECUÇÃO
    post {
        always {
            script {
                echo "Limpando o workspace..."
                cleanWs()
            }
        }
    }
}

