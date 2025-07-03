# Minecraft Ore Finder - Web Hosting Infrastructure

This CDK project provides comprehensive AWS infrastructure for hosting the Minecraft Ore Finder Flutter web application using S3, CloudFront, CloudWatch RUM monitoring, and automated CI/CD deployment.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   GitHub Repo   │───▶│  GitHub Actions  │───▶│   AWS Account   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │  Flutter Build   │    │  CDK Deploy     │
                       └──────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │   S3 Upload      │    │  Infrastructure │
                       └──────────────────┘    │  - S3 Bucket    │
                                │              │  - CloudFront   │
                                ▼              │  - ACM Cert     │
                       ┌──────────────────┐    │  - Route53 DNS  │
                       │ CloudFront Cache │    │  - RUM Monitor  │
                       │   Invalidation   │    └─────────────────┘
                       └──────────────────┘
```

### Core Components

- **🪣 S3 Bucket**: Static website hosting with versioning and lifecycle policies
- **🌐 CloudFront**: Global CDN with custom domain, SSL, and optimized caching
- **🔒 ACM Certificate**: Automated SSL/TLS certificate with DNS validation
- **📊 CloudWatch RUM**: Real user monitoring and performance analytics
- **🌍 Route53**: Cross-account DNS management for custom domains
- **🚀 GitHub Actions**: Automated CI/CD pipeline for deployment

## 📋 Prerequisites

### Required Tools
- **Node.js** 18+ and npm
- **AWS CLI** v2+ configured with appropriate permissions
- **AWS CDK CLI** v2+ (`npm install -g aws-cdk`)
- **Flutter SDK** 3.32+ (for local builds)
- **Git** for version control

### AWS Account Setup
1. **Primary AWS Account**: For hosting infrastructure
2. **DNS AWS Account**: For Route53 hosted zone (can be same account)
3. **Cross-account IAM role**: For DNS management (if using separate accounts)

### Required AWS Permissions

#### Primary Account (Infrastructure)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "cloudfront:*",
        "acm:*",
        "rum:*",
        "iam:*",
        "cloudformation:*",
        "sts:AssumeRole"
      ],
      "Resource": "*"
    }
  ]
}
```

#### DNS Account (Route53)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:GetHostedZone",
        "route53:ListHostedZones",
        "route53:ChangeResourceRecordSets",
        "route53:GetChange",
        "route53:ListResourceRecordSets"
      ],
      "Resource": "*"
    }
  ]
}
```

## 🚀 Quick Start

### 1. Clone and Setup
```bash
# Clone the repository
git clone <repository-url>
cd minecraft-ore-finder

# Install infrastructure dependencies
cd infrastructure
npm install

# Validate configuration
npm run validate-config
```

### 2. Configure Environment
```bash
# Copy example configuration
cp config/dev.json.example config/dev.json

# Edit configuration with your values
nano config/dev.json
```

### 3. Deploy Infrastructure
```bash
# Bootstrap CDK (first time only)
npx cdk bootstrap

# Deploy to development
ENVIRONMENT=dev npm run deploy

# Or use the deployment script
../scripts/deploy.sh -e dev
```

## ⚙️ Configuration Management

### Environment-Specific Configuration

The project uses comprehensive environment-specific configuration files located in the `config/` directory:

- **`dev.json`** - Development environment
- **`staging.json`** - Staging environment  
- **`prod.json`** - Production environment

### Configuration Structure

Each configuration file contains:

```json
{
  "environment": "dev",
  "environmentConfig": {
    "name": "dev",
    "description": "Development environment",
    "isProduction": false,
    "featureFlags": { ... },
    "limits": { ... }
  },
  "domainConfig": {
    "domainName": "dev-minecraft.lockhead.cloud",
    "hostedZoneId": "REPLACE_WITH_HOSTED_ZONE_ID",
    "crossAccountRoleArn": "REPLACE_WITH_CROSS_ACCOUNT_ROLE_ARN"
  },
  "monitoringConfig": { ... },
  "cachingConfig": { ... },
  "s3Config": { ... },
  "resourceNaming": { ... },
  "costAllocation": { ... },
  "tags": { ... }
}
```

### Required Configuration Updates

Before deployment, replace these placeholder values:

1. **`REPLACE_WITH_HOSTED_ZONE_ID`**
   ```bash
   # Find your hosted zone ID
   aws route53 list-hosted-zones --query 'HostedZones[?Name==`lockhead.cloud.`].Id' --output text
   ```

2. **`REPLACE_WITH_CROSS_ACCOUNT_ROLE_ARN`**
   ```bash
   # Format: arn:aws:iam::ACCOUNT-ID:role/ROLE-NAME
   # Example: arn:aws:iam::123456789012:role/CrossAccountDNSRole
   ```

### Configuration Validation

Always validate your configuration before deployment:

```bash
# Validate all environments
npm run validate-config

# Validate specific environment
npm run validate-config dev

# Verbose validation with detailed reports
npm run validate-config --verbose

# Generate validation report file
npm run validate-config --output validation-report.txt
```

## 🛠️ Available Scripts

### Infrastructure Scripts
```bash
# Build and compilation
npm run build              # Compile TypeScript
npm run watch              # Watch mode compilation
npm run lint               # Run ESLint
npm run lint:fix           # Fix ESLint issues

# Testing
npm run test               # Run unit tests
npm run test:watch         # Run tests in watch mode

# CDK operations
npm run cdk                # Run CDK commands
npm run deploy             # Deploy the stack
npm run destroy            # Destroy the stack
npm run diff               # Show deployment diff
npm run synth              # Synthesize CloudFormation

# Configuration management
npm run validate-config    # Validate configurations
```

### Deployment Scripts
```bash
# Local deployment script (recommended for testing)
../scripts/deploy.sh -e dev -v

# Direct CDK deployment
ENVIRONMENT=dev npm run deploy

# GitHub Actions deployment (automatic on push to main)
# Manual trigger via GitHub UI
```

## 🚀 Deployment Guide

### Local Deployment

Use the comprehensive deployment script for local testing:

```bash
# Basic deployment to development
./scripts/deploy.sh

# Deploy to specific environment with options
./scripts/deploy.sh -e staging -v

# Skip Flutter build (infrastructure only)
./scripts/deploy.sh -e prod -s

# Skip tests for faster deployment
./scripts/deploy.sh -e dev -t

# Full deployment with verbose output
./scripts/deploy.sh -e prod -v
```

### GitHub Actions Deployment

Automatic deployment is triggered by:

1. **Push to main branch** (deploys to dev)
2. **Manual workflow dispatch** (choose environment)

#### Required GitHub Secrets

Configure these secrets in your GitHub repository:

```bash
# AWS Credentials
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_ACCOUNT_ID=123456789012

# Domain Configuration
DOMAIN_NAME=minecraft.lockhead.cloud
HOSTED_ZONE_ID=Z1234567890ABC
CROSS_ACCOUNT_ROLE_ARN=arn:aws:iam::123456789012:role/CrossAccountDNSRole
```

#### Manual Deployment via GitHub Actions

1. Go to **Actions** tab in GitHub
2. Select **Deploy Web Hosting Infrastructure**
3. Click **Run workflow**
4. Choose environment and options
5. Click **Run workflow**

### Environment-Specific Deployment

#### Development Environment
```bash
# Quick development deployment
ENVIRONMENT=dev npm run deploy

# Or with deployment script
./scripts/deploy.sh -e dev
```

**Features:**
- Lower cache TTLs for easier testing
- Basic monitoring to reduce costs
- Relaxed security for development convenience
- Random resource suffixes for uniqueness

#### Staging Environment
```bash
# Staging deployment
ENVIRONMENT=staging npm run deploy

# Or with deployment script
./scripts/deploy.sh -e staging
```

**Features:**
- Production-like settings for realistic testing
- Enhanced monitoring for performance validation
- Security hardening enabled
- Extended metrics for comprehensive testing

#### Production Environment
```bash
# Production deployment (use with caution)
ENVIRONMENT=prod npm run deploy

# Or with deployment script
./scripts/deploy.sh -e prod -v
```

**Features:**
- Optimized cache settings for performance
- Full monitoring with cost-controlled sampling
- Maximum security hardening
- Comprehensive tagging for compliance

## 🔐 Cross-Account DNS Setup

### Overview

This infrastructure supports cross-account DNS management, allowing you to:
- Host infrastructure in one AWS account
- Manage DNS (Route53) in another AWS account
- Automatically create SSL certificates with DNS validation
- Create DNS records for custom domains

### Setup Steps

#### 1. Create Cross-Account Role (DNS Account)

```bash
# Create trust policy file
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::INFRASTRUCTURE-ACCOUNT-ID:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "minecraft-finder-dns-access"
        }
      }
    }
  ]
}
EOF

# Create the role
aws iam create-role \
  --role-name CrossAccountDNSRole \
  --assume-role-policy-document file://trust-policy.json

# Attach Route53 permissions
aws iam attach-role-policy \
  --role-name CrossAccountDNSRole \
  --policy-arn arn:aws:iam::aws:policy/Route53FullAccess
```

#### 2. Configure Infrastructure Account

Update your configuration files with the cross-account role ARN:

```json
{
  "domainConfig": {
    "crossAccountRoleArn": "arn:aws:iam::DNS-ACCOUNT-ID:role/CrossAccountDNSRole"
  }
}
```

#### 3. Test Cross-Account Access

```bash
# Test role assumption
aws sts assume-role \
  --role-arn arn:aws:iam::DNS-ACCOUNT-ID:role/CrossAccountDNSRole \
  --role-session-name test-session \
  --external-id minecraft-finder-dns-access
```

## 📊 Monitoring and Observability

### CloudWatch RUM Integration

The infrastructure automatically configures CloudWatch RUM to collect:

- **Performance Metrics**
  - Page load times
  - First Contentful Paint (FCP)
  - Largest Contentful Paint (LCP)
  - First Input Delay (FID)
  - Cumulative Layout Shift (CLS)

- **Error Tracking**
  - JavaScript errors
  - Network failures
  - Resource loading errors

- **User Interactions**
  - Click events
  - Navigation patterns
  - Session duration

### Flutter Web Integration

Add RUM monitoring to your Flutter web app:

```javascript
// Add to web/index.html
import { AwsRum } from 'aws-rum-web';

try {
  const config = {
    sessionSampleRate: 1.0,
    identityPoolId: 'COGNITO_IDENTITY_POOL_ID',
    endpoint: 'https://dataplane.rum.us-east-1.amazonaws.com',
    telemetries: ['performance','errors','http'],
    allowCookies: true,
    enableXRay: false
  };

  const APPLICATION_ID = 'YOUR_RUM_APPLICATION_ID';
  const APPLICATION_VERSION = '1.0.0';
  const APPLICATION_REGION = 'us-east-1';

  const awsRum = new AwsRum(
    APPLICATION_ID,
    APPLICATION_VERSION,
    APPLICATION_REGION,
    config
  );
} catch (error) {
  console.log('RUM initialization failed:', error);
}
```

### Cost Monitoring

Each environment includes cost allocation tags and budget monitoring:

- **Development**: $50/month budget
- **Staging**: $100/month budget  
- **Production**: $500/month budget

Monitor costs in AWS Cost Explorer using these tags:
- `Project: MinecraftOreFinder`
- `Environment: dev|staging|prod`
- `CostCenter: Engineering-Development`

## 💰 Cost Optimization

### S3 Optimization
- **Intelligent Tiering**: Automatic cost optimization
- **Lifecycle Policies**: Delete old versions after 90 days
- **Compression**: Gzip compression for text assets

### CloudFront Optimization
- **Price Class**: Optimized for target regions
- **Caching Strategies**: Long cache for static assets
- **Compression**: Automatic compression enabled

### RUM Cost Control
- **Sampling Rates**: 
  - Development: 10%
  - Staging: 50%
  - Production: 100% (with cost monitoring)

### Resource Cleanup
```bash
# Clean up old CDK assets
aws s3 ls | grep cdk-hnb659fds
aws s3 rb s3://cdk-hnb659fds-assets-ACCOUNT-REGION --force

# Clean up old CloudFormation stacks
aws cloudformation list-stacks --stack-status-filter DELETE_COMPLETE
```

## 🔒 Security Best Practices

### Infrastructure Security

- **S3 Bucket Security**
  - Block all public access
  - CloudFront-only access via OAC
  - Versioning enabled for rollback
  - Server-side encryption enabled

- **CloudFront Security**
  - HTTPS enforcement (redirect HTTP to HTTPS)
  - Security headers (HSTS, CSP, X-Frame-Options)
  - Origin Access Control (OAC) instead of deprecated OAI
  - Modern TLS versions only

- **Certificate Management**
  - Automatic SSL/TLS certificate provisioning
  - DNS validation for security
  - Automatic renewal
  - Certificate transparency logging

### Access Control

- **IAM Roles**: Least privilege principle
- **Cross-Account Access**: Minimal permissions with external ID
- **GitHub Actions**: Secure credential handling with OIDC
- **Resource Tagging**: Comprehensive tagging for compliance

### Security Monitoring

```bash
# Check S3 bucket policies
aws s3api get-bucket-policy --bucket YOUR-BUCKET-NAME

# Verify CloudFront security headers
curl -I https://your-domain.com

# Check certificate status
aws acm list-certificates --region us-east-1
```

## 🐛 Troubleshooting Guide

### Common Issues and Solutions

#### 1. Certificate Validation Timeout

**Problem**: ACM certificate validation takes too long or fails

**Solutions**:
```bash
# Check DNS propagation
dig TXT _acme-challenge.your-domain.com

# Verify Route53 records
aws route53 list-resource-record-sets --hosted-zone-id YOUR-ZONE-ID

# Check cross-account role permissions
aws sts assume-role --role-arn YOUR-CROSS-ACCOUNT-ROLE-ARN --role-session-name test
```

#### 2. Cross-Account Role Assumption Failed

**Problem**: Cannot assume cross-account role for DNS operations

**Solutions**:
```bash
# Verify role ARN format
echo "arn:aws:iam::ACCOUNT-ID:role/ROLE-NAME"

# Check trust policy
aws iam get-role --role-name CrossAccountDNSRole

# Test role assumption
aws sts assume-role \
  --role-arn arn:aws:iam::DNS-ACCOUNT:role/CrossAccountDNSRole \
  --role-session-name test-session
```

#### 3. Domain Not Resolving

**Problem**: Custom domain doesn't resolve to CloudFront

**Solutions**:
```bash
# Check DNS records
nslookup your-domain.com
dig your-domain.com

# Verify CloudFront distribution
aws cloudfront get-distribution --id YOUR-DISTRIBUTION-ID

# Check Route53 records
aws route53 list-resource-record-sets --hosted-zone-id YOUR-ZONE-ID
```

#### 4. Flutter Build Failures

**Problem**: Flutter web build fails in CI/CD

**Solutions**:
```bash
# Check Flutter version
flutter --version

# Clear Flutter cache
flutter clean
flutter pub get

# Build locally to test
flutter build web --release --web-renderer html
```

#### 5. CDK Deployment Failures

**Problem**: CDK deployment fails with various errors

**Solutions**:
```bash
# Check CDK version
cdk --version

# Bootstrap CDK
cdk bootstrap

# Check CloudFormation events
aws cloudformation describe-stack-events --stack-name YOUR-STACK-NAME

# Validate CDK template
cdk synth
```

#### 6. GitHub Actions Failures

**Problem**: GitHub Actions workflow fails

**Solutions**:
```bash
# Check required secrets are set
# AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, etc.

# Verify AWS credentials
aws sts get-caller-identity

# Check workflow permissions
# Ensure GITHUB_TOKEN has necessary permissions
```

### Debug Commands

```bash
# CDK debugging
cdk diff --verbose
cdk synth --verbose
cdk deploy --verbose

# AWS CLI debugging
aws --debug s3 ls
aws --debug cloudfront list-distributions

# Configuration validation
npm run validate-config --verbose

# Test deployment script
./scripts/deploy.sh -e dev -v --dry-run
```

### Log Analysis

#### CloudFormation Logs
```bash
# Get stack events
aws cloudformation describe-stack-events \
  --stack-name WebHostingStack-dev \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]'

# Get stack resources
aws cloudformation describe-stack-resources \
  --stack-name WebHostingStack-dev
```

#### CloudFront Logs
```bash
# Enable CloudFront logging (if needed)
aws cloudfront get-distribution-config --id YOUR-DISTRIBUTION-ID

# Check access logs in S3
aws s3 ls s3://your-cloudfront-logs-bucket/
```

#### GitHub Actions Logs
- Go to **Actions** tab in GitHub repository
- Click on failed workflow run
- Expand failed job steps
- Download logs for detailed analysis

### Getting Help

1. **Check Documentation**: Review this README and configuration docs
2. **Validate Configuration**: Run `npm run validate-config --verbose`
3. **Check AWS Status**: Visit [AWS Service Health Dashboard](https://status.aws.amazon.com/)
4. **Review Logs**: Check CloudFormation, CloudFront, and GitHub Actions logs
5. **Test Locally**: Use deployment script with verbose output
6. **Community Support**: Check AWS CDK GitHub issues and Stack Overflow

## 📚 Additional Resources

### Documentation
- [AWS CDK Documentation](https://docs.aws.amazon.com/cdk/)
- [CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
- [Route53 Documentation](https://docs.aws.amazon.com/route53/)
- [CloudWatch RUM Documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-RUM.html)

### Best Practices
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [CDK Best Practices](https://docs.aws.amazon.com/cdk/v2/guide/best-practices.html)
- [CloudFront Best Practices](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/best-practices.html)

### Tools and Utilities
- [AWS CLI](https://aws.amazon.com/cli/)
- [CDK CLI](https://docs.aws.amazon.com/cdk/v2/guide/cli.html)
- [Flutter SDK](https://flutter.dev/docs/get-started/install)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly in development environment
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.