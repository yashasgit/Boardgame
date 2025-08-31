pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "yashasdocker/boardgame-app:${env.BUILD_ID}"
        REGISTRY_CREDENTIALS = credentials('dockerhub-cred')
        K8S_SERVER = 'https://172.31.34.168:6443'
        K8S_TOKEN = credentials('k8s-token')
    }

    stages {
        stage('SCM Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    dockerImage = docker.build("${DOCKER_IMAGE}")
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('', REGISTRY_CREDENTIALS) {
                        dockerImage.push()
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sh """
                        kubectl config set-cluster my-cluster --server=${K8S_SERVER} --insecure-skip-tls-verify=true
                        kubectl config set-credentials jenkins --token=${K8S_TOKEN}
                        kubectl config set-context my-context --cluster=my-cluster --user=jenkins
                        kubectl config use-context my-context
                        sed -i 's|image: .*|image: ${DOCKER_IMAGE}|' k8s/deployment-service.yaml
                        kubectl apply -f k8s/deployment-service.yaml
                    """
                }
            }
        }
    }

    post {
        failure {
            echo 'Pipeline failed! Check the logs.'
        }
        success {
            echo 'Pipeline succeeded! Application is deployed.'
        }
    }
}
