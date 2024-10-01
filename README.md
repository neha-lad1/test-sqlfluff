# CICD Workflow for Dev, Staging, and Prod

## Overview

This GitHub Actions workflow automates the continuous integration and deployment (CICD) process across three environments: Development (Dev), Testing (Test), and Production (Prod). The workflow is triggered on pushes to the `develop` branch and can also be manually triggered using the `workflow_dispatch` event.

## Workflow Structure

- **Trigger**: The workflow triggers automatically on pushes to the `develop` branch. It can also be manually invoked using the workflow dispatch feature by selecting a release version.
- **Stages**:
  - **Build**: This job builds the project using the specified release version.
  - **Print Release Version**: This job prints the release version selected for the deployment.
  - **Dev Deploy**: Deploys the selected release to the Dev environment.
  - **Test Deploy**: Deploys the selected release to the Test environment after successful deployment to Dev.

## Workflow Triggers

### 1. **Automatic Trigger**
The workflow will automatically run whenever there is a push to the `develop` branch.

### 2. **Manual Trigger**
You can manually trigger the workflow from the GitHub Actions tab using the `workflow_dispatch` event. This requires selecting the release version to deploy.

### Inputs for Manual Trigger:
- **release_version**: Select the version of the release from the following options:
  - `v1.0.0`
  - `v1.0.1`
  - `v1.0.2`
  - `v1.0.3`
  - `v1.0.4`
  - `v1.0.5`

## Workflow Breakdown

### Jobs

1. **Build**
   - **Description**: This job runs the build process for the application.
   - **Usage**: Reuses the `build.yml` file from `.github/workflows/`.
   - **Input**: Takes `release_version` as input from the workflow dispatch.
   - **Secrets**: Inherits secrets for secure credentials and access.

2. **Print Release Version**
   - **Description**: Prints the selected release version.
   - **Dependency**: This job depends on the `build` job and uses its output (`release_version`).
   - **Steps**: A simple echo command to output the release version.

3. **Dev Deploy**
   - **Description**: Deploys the built application to the Dev environment.
   - **Usage**: Reuses the `deploy-environment.yml` file from `.github/workflows/`.
   - **Dependency**: Runs after the `build` job.
   - **Input**: Takes `environment: DEV` and `release_version` as input.
   - **Secrets**: Inherits necessary secrets for deployment.

4. **Test Deploy**
   - **Description**: Deploys the built application to the Test environment after successful Dev deployment.
   - **Usage**: Reuses the `deploy-environment.yml` file from `.github/workflows/`.
   - **Dependency**: Runs after both the `build` and `dev-deploy` jobs.
   - **Input**: Takes `environment: TEST` and `release_version` as input.
   - **Secrets**: Inherits necessary secrets for deployment.

## How to Trigger the Workflow Manually

1. Go to the **Actions** tab in the GitHub repository.
2. Select the **CICD (Dev, Staging, Prod)** workflow from the list.
3. Click the **Run workflow** button.
4. Choose the **release_version** from the drop-down list.
5. Click **Run workflow** to manually start the pipeline.

## Secrets and Permissions

The workflow uses GitHub Secrets for sensitive information such as environment credentials, which are inherited for each job. Make sure the following secrets are configured in your repository settings:
- **DEV_ENV_SECRET**
- **TEST_ENV_SECRET**
- **PROD_ENV_SECRET**

> **Note**: Ensure that secrets are correctly set up to avoid deployment issues.

## Environment-Specific Configurations

- **Dev Deployment**: The deployment will occur in the Development environment first.
- **Test Deployment**: After the Dev deployment is successful, the application is deployed to the Test environment.
- **Prod Deployment** (Future Implementation): The Prod deployment will be added later and will follow a similar pattern as the Dev and Test deployments.

## Rollback and Monitoring

If there are any issues during deployment, you can roll back the deployment by:
- Re-running the workflow with a previous `release_version`.
- Contacting the DevOps team for assistance in handling rollback scenarios.

