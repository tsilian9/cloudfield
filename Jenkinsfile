// ═══════════════════════════════════════════════════════════════
// CloudField CI/CD Pipeline
// Trigger: git push → Jenkins build → Docker Hub push → ArgoCD deploy
// ═══════════════════════════════════════════════════════════════
pipeline {
    agent any

    environment {
        DOCKER_HUB_USER = 'tsilian9'
        IMAGE_NAME      = 'cloudfield-nodered'
        IMAGE_FULL      = "${DOCKER_HUB_USER}/${IMAGE_NAME}"
        GITHUB_REPO     = 'https://github.com/tsilian9/cloudfield.git'
    }

    stages {

        // ── Stage 1: Checkout ──────────────────────────────────
        stage('Checkout') {
            steps {
                git branch: 'main', url: "${GITHUB_REPO}"
            }
        }

        // ── Stage 2: Build Docker Image ────────────────────────
        stage('Build Image') {
            steps {
                script {
                    def tag = "${BUILD_NUMBER}"
                    sh "docker build -t ${IMAGE_FULL}:${tag} -t ${IMAGE_FULL}:latest ."
                }
            }
        }

        // ── Stage 3: Push to Docker Hub ────────────────────────
        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
                        docker push ${IMAGE_FULL}:${BUILD_NUMBER}
                        docker push ${IMAGE_FULL}:latest
                        docker logout
                    """
                }
            }
        }

        // ── Stage 4: Update nodered.yaml με νέο image tag ──────
        stage('Update K8s Manifest') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'github-credentials',
                    usernameVariable: 'GIT_USER',
                    passwordVariable: 'GIT_PASS'
                )]) {
                    sh """
                        # Ενημέρωσε το image tag στο nodered.yaml
                        sed -i 's|image: ${IMAGE_FULL}:.*|image: ${IMAGE_FULL}:${BUILD_NUMBER}|g' nodered.yaml

                        # Git commit & push
                        git config user.email "jenkins@cloudfield.local"
                        git config user.name "Jenkins CI"
                        git add nodered.yaml
                        git commit -m "CI: Update nodered image to build #${BUILD_NUMBER}" || echo "No changes to commit"
                        git push https://${GIT_USER}:${GIT_PASS}@github.com/tsilian9/cloudfield.git main
                    """
                }
            }
        }
    }

    // ── Post Actions ───────────────────────────────────────────
    post {
        success {
            echo "✅ Build #${BUILD_NUMBER} επιτυχής! ArgoCD θα κάνει auto-deploy σε λίγα λεπτά."
        }
        failure {
            echo "❌ Build #${BUILD_NUMBER} απέτυχε! Έλεγξε τα logs."
        }
        always {
            // Καθαρισμός local Docker images για εξοικονόμηση χώρου
            sh "docker rmi ${IMAGE_FULL}:${BUILD_NUMBER} || true"
        }
    }
}
