pipeline {
  agent { label '________ (jenkins-agent-label)' }

  options {
    timeout(time: 60, unit: 'MINUTES')
    timestamps()
    disableConcurrentBuilds()
  }

  parameters {
    choice(name: 'ENV', choices: ['dev', 'staging'], description: 'Deployment environment (production requires manual change)')
    booleanParam(name: 'RUN_SONAR', defaultValue: true)
    booleanParam(name: 'RUN_OWASP', defaultValue: true)
    booleanParam(name: 'RUN_TRIVY', defaultValue: true)
    booleanParam(name: 'RUN_TESTS', defaultValue: true)
    booleanParam(name: 'RUN_DEPLOY', defaultValue: false)
  }

  environment {
    PROJECT_NAME = "mern-frontend"
    NODE_ENV = "production"
    SONAR_PROJECT_KEY = "________ (SonarQube project key)"
    OWASP_DATA_DIR = "________ (OWASP Dependency-Check data directory)"
    OWASP_CVSS_THRESHOLD = "________ (CVSS threshold)"
    TRIVY_CACHE_DIR = "________ (Trivy cache directory)"
    DOCKER_IMAGE = "________ (Docker image name/tag)"
    AWS_REGION = "________ (AWS region)"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Prepare Environment') {
      steps {
        sh 'node -v'
        sh 'npm -v'
        sh 'mkdir -p reports'
      }
    }

    stage('Install Dependencies') {
      steps {
        sh '''
          if [ -f package-lock.json ]; then
            npm ci --no-fund --no-audit
          else
            npm install --no-fund --no-audit
          fi
        '''
      }
    }

    stage('SonarQube Scan') {
      when { expression { params.RUN_SONAR } }
      steps {
        withCredentials([string(credentialsId: '________ (SonarQube token credential ID)', variable: 'SONAR_TOKEN')]) {
          withSonarQubeEnv('________ (SonarQube server name)') {
            sh '''
              sonar-scanner \
                -Dsonar.projectKey=$SONAR_PROJECT_KEY \
                -Dsonar.sources=src \
                -Dsonar.host.url=$SONAR_HOST_URL \
                -Dsonar.login=$SONAR_TOKEN
            '''
          }
        }
      }
    }

    stage('SonarQube Quality Gate') {
      when { expression { params.RUN_SONAR } }
      steps {
        timeout(time: 10, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }

    stage('OWASP Dependency Check') {
      when { expression { params.RUN_OWASP } }
      steps {
        sh '''
          dependency-check.sh \
            --format "HTML" --format "XML" \
            --project "$PROJECT_NAME" \
            --out reports/dependency-check \
            --scan . \
            --data "$OWASP_DATA_DIR" \
            --failOnCVSS "$OWASP_CVSS_THRESHOLD"
        '''
        archiveArtifacts artifacts: 'reports/dependency-check/**/*', allowEmptyArchive: true
      }
    }

    stage('Trivy Filesystem Scan') {
      when { expression { params.RUN_TRIVY } }
      steps {
        sh '''
          trivy fs \
            --cache-dir "$TRIVY_CACHE_DIR" \
            --format table \
            --output reports/trivy-fs.txt \
            --severity HIGH,CRITICAL \
            --exit-code 1 .
        '''
        archiveArtifacts artifacts: 'reports/trivy-fs.txt', allowEmptyArchive: true
      }
    }

    stage('Build') {
      steps {
        sh 'npm run build --if-present'
      }
    }

    stage('Test') {
      when { expression { params.RUN_TESTS } }
      steps {
        sh 'npm run test --if-present'
      }
    }

    stage('Docker Build & Push') {
      when { expression { fileExists("Dockerfile") && params.RUN_DEPLOY } }
      steps {
        sh '''
          docker build -t "$DOCKER_IMAGE" .
          # TODO: docker login to target registry using Jenkins credentials before push
          # TODO: uncomment next line after configuring registry access
          # docker push "$DOCKER_IMAGE"
        '''
      }
    }

    stage('Trivy Image Scan') {
      when { expression { fileExists("Dockerfile") && params.RUN_DEPLOY && params.RUN_TRIVY } }
      steps {
        sh '''
          trivy image \
            --cache-dir "$TRIVY_CACHE_DIR" \
            --format table \
            --output reports/trivy-image.txt \
            --severity HIGH,CRITICAL \
            --exit-code 1 "$DOCKER_IMAGE"
        '''
        archiveArtifacts artifacts: 'reports/trivy-image.txt', allowEmptyArchive: true
      }
    }

    stage('Deploy (Safe Mode)') {
      when { expression { params.RUN_DEPLOY } }
      steps {
        input message: 'Approve deployment?', ok: 'Proceed'
        sh '''
          # TODO: configure AWS credentials in Jenkins (e.g., withCredentials) and export AWS_DEFAULT_REGION="$AWS_REGION"
          # TODO: set Kubernetes context or EKS cluster: ________ (Kubernetes context or EKS cluster name)
          # TODO: configure Terraform backend bucket: ________ (Terraform backend S3 bucket)
          # SAFE MODE: run plan-only; apply must be gated by an additional manual approval
          # Example (plan-only):
          # terraform init -backend-config="bucket=________ (Terraform backend S3 bucket)"
          # terraform plan
          # kubectl/helm apply steps must remain behind a manual approval gate
        '''
      }
    }

    stage('Notify') {
      steps {
        sh '''
          # TODO: send notification via preferred provider
          # Example: curl -X POST ________ (Notification endpoint) -d 'channel=________ (notification channel or recipient)&status=${currentBuild.currentResult}'
        '''
      }
    }
  }

  post {
    success {
      echo 'Pipeline completed successfully.'
    }
    failure {
      echo 'Pipeline failed. Check logs and artifacts.'
    }
    always {
      cleanWs deleteDirs: true, notFailBuild: true
    }
  }
}


// ==============================
// REQUIRED VALUES TO FILL IN JENKINS _ (jenkins-agent-label)
// _ (SonarQube server name)
// _ (SonarQube token credential ID)
// _ (SonarQube project key)
// _ (OWASP Dependency-Check data directory)
// _ (CVSS threshold)
// _ (Trivy cache directory)
// _ (Docker image name/tag)
// _ (AWS credentials ID)
// _ (AWS region)
// _ (Kubernetes context / EKS cluster)
// _ (Terraform backend bucket)
// _ (Notification endpoint)
// _ (notification channel or recipient)