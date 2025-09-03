pipeline {
    agent any

    environment {
        // ID do seu projeto no Google Cloud/Firebase
        FIREBASE_PROJECT_ID = "test-integration-app-4e52e"
        // ID da credencial que você criou no Jenkins no Passo 2
        SERVICE_ACCOUNT_CREDENTIALS_ID = "firebase-service-account-key"
        // Nome da imagem Docker a ser construída
        IMAGE_NAME = "test-integration-app/flutter-builder:${env.BUILD_NUMBER}"
        // ID do seu App no Firebase para o App Distribution (encontre em Configurações do Projeto no Firebase)
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
                    // ==================== CORREÇÃO DEFINITIVA ====================
                    // Usamos o comando 'docker run' explícito para ter controle total sobre os argumentos.
                    // Isso evita que o plugin do Jenkins adicione um caminho de Windows inválido.
                    sh """
                        docker run --rm --workdir /home/flutterdev/app \
                            -v "${workspace}":/home/flutterdev/app \
                            ${IMAGE_NAME} \
                            sh -c "cd android && ./gradlew clean && ./gradlew app:assembleDebug assembleDebugAndroidTest"
                    """
                }
            }
        }

        // Os estágios seguintes permanecem os mesmos...
        stage('Run Tests on Firebase Test Lab') {
            steps {
                withCredentials([file(credentialsId: SERVICE_ACCOUNT_CREDENTIALS_ID, variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh '''
                        echo "Autenticando com o Google Cloud..."
                        gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
                        gcloud config set project ${FIREBASE_PROJECT_ID}

                        echo "Enviando APKs para o Firebase Test Lab..."
                        gcloud firebase test android run \
                          --type instrumentation \
                          --app android/app/build/outputs/apk/debug/app-debug.apk \
                          --test android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
                          --device model=pixel6,version=34,locale=pt_BR,orientation=portrait \
                          --timeout 15m
                    '''
                }
            }
        }

        // ... (resto dos estágios 'Deploy' e 'post' permanecem iguais)
    }

    post {
        always {
            echo "Pipeline finalizado. Limpando..."
            cleanWs()
            script {
                try {
                    sh "docker rmi ${IMAGE_NAME}"
                } catch (err) {
                    echo "Imagem ${IMAGE_NAME} não encontrada ou não pôde ser removida."
                }
            }
        }
    }
}