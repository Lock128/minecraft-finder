# GitHub Actions Workflows

This directory contains GitHub Actions workflows for the Minecraft Ore Finder project.

## Web Hosting Deployment Workflow

The `deploy-web-hosting.yml` workflow provides automated CI/CD for deploying the Flutter web application to AWS using CDK infrastructure.

### Features

- **Automated Flutter Web Build**: Builds the Flutter web application with optimizations
- **CDK Infrastructure Deployment**: Deploys AWS infrastructure using TypeScript CDK
- **Asset Upload**: Syncs built assets to S3 with proper cache headers
- **CloudFront Cache Invalidation**: Automatically invalidates CDN cache after deployment
- **Multi-Environment Support**: Supports dev, staging, and prod environments
- **Error Handling**: Comprehensive error handling and rollback capabilities
- **Status Reporting**: Detailed deployment summaries and notifications

### Triggers

The workflow triggers on:
- **Push to main branch**: Automatic deployment when changes are pushed to main
- **Manual dispatch**: Manual deployment with environment selection via GitHub UI
- **Path filtering**: Only triggers when relevant files change (flutter_app/**, infrastructure/**, workflow file)

### Required GitHub Secrets

Configure the following secrets in your GitHub repository settings:

#### AWS Credentials
- `AWS_ACCESS_KEY_ID`: AWS access key for the deployment account
- `AWS_SECRET_ACCESS_KEY`: AWS secret access key for the deployment account
- `AWS_ACCOUNT_ID`: AWS account ID where resources will be deployed

#### Domain Configuration
- `DOMAIN_NAME`: Custom domain name (e.g., `app.minecraft.lockhead.cloud`)
- `HOSTED_ZONE_ID`: Route53 hosted zone ID in the DNS management account
- `CROSS_ACCOUNT_ROLE_ARN`: IAM role ARN for cross-account DNS operations

### Workflow Jobs

#### 1. Build Flutter (`build-flutter`)
- Sets up Flutter environment
- Installs dependencies and runs analysis
- Executes tests with coverage
- Builds Flutter web application for production
- Generates build metadata
- Uploads build artifacts

#### 2. Deploy Infrastructure (`deploy-infrastructure`)
- Sets up Node.js and AWS credentials
- Installs CDK dependencies and builds TypeScript
- Runs CDK tests and generates diff
- Bootstraps CDK (if needed)
- Deploys CDK stack with environment-specific configuration
- Extracts deployment outputs (CloudFront ID, S3 bucket, domain)

#### 3. Deploy Assets (`deploy-assets`)
- Downloads Flutter build artifacts
- Syncs assets to S3 with optimized cache headers
- Applies different cache policies for static assets vs. HTML files
- Creates CloudFront invalidation
- Waits for invalidation completion

#### 4. Notify Deployment (`notify-deployment`)
- Determines overall deployment status
- Creates comprehensive deployment summary
- Posts status to GitHub Step Summary
- Comments on pull requests (if applicable)

### Environment Configuration

The workflow supports multiple environments through the `environment` input:

- **dev**: Development environment (default)
- **staging**: Staging environment for testing
- **prod**: Production environment

Environment-specific configurations are managed through:
- CDK context parameters
- GitHub environment protection rules
- Environment-specific secrets

### Cache Strategy

The workflow implements an optimized caching strategy:

#### Static Assets (CSS, JS, Images)
- Cache-Control: `public, max-age=31536000` (1 year)
- Suitable for versioned assets with content hashing

#### HTML and Service Worker Files
- Cache-Control: `no-cache, no-store, must-revalidate`
- Ensures fresh content for entry points and service workers

### Error Handling

The workflow includes comprehensive error handling:

- **Build Failures**: Flutter analysis, test, and build errors are caught and reported
- **Infrastructure Failures**: CDK deployment errors with detailed logging
- **Asset Upload Failures**: S3 sync and CloudFront invalidation error handling
- **Timeout Protection**: Each job has appropriate timeout limits
- **Rollback Support**: Failed deployments don't affect existing infrastructure

### Manual Deployment Options

The workflow supports manual deployment with additional options:

- **Environment Selection**: Choose target environment (dev/staging/prod)
- **Skip Build**: Deploy infrastructure changes without rebuilding Flutter app
- **Custom Parameters**: Override default configuration through workflow inputs

### Monitoring and Observability

The workflow provides detailed monitoring:

- **Step-by-step Progress**: Real-time deployment progress in GitHub Actions
- **Deployment Summaries**: Comprehensive reports with URLs and status
- **Artifact Retention**: Build artifacts and outputs retained for 7 days
- **Error Reporting**: Detailed error messages and troubleshooting information

### Security Considerations

The workflow implements security best practices:

- **Least Privilege**: AWS credentials with minimal required permissions
- **Secret Management**: Sensitive data stored in GitHub Secrets
- **Session Management**: Time-limited AWS sessions with unique names
- **Environment Protection**: GitHub environment protection rules
- **Audit Trail**: Complete deployment history and logging

### Troubleshooting

#### Common Issues

1. **AWS Credentials**: Ensure AWS secrets are correctly configured
2. **CDK Bootstrap**: First deployment may require manual CDK bootstrap
3. **Cross-Account Permissions**: Verify cross-account role has proper permissions
4. **Domain Configuration**: Check DNS settings and certificate validation
5. **Build Failures**: Review Flutter dependencies and test results

#### Debug Steps

1. Check GitHub Actions logs for detailed error messages
2. Verify AWS credentials and permissions
3. Test CDK deployment locally with same parameters
4. Validate Flutter build process locally
5. Check AWS CloudFormation stack events for infrastructure issues

### Local Development

To test the deployment process locally:

```bash
# Build Flutter web
cd flutter_app
flutter build web --release

# Deploy CDK infrastructure
cd ../infrastructure
npm install
npm run build
npm test
npx cdk deploy --context environment=dev

# Upload assets (requires AWS CLI)
aws s3 sync ../flutter_app/build/web/ s3://your-bucket-name/
aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths "/*"
```

### Contributing

When modifying the workflow:

1. Test changes in a feature branch first
2. Use workflow_dispatch for manual testing
3. Verify all required secrets are documented
4. Update this README with any new requirements
5. Test with different environments (dev/staging/prod)

For more information about the CDK infrastructure, see the [infrastructure README](../../infrastructure/README.md).