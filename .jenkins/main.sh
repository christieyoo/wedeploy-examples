#!/bin/bash

set -o errexit
set -o xtrace

CURRENT_DIR=$(pwd)

main() {
  case $1 in

  --setup-machine)
    setup_machine
    ;;

  --shutdown-infrastructure)
    shutdown_infrastructure
    ;;

  --pull-infrastructure-images)
    pull_infrastructure_images
    ;;

  --tag-infrastructure-images)
    tag_infrastructure_images $2
    ;;

  --start-infrastructure)
    start_infrastructure $2
    ;;

  --create-test-user)
    create_test_user
    ;;

  --setup-functional-tests)
    setup_functional_tests
    ;;

  --install-packages)
    install_packages
    ;;

  --run-tests)
    run_tests
    ;;

  *)
    echo "Error:
  Unknown command.
  Usage: main.sh [--setup-machine | --shutdown-infrastructure | --pull-infrastructure-images | --start-infrastructure
                  --create-test-user | --setup-functional-tests | --install-packages | --run-tests]

  Aborting."
    exit 1
    ;;
  esac
}

setup_machine() {
  setup_runner
  dig +trace wedeploy.domains
}

install_packages() {
  cd "$CURRENT_DIR/.runner/wedeploy-functional-tests"
  sudo bundle install
}

setup_runner() {
  rm -rf "$CURRENT_DIR/.runner/ci-infrastructure"

  echo "Fetching exploded infra"

  mkdir -p "$CURRENT_DIR/.runner"

  cd "$CURRENT_DIR/.runner"

  git clone https://github.com/wedeploy/ci-infrastructure.git

  chmod +x "$CURRENT_DIR/.runner/ci-infrastructure/runner/exploded-infra-runner.sh"
}

run_tests() {
  cd "${CURRENT_DIR}/.runner/wedeploy-functional-tests"
  echo "Running tests"
  export API_URL="https://api.wedeploy.xyz"
  export MAILHOG_API_URL="https://mailhog.wedeploy.xyz/api"
  export CONSOLE_URL="https://console.wedeploy.xyz"
  export REDIRECT_URI="http://localhost:8082"
  export SELENIUM_DRIVER="chrome"
  export SERVICE_DOMAIN="wedeploy.sh"
  export TEAM_USER_EMAIL="qa.team.user@wedeploy.com"
  export TEAM_USER_PW="L6P&ZExVXydC"
  export DISPLAY=:99.0

  rake ci:examples || rake ci:rerun
}

setup_functional_tests() {
  rm -rf "$CURRENT_DIR/.runner/wedeploy-functional-tests"

  echo "Fetching exploded infra"

  mkdir -p "$CURRENT_DIR/.runner"

  cd "$CURRENT_DIR/.runner"

  git clone https://github.com/wedeploy/wedeploy-functional-tests.git
}

start_infrastructure() {
  local BUILD_TAG=$1
  local WEDEPLOY_ENVIRONMENT=wd-paas-test-us-east-1
  bash "$CURRENT_DIR/.runner/ci-infrastructure/runner/exploded-infra-runner.sh" --run $BUILD_TAG $WEDEPLOY_ENVIRONMENT
}

shutdown_infrastructure() {
  bash "$CURRENT_DIR/.runner/ci-infrastructure/runner/exploded-infra-runner.sh"  --shutdown
}

pull_infrastructure_images() {
  bash "$CURRENT_DIR/.runner/ci-infrastructure/runner/exploded-infra-runner.sh" --pull-images
}

tag_infrastructure_images() {
  local BUILD_TAG=$1
  bash "$CURRENT_DIR/.runner/ci-infrastructure/runner/exploded-infra-runner.sh" --tag-images staging $BUILD_TAG
}

create_test_user() {
  curl -X "POST" "localhost:8082/users" \
    -H "Authorization: Bearer token" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d $'{
        "email": "qa.team.user@wedeploy.com",
        "password": "L6P&ZExVXydC",
        "confirmed": null,
        "name": "QA Team User",
        "planId": "team",
        "supportedScopes": [
          "team"
        ]
      }'
}


main "$@"
