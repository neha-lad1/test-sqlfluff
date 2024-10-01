# CI/CD for Power BI Deployments
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

Welcome to the **CICD (Test, Staging, Production)** Power BI GitHub Workflow. This workflow automates the process of building, testing, and deploying Power BI project across multiple environments—**Test**, **Staging**, and **Production**. It supports automatic deployments on the `develop` branch and can also be manually triggered with a selectable release version.

## Prerequisites

Before you can use this workflow, make sure to have the following:
- A **GitHub repository** set up and accessible.
- Basic understanding of **GitHub Actions** and **YAML, Config file syntax**.
- All necessary **secrets** configured in your repository's settings to support build and deployment processes.
  
## Workflow Overview

This workflow is designed to:
- **Build** your project using a selected release version.
- **Print** the selected release version for logging purposes.
- **Deploy** the built project to the **Test**, **Staging**, and **Production** environments.

The workflow uses a combination of build and deployment jobs, each using pre-configured `.yml` files located in the repository.

## Triggering the Workflow

### Push Events

The workflow automatically runs when there is a **push** event to the `develop` branch. Ensure that any feature updates or changes are merged into this branch to trigger the CI/CD pipeline.

### Manual Dispatch

You can also trigger the workflow manually through GitHub’s **"Run workflow"** button. When manually triggering the workflow, you will be prompted to select a `release_version` from the following options:
- `v1.0.0`
- `v1.0.1`
- `v1.0.2`
- `v1.0.3`
- `v1.0.4`
- `v1.0.5`

To manually run the workflow:
1. Navigate to the **Actions** tab in your GitHub repository.
2. Select the **CICD (Test, Staging, Production)** workflow from the list.
3. Click **Run workflow**.
4. Select the **release_version** from the dropdown.
5. Click **Run workflow** to start the process.

## Jobs and Steps

### Build Job

The `build` job is responsible for building your project. It uses the `build.yml` workflow located in the `.github/workflows/` directory. The job takes the `release_version` input passed from either the push event or manual dispatch.

```yaml
build:
  uses: ./.github/workflows/build.yml
  with:
    release_version: ${{ github.event.inputs.release_version }}
  secrets: inherit
```

This job is critical as it prepares the application for deployment by compiling or building the code.

### Print Release Version Job

After the build process, the `print-release` job prints the selected release version to the logs. This helps in tracking which release version is being deployed.

```yaml
print-release:
  needs: build
  runs-on: vars.RUNNER_NAME_$ENV
  steps:
    - name: Print Release Version
      run: |
        echo "Selected release for deployment: ${{ needs.build.outputs.release_version }}"
```

### Deployment Jobs

There are three deployment jobs included in this workflow, each for the **Test**, **Staging**, and **Production** environments. All deployment jobs reuse the `deploy-environment.yml` file to ensure consistency across environments.

1. **Test Deploy**
   - Deploys the application to the Test environment after a successful build.
   - Takes `environment: TEST` as input.

```yaml
test-deploy:
  needs: build
  uses: ./.github/workflows/deploy-environment.yml
  with:
    environment: TEST
    release_version: ${{ needs.build.outputs.release_version }}
  secrets: inherit
```

2. **Staging Deploy**
   - Deploys the application to the Staging environment after a successful deployment in Test.
   - Takes `environment: STG` as input.

```yaml
stg-deploy:
  needs: [build, test-deploy]
  uses: ./.github/workflows/deploy-environment.yml
  with:
    environment: STG
    release_version: ${{ needs.build.outputs.release_version }}
  secrets: inherit
```

3. **Production Deploy**
   - Deploys the application to the Production environment after a successful deployment in Staging.
   - Takes `environment: PROD` as input.

```yaml
prod-deploy:
  needs: [build, test-deploy, stg-deploy]
  uses: ./.github/workflows/deploy-environment.yml
  with:
    environment: PROD
    release_version: ${{ needs.build.outputs.release_version }}
  secrets: inherit
```

## Environment Variables and Secrets

This workflow depends on environment variables and secrets for secure deployment. Make sure the following are configured in your repository settings:

- **Secrets**: These may include sensitive data such as API keys, credentials, or environment-specific secrets (e.g., `TEST_ENV_SECRET`, `STG_ENV_SECRET`, `PROD_ENV_SECRET`).
  
To set up secrets:
1. Go to your GitHub repository.
2. Click on **Settings** > **Secrets** > **Actions**.
3. Add the required secrets used in your jobs.

## Troubleshooting

In case of issues with the workflow:
- Review the **logs** for each step to identify where the process failed.
- Ensure that all required **secrets** are set up correctly in your repository settings.
- Verify the **environment configurations** and ensure the build and deployment scripts are correctly defined.

If errors persist, consider:
- Checking the version compatibility of tools used in your jobs.
- Reviewing any recent changes in the repository that might affect the workflow.

## Contributing

Contributions are welcome! If you'd like to improve this workflow or add new features:
1. Fork the repository.
2. Create a new branch for your feature or fix.
3. Make the necessary changes.
4. Submit a **pull request** explaining the updates you've made.


This README file now reflects the workflow for the **Test**, **Staging**, and **Production** environments and provides clear guidelines for understanding and using the CI/CD pipeline effectively.
