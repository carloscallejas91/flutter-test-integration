pipeline {
    agent any

    environment {
        GCP_PROJECT_ID = 'test-integration-app-4e52e'
        FIREBASE_APP_ID = '1:424599350937:android:5c7fd412fffd453bcb5208'
        GCP_CREDENTIALS_ID = 'firebase-service-account-key'
        FIREBASE_TESTER_GROUP = 'qa-team'
        DOCKER_IMAGE_NAME = 'flutter-ci-agent:latest'
    }

    stages {
        stage('Checkout') {
            steps {
                echo "Baixando o código-fonte..."
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Construindo a imagem Docker ${DOCKER_IMAGE_NAME}..."
                script {
                    docker.build(DOCKER_IMAGE_NAME)
                }
            }
        }

        stage('Build & Test') {
            steps {
                withCredentials([file(credentialsId: "${GCP_CREDENTIALS_ID}", variable: 'GCP_KEY_FILE')]) {
                    bat """
                        docker run --rm --pull=never ^
                          -v "${env.WORKSPACE}:/app" ^
                          -v "%GCP_KEY_FILE%:/key.json" ^
                          -w /app ${DOCKER_IMAGE_NAME} sh -c "set -ex && \
                            echo '==> Autenticando com Google Cloud...' && \
                            gcloud auth activate-service-account --key-file=/key.json && \
                            gcloud config set project ${GCP_PROJECT_ID} && \
                            echo '==> Preparando ambiente Flutter...' && \
                            flutter pub get && \
                            flutter clean && \
                            echo '==> Construindo APKs...' && \
                            flutter build apk --debug && \
                            flutter build apk -t lib/main.dart --debug && \
                            echo '==> Executando testes no Firebase Test Lab...' && \
                            gcloud firebase test android run \
                              --type instrumentation \
                              --app build/app/outputs/apk/debug/app-debug.apk \
                              --test build/app/outputs/apk/debug/app-debug.apk \
                              --device model=Pixel6,version=31,locale=pt_BR,orientation=portrait \
                              --timeout 15m"
                    """
                }
            }
        }

        stage('Deploy to QA') {
            steps {
                bat """
                    docker run --rm --pull=never ^
                      -v "${env.WORKSPACE}:/app" ^
                      -w /app ${DOCKER_IMAGE_NAME} sh -c "set -ex && \
                        echo '==> Distribuindo APK para o grupo ${FIREBASE_TESTER_GROUP}...' && \
                        firebase appdistribution:distribute build/app/outputs/apk/debug/app-debug.apk \
                          --app ${FIREBASE_APP_ID} \
                          --release-notes 'Build ${env.BUILD_NUMBER} - Nova versão para testes.' \
                          --groups '${FIREBASE_TESTER_GROUP}'"
                """
            }
        }
    }

    post {
        always {
            echo "Limpando o workspace..."
            cleanWs()
        }
    }
}
