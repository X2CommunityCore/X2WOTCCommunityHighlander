pipeline {
  environment {
      modName = "X2WOTCCommunityHighlander"
      repoName = "X2CommunityCore/X2WOTCCommunityHighlander"
  }

  options {
        timeout(time: 15, unit: 'MINUTES')
        disableConcurrentBuilds()
  }

  agent { 
    node { 
      label 'master'
    } 
  }

  stages {
    // couldn't figure out how to modify the built-in checkout, so just do it again
    stage('Checkout') {
      steps {
        checkout([
          $class: 'GitSCM',
          branches: scm.branches,
          doGenerateSubmoduleConfigurations: scm.doGenerateSubmoduleConfigurations,
          extensions: scm.extensions + [[$class: 'GitLFSPull']],
          userRemoteConfigs: scm.userRemoteConfigs
        ])
      }
    }

    stage('Build Mod Project') {
      steps {
        bat '''
          @echo "Building Mod Project!"
          @echo %WORKSPACE%
          @powershell set-executionpolicy remotesigned
          powershell ".scripts/build_jenkins.ps1" -mod %modName% -srcDirectory "'%WORKSPACE%'"
        '''
      }
    }

    stage('Upload Release') {
      when { branch 'master' }
      steps {
        withCredentials([usernamePassword(credentialsId: 'github-x2communitycore-via-access-token', passwordVariable: 'personal_access_token', usernameVariable: 'username')]) {
          bat '''
            C:\\Python37\\python.exe .scripts/tagmaker.py %personal_access_token% --repo %repoName% --current_commit_hash %GIT_COMMIT% --workspace_directory "%WORKSPACE%" --artifact_name %modName%.zip --should_increment 1
            '''
        }
      }
    }
  }
  
  post { 
        always { 
            deleteDir()
        }
    }
}