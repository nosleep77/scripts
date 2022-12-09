pipeline {
  stages {
    stage('Run Script') {
      steps {
        container('azcli') {
          script {
            env.secret=FetchSecret("api","jenkins-keyvault-azure")
            sh 'curl -s -o script.sh https://raw.githubusercontent.com/Ryder05/AwsomeProject/main/script.sh && chmod u+x script.sh '
            sh """ ./script.sh ${env.secret} """ }
                }
            }
        }
    }
}

String FetchSecret(String secretName,String vaultName) {
      withCredentials([azureServicePrincipal(credentialsId: 'azure-sp',
                      subscriptionIdVariable: 'SUBS_ID',
                      clientIdVariable: 'CLIENT_ID',
                      clientSecretVariable: 'CLIENT_SECRET',
                      tenantIdVariable: 'TENANT_ID')]) {
      sh """
      set +x
      az version 
      az account clear
      az login --service-principal -u $CLIENT_ID -p $CLIENT_SECRET -t $TENANT_ID
      echo 'set current subcription to source subscription'
      az account set --subscription $SUBS_ID
      """ 
      def secret = sh script:'az keyvault secret show --name "api" --vault-name "jenkins-keyvault-azure" --query value -o tsv', returnStdout: true
      println "Azure keyvault secret: ${secret}"
      env.secret = secret //exporting to secret as env var
      }
}
