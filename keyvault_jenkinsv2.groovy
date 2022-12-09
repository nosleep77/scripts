pipeline {
  environment {
    MY_CRED = credentials('azure-sp')
  }
  stages {
    stage('Fetch Secret') {
      steps {
          script {
            def azlogin = sh script: 'az login --service-principal -u $MY_CRED_CLIENT_ID -p $MY_CRED_CLIENT_SECRET -t $MY_CRED_TENANT_ID', returnStdout: true
            println "Agent info within script: ${azlogin}"
            def secret = sh script: 'az keyvault secret show --name "api" --vault-name "jenkins-keyvault-azure" --query value -o tsv', returnStdout: true
            println "Azure keyvault secret: ${secret}"
            env.secret = secret
          }
      }
    }
    stage('Run Script') {
      steps {
        container('azcli') {
          script {
            # download the script as script.sh
            sh 'curl -s -o script.sh https://raw.githubusercontent.com/Ryder05/AwsomeProject/main/script.sh && chmod u+x script.sh '
          }
          sh ""
          " ./script.sh ${env.secret} "
          ""

        }
      }
    }
  }
}
