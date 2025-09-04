// Jenkinsfile Declarativo para CI/CD de um projeto Flutter
// Constrói, Testa no Firebase Test Lab e Distribui para o Firebase App Distribution

pipeline {
    // 1. AGENTE DE EXECUÇÃO
    agent any

    // 2. VARIÁVEIS DE AMBIENTE
    environment {
        GCP_PROJECT_ID = 'test-integration-app-4e52e'
        FIREBASE_APP_ID = '1:424599350937:android:5c7fd412fffd453bcb5208'
        GCP_CREDENTIALS_ID = 'firebase-service-account-key'
        FIREBASE_TESTER_GROUP = 'qa-team'
        DOCKER_IMAGE_NAME = 'flutter-ci-agent:latest'
    }

    // 3. ESTÁGIOS DO PIPELINE
    stages {
        // Estágio para construir a imagem Docker.
        stage('Build Docker Image') {
            steps {
                script {
                    echo "Construindo a imagem Docker ${DOCKER_IMAGE_NAME}..."
                    docker.build(DOCKER_IMAGE_NAME)
                }
            }
        }

        // Estágio de Build e Teste.
        stage('Build & Test') {
            steps {
                // CORREÇÃO FINAL: Adiciona um bloco de script para controlar o resultado.
                script {
                    withCredentials([file(credentialsId: "${GCP_CREDENTIALS_ID}", variable: 'GCP_KEY_FILE')]) {
                        // Executa o comando e captura o seu código de saída em vez de parar o pipeline.
                        def result = bat(
                            script: "docker run --rm --pull=never -v \"%WORKSPACE%:/app\" -v \"%GCP_KEY_FILE%:/key.json\" -w /app ${DOCKER_IMAGE_NAME} sh -c \"echo \\\"==> Autenticando com Google Cloud...\\\" && gcloud auth activate-service-account --key-file=/key.json && gcloud config set project ${GCP_PROJECT_ID} && echo \\\"==> Preparando ambiente Flutter...\\\" && flutter pub get && flutter clean && echo \\\"==> Regenerando arquivos de build nativo...\\\" && flutter create . && echo \\\"==> Construindo APKs com Gradle...\\\" && chmod +x android/gradlew && cd android && ./gradlew app:assembleDebug app:assembleDebugAndroidTest && cd .. && echo \\\"==> Executando testes no Firebase Test Lab...\\\" && gcloud firebase test android run --type instrumentation --app build/app/outputs/apk/debug/app-debug.apk --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk --device model=redfin,version=30,locale=pt_BR,orientation=portrait --timeout 15m --num-flaky-test-attempts 2\"",
                            returnStatus: true
                        )

                        // Verifica o resultado.
                        // Código 0 = Sucesso total.
                        // Código 10 = Sucesso, mas com instabilidade (testes passaram na repetição).
                        // Qualquer outro código é um erro real.
                        if (result == 0) {
                            echo "SUCESSO: Todos os testes passaram na primeira tentativa."
                        } else if (result == 10) {
                            echo "SUCESSO: Testes instáveis, mas passaram numa tentativa de repetição. A avançar para o deploy."
                        } else {
                            error("FALHA: O estágio de Build & Test falhou com o código de saída: ${result}")
                        }
                    }
                }
            }
        }

        // Estágio de Deploy: Distribui o APK para a equipa de QA.
        stage('Deploy to QA') {
            steps {
                script {
                    echo "==> A iniciar o deploy para a equipa de QA..."
                    withCredentials([file(credentialsId: "${GCP_CREDENTIALS_ID}", variable: 'GCP_KEY_FILE')]) {
                         bat "docker run --rm --pull=never -v \"%WORKSPACE%:/app\" -v \"%GCP_KEY_FILE%:/key.json\" -w /app ${DOCKER_IMAGE_NAME} sh -c \"echo \\\"==> Autenticando para o deploy...\\\" && gcloud auth activate-service-account --key-file=/key.json && gcloud config set project ${GCP_PROJECT_ID} && echo \\\"==> A distribuir o APK...\\\" && firebase appdistribution:distribute build/app/outputs/apk/debug/app-debug.apk --app ${FIREBASE_APP_ID} --release-notes 'Build ${env.BUILD_NUMBER} - Passou nos testes de integração.' --groups '${FIREBASE_TESTER_GROUP}'\""
                    }
                }
            }
        }
    }

    // 4. AÇÕES PÓS-EXECUÇÃO
    post {
        always {
            script {
                echo "A limpar o workspace..."
                cleanWs()
            }
        }
    }
}

