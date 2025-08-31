pipeline {
    agent any

    environment {
        // Define environment variables
        DOCKER_IMAGE = "yashasdocker/boardgame-app:${env.BUILD_ID}"
        REGISTRY_CREDENTIALS = credentials('dockerhub-cred') // ID of credentials in Jenkins
        KUBECONFIG = credentials('kubeconfig') // ID of the kubeconfig file in Jenkins
    }

    stages {
        stage('SCM Checkout') {
            steps {
                checkout scm // Checks out the code from GitHub
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
                    // Set the kubeconfig context
                    withEnv(["KUBECONFIG=${KUBECONFIG}"]) {
                        // Replace the image name in the deployment.yaml and apply it
                        sh """
                            sed -i 's|image: .*|image: ${DOCKER_IMAGE}|' k8s/deployment.yaml
                            kubectl apply -f k8s/
                        """
                    }
                }
            }
        }
    }

    post {
        failure {
            echo 'Pipeline failed! Check the logs.'
            // You can add Slack/Email notifications here
        }
        success {
            echo 'Pipeline succeeded! Application is deployed.'
            sh "kubectl get svc boardgame-service" // Get the service URL
        }
    }
}
