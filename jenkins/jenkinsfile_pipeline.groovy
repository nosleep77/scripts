node {

    // Variables definition

    // Git repo url
    def git_url = 'git@usr-git.cicd.local:auto/puppet.git'

    // Variables used for rollback function to know which environment where changed in order to rollback them
    def lab_updated = "no"
    def prod_updated = "no"

    def branch_input

    try {

        // Initialize a connexion to git - If this fails the build immediately fails
        git url: git_url, branch: "master"

        // Export the whole list of branch to a temporary file
        sh "git branch -a > /tmp/branches.txt"

    	// Parse the list of branches imported
        def txtt = new File("/tmp/branches.txt").readLines()
        def branch_list_auto = new String[txtt.size()];
        def branchIndex = 0
        for (int i = 0; i < txtt.size(); i++) {
            def b_element;
            if (txtt[i].indexOf("remotes/origin/") != -1) {
                b_element = txtt[i].minus(" remotes/origin/").trim()
                branch_list_auto[branchIndex] = b_element
                branchIndex++
            }
        }

    	// Present the user which branch he want to build from
        choice = new ChoiceParameterDefinition('Param name', branch_list_auto, 'Description')
        branch_input = input( message: 'Lab Test Results', parameters: [choice] )

        // CHeckout the selected branch
        git url: git_url, branch: branch_input

        // Stage 1 - Update foreman in lab stage
        stage 'Update Foreman in Lab'

            // Copy files
            sh "scp -r ./* jenkins@10.99.212.59:/etc/puppet/environments/lab/modules/"

            // update foreman api
            update_foreman_api()

            // Once the copy is completed successfully, we update the content of this variable so the script know that a lab rollback may be needed if something goes wrong in next steps
            lab_updated = "yes"

    		updateJira(branch_input, 'Jenkins update: Foreman updated on LAB')

    	// Stage 2 - Run lab tests manually and input the test result
        stage 'Run LAB Tests Manually'

        	// Ask for lab test result
            choice = new ChoiceParameterDefinition('Param name', ['succeed', 'failed'] as String[], 'Description')
            def res_input = input( message: 'Lab Test Results', parameters: [choice] )

            // If the test pass, proceed. If it fails throw and exception to exit the script
            if (res_input == "succeed"){
                echo "ok, moving to next step"
                updateJira(branch_input, 'Jenkins update: Lab tests passed')

            } else {
                currentBuild.result = 'FAILURE'
                throw new Exception()
            }

 		// Step 3 - Update foreman in Prod stage
        stage 'Update Foreman in Prod'

        	// Copy files
            sh "scp -r ./* jenkins@10.99.212.59:/etc/puppet/environments/production/modules/"

            // update foreman api
            update_foreman_api()

            // Once the copy is completed successfully, we update the content of this variable so the script know that a lab rollback may be needed if something goes wrong in next steps
            prod_updated = "yes"

            updateJira(branch_input, 'Jenkins update: Foreman updated on PROD')

        // Step 4 - Run prod tests manually and input the test result
        stage 'Run PROD Tests Manually'

        	// Ask for prod test result
            choice = new ChoiceParameterDefinition('Param name', ['succeed', 'failed'] as String[], 'Description')
            def res_input_prod = input( message: 'Prod Test Results', parameters: [choice] )

    		// If the test pass, proceed. If it fails throw and exception to exit the script
            if (res_input_prod == "succeed") {
                echo "ok, moving to next step"
                updateJira(branch_input, 'Jenkins update: Prod tests passed')
            }
            else {
                currentBuild.result = 'FAILURE'
                throw new Exception()
            }

       	// Step 5 - Merge the feature branch to prod
        stage 'Merge to Prod'

        	// CHeckout master branch
            git url: git_url, branch: 'master'

            // Merge feature branch on master
            sh "git merge " + branch_input

            // Push to remote
            sh "git push origin master"

            // Update JIRA Comment with information
            updateJira(branch_input, 'Jenkins update: Merged working branch to Master/Prod')

       // Step 6 - Update JIRA with the final status
        stage 'Jira updates'
            updateJira(branch_input, 'Jenkins update: Build Successful!')

    }
    // In case of any exception thrown , we catch it and trigger rollback actions and JIRA updates
    catch (all) {
    	// As we catch the exception, we need to manually set the job to failed
        currentBuild.result = 'FAILURE'

        // Rollbacks
        rollback_copy(lab_updated, prod_updated, git_url)

        // Update Jira with failed status
        updateJira(branch_input, 'Jenkins update: Build Failed!')
    }


}

// This function updates JIRA.
// b_name is the feature branch name from which we get the ticket ID
// comment is the comment to be updated on jira

def updateJira(b_name, comment) {

   //def b_name = "nginx-JRMYB-5"
    def project_filter = "JR"
    def s_index = b_name.indexOf(project_filter)

    def jira_info = b_name.substring(s_index, b_name.size())

    def issue_id = jira_info.substring(2, jira_info.size())
    echo issue_id

    def project_arr = issue_id.split('-')
    def project_id = project_arr[0]

    step([$class: 'hudson.plugins.jira.JiraIssueUpdateBuilder',
        jqlSearch: "project = '"+project_id+"' and key = '"+issue_id+"'",
        comment: comment])

}

// This function performs the rollback of foreman
// lab_updated / prod_updated indicate which environment changed
// git_url indicate the git server url as there will be need to checkout master branch for the rollback

def rollback_copy(lab_updated, prod_updated, git_url) {

    git url: git_url, branch: 'master'
    if (lab_updated == "yes") {
        stage 'Rollback Lab'
            sh "ssh jenkins@10.99.212.59 'rm -rf /etc/puppet/environments/lab/modules/*'"
            sh "scp -r ./* jenkins@10.99.212.59:/etc/puppet/environments/lab/modules/"
    }

    if (prod_updated == "yes") {
        stage 'Rollback Prod'
            sh "ssh jenkins@10.99.212.59 'rm -rf /etc/puppet/environments/production/modules/*'"
            sh "scp -r ./* jenkins@10.99.212.59:/etc/puppet/environments/production/modules/"
             
    }

    update_foreman_api()
}

def update_foreman_api() {
    sh "curl --request POST -k  -H 'Content-Type: application/json' 'https://10.99.212.59//api/smart_proxies/1/import_puppetclasses' --user usrtest:Password123"
}
