```markdown
# CICD (Dev, Staging, Prod) Workflow

## Table of Contents
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Workflow Overview](#workflow-overview)
- [Triggering the Workflow](#triggering-the-workflow)
  - [Push Events](#push-events)
  - [Manual Dispatch](#manual-dispatch)
- [Jobs and Steps](#jobs-and-steps)
  - [Build Job](#build-job)
  - [Print Release Version Job](#print-release-version-job)
  - [Deployment Jobs](#deployment-jobs)
- [Environment Variables and Secrets](#environment-variables-and-secrets)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Introduction
Welcome to the CICD (Dev, Staging, Prod) GitHub Workflow. This workflow is designed to automate the build, test, and deployment processes for your project across different environments.

## Prerequisites
Before using this workflow:
- Ensure you have a GitHub repository set up.
- Familiarize yourself with GitHub Actions and YAML syntax.
- Set up necessary secrets in your repository settings if required by the workflow.

## Workflow Overview
This workflow automates the following processes:
- Builds your project.
- Prints the selected release version.
- Deploys your project to DEV and TEST environments.

## Triggering the Workflow

### Push Events
The workflow is triggered automatically when there is a push event on the `develop` branch.

### Manual Dispatch
You can also manually trigger this workflow using the "Run workflow" button on GitHub. When doing so, you will be prompted to select a release version from a list of predefined options.

## Jobs and Steps

### Build Job
The `build` job uses another workflow file located at `./.github/workflows/build.yml`. It takes an input parameter `release_version` which is passed from either the push event or manual dispatch.

```yaml
build:
  uses: ./.github/workflows/build.yml
  with:
    release_version: ${{ github.event.inputs.release_version }}
  secrets: inherit
```

### Print Release Version Job
This job prints out the selected release version after the build job has completed.

```yaml
print-release:
  needs: build
  runs-on: ubuntu-latest
  steps:
    - name: Print Release Version
      run: |
        echo "Selected release for deployment: ${{ needs.build.outputs.release_version }}"
```

### Deployment Jobs
There are two deployment jobs: one for DEV environment and another for TEST environment. Both jobs use another workflow file located at `./.github/workflows/deploy-environment.yml`.

```yaml
dev-deploy:
  needs: build
  uses: ./.github/workflows/deploy-environment.yml
  with:
    environment: DEV
    release_version: ${{ needs.build.outputs.release_version }}
  secrets: inherit

test-deploy:
  needs: [build, dev-deploy]
  uses: ./.github/workflows/deploy-environment.yml
  with:
    environment: TEST
    release_version: ${{ needs.build.outputs.release_version }}
  secrets: inherit
```

## Environment Variables and Secrets
The workflow uses inherited secrets from your repository settings. Ensure that all necessary secrets are configured in your repository settings before running this workflow.

## Troubleshooting
If you encounter any issues during the execution of this workflow:
- Check the logs of each job step to identify where things went wrong.
- Verify that all required secrets are correctly set up in your repository settings.
- Ensure that dependencies and environment configurations are correct in your build and deployment scripts.

## Contributing
To contribute to this project or modify this workflow:
- Fork this repository.
- Make necessary changes or additions.
- Submit a pull request with detailed explanations of your changes.
