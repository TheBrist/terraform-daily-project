  metadata = {
    startup-script = <<-EOF
      #!/bin/bash
      apt-get update && apt-get install -y curl jq git
      mkdir /actions-runner && cd /actions-runner
      RUNNER_VERSION="2.316.0"
      curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
      tar xzf actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
      ./config.sh --url https://github.com/ORG/REPO --token $RUNNER_TOKEN --unattended
      ./svc.sh install && ./svc.sh start
    EOF
  }
