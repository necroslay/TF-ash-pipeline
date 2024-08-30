
# AWS Pipeline Refactoring: CDK to Terraform

## Overview

This project involved refactoring an existing AWS pipeline originally implemented using the AWS Cloud Development Kit (CDK) into Terraform. The refactored pipeline now supports GitHub as the source repository instead of AWS CodeCommit. Additionally, a bug that affected the original implementation was identified and resolved in this process.

## Key Changes

### 1. **Refactoring from CDK to Terraform**
   - The AWS pipeline was initially created using CDK, an infrastructure-as-code (IaC) tool provided by AWS. The project has now been refactored to use Terraform, which offers a cloud-agnostic way to define and provision infrastructure.
   - The refactored Terraform code follows best practices for resource naming, modularity, and reusability.

### 2. **Bug Fixes**
   - A bug was identified in the original CDK implementation that caused issues with the pipeline’s deployment process. This bug was fixed during the refactoring process.
   - The bug was related to [describe the bug briefly, e.g., "an incorrect IAM policy assignment that prevented the pipeline from accessing necessary resources"]. The issue has been resolved by [describe the fix briefly, e.g., "correcting the IAM policy and ensuring that the required permissions are in place"].

### 3. **Migration to GitHub**
   - The pipeline’s source repository was changed from AWS CodeCommit to GitHub.
   - The Terraform code now includes integration with GitHub, enabling the pipeline to automatically trigger on pushes or pull requests to specified branches.
   - This change allows for easier collaboration and leverages GitHub’s features such as code reviews, pull request templates, and GitHub Actions for additional CI/CD capabilities.

## Pipeline Structure

The pipeline consists of the following stages:

1. **Source**: Fetches the code from the specified GitHub repository and branch.
2. **Build**: Compiles and builds the application using AWS CodeBuild.
3. **Test**: Runs unit tests and other automated tests.
4. **Deploy**: Deploys the application to the specified AWS environment using AWS CodeDeploy or similar services.

## Prerequisites

Before deploying the pipeline, ensure that you have the following:

1. **AWS CLI**: Installed and configured with appropriate credentials.
2. **Terraform**: Installed on your local machine or CI/CD environment.
3. **GitHub Personal Access Token**: With sufficient permissions to access the repository.
4. **AWS Account**: With permissions to create and manage resources such as IAM roles, CodeBuild projects, and S3 buckets.

## Deployment

To deploy the pipeline, follow these steps:

1. **Clone the Repository**

   ```sh
   git clone https://github.com/yourusername/your-repo.git
   cd your-repo
   ```

2. **Initialize Terraform**

   ```sh
   terraform init
   ```

3. **Configure Terraform Variables**

   Update the `terraform.tfvars` file with your specific settings, including:

   - `github_token`: Your GitHub personal access token.
   - `github_repository`: The name of the GitHub repository to connect to the pipeline.
   - `aws_region`: The AWS region where the pipeline will be deployed.

4. **Apply the Terraform Configuration**

   ```sh
   terraform apply
   ```

   Review the changes and confirm to proceed with the deployment.

5. **Monitor the Pipeline**

   Once the Terraform configuration is applied, the pipeline will be created in your AWS account. You can monitor its progress and status in the AWS Management Console under AWS CodePipeline.

## Troubleshooting

If you encounter any issues during deployment or execution, consider the following:

- **Terraform Errors**: Check the Terraform plan output for any configuration issues. Ensure that all required variables are correctly set.
- **Pipeline Failures**: Review the AWS CodePipeline and CodeBuild logs for detailed error messages. Common issues may include IAM permission errors, incorrect GitHub repository settings, or build configuration errors.

## Future Enhancements

- **Enhanced Security**: Consider adding IAM roles with least privilege for better security.
- **Automated Tests**: Integrate more automated tests at different stages of the pipeline.
- **Multi-Environment Support**: Extend the Terraform code to support multiple environments (e.g., dev, staging, prod) with different configurations.

## Acknowledgments

- [Terraform Documentation](https://www.terraform.io/docs/)
- [AWS CodePipeline Documentation](https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html)
- [GitHub Documentation](https://docs.github.com/en)

## License

This project is licensed under the MIT License. See the `LICENSE` file for more details.
