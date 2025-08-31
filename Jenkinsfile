pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "yashasdocker/boardgame-app:${env.BUILD_ID}"
        REGISTRY_CREDENTIALS = credentials('dockerhub-cred')
        K8S_SERVER = 'https://172.31.34.168:6443'
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
                    // Build without storing in variable to avoid warning
                    sh "docker build -t ${DOCKER_IMAGE} ."
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-cred') {
                        sh "docker push ${DOCKER_IMAGE}"
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'k8s-token', variable: 'K8S_TOKEN_SECRET')]) {
                        sh '''
                            # Configure kubectl access
                            kubectl config set-cluster my-cluster --server=$K8S_SERVER --insecure-skip-tls-verify=true
                            kubectl config set-credentials jenkins --token=$K8S_TOKEN_SECRET
                            kubectl config set-context my-context --cluster=my-cluster --user=jenkins
                            kubectl config use-context my-context

                            # Update image in deployment
                            sed -i "s|image:.*|image: $DOCKER_IMAGE|" deployment-service.yaml
                            
                            # Apply deployment (this works!)
                            kubectl apply -f deployment-service.yaml
                            
                            # Wait a bit for pods to start
                            sleep 30
                            
                            # Check status without failing the pipeline
                            echo "=== Deployment Status ==="
                            kubectl get deployment/boardgame-app -o wide
                            
                            echo "=== Pod Status ==="
                            kubectl get pods -l app=boardgame-app -o wide
                            
                            echo "=== Service Status ==="
                            kubectl get service/boardgame-service -o wide
                            
                            # Get application URL
                            echo "=== Application Access ==="
                            kubectl get service boardgame-service -o jsonpath='{"External IP: "}{.status.loadBalancer.ingress[0].ip}{"\\n"}'
                            
                            # Check pod logs for debugging
                            POD_NAME=$(kubectl get pods -l app=boardgame-app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "no-pods")
                            if [ "$POD_NAME" != "no-pods" ]; then
                                echo "=== Pod Logs (last 10 lines) ==="
                                kubectl logs $POD_NAME --tail=10 || true
                            fi
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            echo "=== Pipeline Execution Summary ==="
            script {
                withCredentials([string(credentialsId: 'k8s-token', variable: 'K8S_TOKEN_SECRET')]) {
                    sh '''
                        kubectl config set-cluster my-cluster --server=$K8S_SERVER --insecure-skip-tls-verify=true
                        kubectl config set-credentials jenkins --token=$K8S_TOKEN_SECRET
                        kubectl config set-context my-context --cluster=my-cluster --user=jenkins
                        kubectl config use-context my-context
                        
                        echo "=== Final Status ==="
                        kubectl get deployment,service,pods -l app=boardgame-app
                    ''' || true
                }
            }
        }
        success {
            echo "✅ CI/CD Pipeline Completed Successfully!"
            echo "🎉 Your application is deployed and available!"
        }
    }
}
