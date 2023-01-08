
stage('get secret')
 {

withCredentials([azureServicePrincipal('<Azure-credential-id>')]) {
    sh "az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET -t $AZURE_TENANT_ID "
    sh 'grafana_token=$(az keyvault secret show --name "<secret-name>" --vault-name "<vault-name>" --query value -o tsv)'
      }

}

stage('run script')
 {
 sh './script.sh $grafana_token'
}


# jenkins set variable from shell output available globally
