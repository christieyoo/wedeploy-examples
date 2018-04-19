import net.sf.json.JSONArray;
import net.sf.json.JSONObject;

pipeline {
  agent {
    node {
      label 'console'
    }
  }
  stages {
    stage('Setup') {
      steps {
        buildStep('Setup') {
          sh './.jenkins/main.sh --setup-machine'
          sh './.jenkins/main.sh --shutdown-infrastructure'
        }
      }
    }
    stage('Pull Infrastructure Images') {
      steps {
        buildStep('Pull Infrastructure Images') {
          sh './.jenkins/main.sh --pull-infrastructure-images'
        }
      }
    }
    stage('Tag Infrastructure Images') {
      steps {
        buildStep('Tag Infrastructure Images') {
          sh "./.jenkins/main.sh --tag-infrastructure-images ${env.BUILD_TAG}"
        }
      }
    }
    stage('Start Infrastructure') {
      steps {
        buildStep('Start Infrastructure') {
          sh "./.jenkins/main.sh --start-infrastructure ${env.BUILD_TAG}"
        }
      }
    }
    stage('Pause') {
      steps {
        buildStep('Pause') {
          sh 'sleep 3'
        }
      }
    }
    stage('Create Test User') {
      steps {
        buildStep('Create Test User') {
          sh './.jenkins/main.sh --create-test-user'
        }
      }
    }
    stage('Setup functional tests') {
      steps {
        buildStep('Setup functional tests') {
          sh './.jenkins/main.sh --setup-functional-tests'
        }
      }
    }
    stage('Install Packages') {
      steps {
        buildStep('Install Packages') {
          sh './.jenkins/main.sh --install-packages'
        }
      }
    }
    stage('Tests') {
      steps {
        buildStep('Tests') {
          sh './.jenkins/main.sh --run-tests'
        }
      }
    }
  }
  post {
    always {
      junit(allowEmptyResults: true, testResults: '.runner/wedeploy-functional-tests/test-results/TEST-*.xml')

      archiveArtifacts artifacts: '.runner/wedeploy-functional-tests/html-report/*.html'

      sh './.jenkins/main.sh --shutdown-infrastructure'
    }
  }
}

void buildStep(String message, Closure closure) {
  try {
    setBuildStatus(message, "PENDING");

    closure();

    setBuildStatus(message, "SUCCESS");
  }
  catch (Exception e) {
    setBuildStatus(message, "FAILURE");
    pushToSlack();
    throw e
  }
}

void setBuildStatus(String message, String state) {
  step([
      $class: "GitHubCommitStatusSetter",
      reposSource: [$class: "ManuallyEnteredRepositorySource", url: "https://github.com/wedeploy/wedeploy-examples"],
      contextSource: [$class: "ManuallyEnteredCommitContextSource", context: "ci/jenkins/build-status"],
      errorHandlers: [[$class: "ChangingBuildStatusErrorHandler", result: "UNSTABLE"]],
      statusResultSource: [ $class: "ConditionalStatusResultSource", results: [[$class: "AnyBuildResult", message: message, state: state]] ]
  ]);
}

String getGitAuthor() {
  def commit = sh(returnStdout: true, script: 'git rev-parse HEAD');
  return sh(returnStdout: true, script: "git --no-pager show -s --format='%an' ${commit}").trim();
}

String getLastCommitMessage() {
  return sh(returnStdout: true, script: 'git log -1 --pretty=%B').trim();
}

void pushToSlack() {
  String[] errorMessages = [
    'Hey, Vader seems to be mad at you.',
    'Please! Don\'t break the CI ;/',
    'Houston, we have a problem'
  ];

  String title = "FAILED: Job ${env.JOB_NAME} - ${env.BUILD_NUMBER}";

  JSONArray attachments = new JSONArray();

  attachment = new JSONObject();
  attachment.put('pretext', 'BUILD FAILED - wedeploy/console');
  attachment.put('text', getRandom(errorMessages));
  attachment.put('fallback', 'CI BUILD FAILED');
  attachment.put('color','#ff0000');
  attachment.put('author_name', getGitAuthor());
  attachment.put('title', title);
  attachment.put('title_link', env.BUILD_URL);
  attachment.put('footer', 'WeDeploy CI Team');
  attachment.put('footer_icon', 'https://a.slack-edge.com/7bf4/img/services/jenkins-ci_48.png')

  JSONArray attachmentFields = new JSONArray();

  lastCommitField = new JSONObject();
  lastCommitField.put('title', 'Last Commit');
  lastCommitField.put('value', getLastCommitMessage());
  lastCommitField.put('short', false);

  attachmentFields.add(lastCommitField);

  attachment.put('fields', attachmentFields);

  attachments.add(attachment);

  slackSend (color: '#ff0000', attachments: attachments.toString());
}

String getRandom(String[] array) {
    int rnd = new Random().nextInt(array.length);
    return array[rnd];
}
