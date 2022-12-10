pipeline {
    agent any
  stages {
    stage('Run Script') {
      steps {
          script {
            // env.secret=FetchSecret(String secretName,String vaultName)
            env.secret=FetchSecret("jenkins","jenkinskeyvault1")
            sh 'curl -s -o script.sh https://raw.githubusercontent.com/Ryder05/AwsomeProject/main/script.sh && chmod u+x script.sh '
            sh """ ./script.sh ${env.secret} """ }
            }
        }
    }
}


String FetchSecret(String secretName,String vaultName) {
    withCredentials([azureServicePrincipal(credentialsId: 'azure-sp')]) {
        def secret = sh script:"az keyvault secret show --name ${secretName} --vault-name ${vaultName} --query value -o tsv", returnStdout: true
        return secret //exporting to secret as env var
}        
}



################################################################################################################
################################################################################################################


pipeline {
    agent any
  environment {
    MY_CRED = credentials('azure-sp')
  }
  stages {
    stage('Run Script') {
      steps {
          script {
            // env.secret=FetchSecret(String secretName,String vaultName)
            env.secret=FetchSecret("jenkins","jenkinskeyvault1")
            sh 'curl -s -o script.sh https://raw.githubusercontent.com/Ryder05/AwsomeProject/main/script.sh && chmod u+x script.sh '
            sh """ ./script.sh ${env.secret} """ }
            }
        }
    }
}

String FetchSecret(String secretName,String vaultName) {
        def secret = sh script:"az keyvault secret show --name ${secretName} --vault-name ${vaultName} --query value -o tsv", returnStdout: true
        return secret //exporting to secret as env var
}

