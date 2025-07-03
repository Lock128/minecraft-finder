# Setup Guide

This comprehensive setup guide will walk you through configuring and deploying the AWS web hosting infrastructure for the Minecraft Ore Finder Flutter application.

## 📋 Prerequisites Checklist

Before starting, ensure you have the following:

### Required Tools
- [ ] **Node.js** 18+ and npm
- [ ] **AWS CLI** v2+ configured
- [ ] **AWS CDK CLI** v2+ (`npm install -g aws-cdk`)
- [ ] **Flutter SDK** 3.32+ (for local builds)
- [ ] **Git** for version control
- [ ] **jq** for JSON processing (optional but recommended)

### AWS Account Requirements
- [ ] **Primary AWS Account** with administrative access
- [ ] **Route53 Hosted Zone** for your domain (can be in same or different account)
- [ ] **AWS CLI configured** with appropriate credentials
- [ ] **Sufficient AWS permissions** (see detailed permissions below)

### Domain Requirements
- [ ] **Domain name** registered and managed in Route53
- [ ] **Hosted zone** created for your domain
- [ ] **Access to DNS management** (same account or cross-account role)

## 🚀 Quick Start (5 Minutes)

For experienced users who want to get started quickly:

```bash
# 1. Clone and setup
git clone <repository-url>
cd minecraft-ore-finder/infrastructure
npm install

# 2. Configure environment
cp config/dev.json.example config/dev.json
# Edit config/dev.json with your values

# 3. Bootstrap and deploy
npx cdk bootstrap
ENVIRONMENT=dev npm run deploy
```

## 📖 Detailed Setup Instructions

### Step 1: Environment Setup

#### 1.1 Install Required Tools

**Node.js and npm:**
```bash
# Check if already installed
node --version  # Should be 18+
npm --version

# Install via package manager (macOS)
brew install node

# Install via package manager (Ubuntu/Debian)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

**AWS CLI:**
```bash
# Check if already installed
aws --version  # Should be 2.0+

# Install via package manager (macOS)
brew install awscli

# Install via package manager (Ubuntu/Debian)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**AWS CDK CLI:**
```bash
# Install globally
npm install -g aws-cdk

# Verify installation
cdk --version  # Should be 2.120+
```

**Flutter SDK (for local builds):**
```bash
# Check if already installed
flutter --version  # Should be 3.32+

# Install via package manager (macOS)
brew install --cask flutter

# Or download from https://flutter.dev/docs/get-started/install
```

#### 1.2 Configure AWS CLI

```bash
# Configure AWS credentials
aws configure

# Enter your credentials:
# AWS Access Key ID: AKIA...
# AWS Secret Access Key: ...
# Default region name: us-east-1
# Default output format: json

# Verify configuration
aws sts get-caller-identity
```

### Step 2: Project Setup

#### 2.1 Clone Repository and Install Dependencies

```bash
# Clone the repository
git clone <repository-url>
cd minecraft-ore-finder

# Install infrastructure dependencies
cd infrastructure
npm install

# Verify installation
npm run build
npm test
```

#### 2.2 Validate Environment

```bash
# Check all tools are working
node --version
npm --version
aws --version
cdk --version
flutter --version

# Test AWS access
aws sts get-caller-identity
aws s3 ls  # Should not error (even if no buckets)
```

### Step 3: AWS Account Configuration

#### 3.1 Required AWS Permissions

Create an IAM policy with these permissions for your deployment user:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudformation:*",
        "s3:*",
        "cloudfront:*",
        "acm:*",
        "rum:*",
        "iam:*",
        "sts:AssumeRole",
        "route53:GetHostedZone",
        "route53:ListHostedZones"
      ],
      "Resource": "*"
    }
  ]
}
```

#### 3.2 CDK Bootstrap

Bootstrap CDK in your AWS account:

```bash
# Bootstrap with default settings
cdk bootstrap

# Or bootstrap with specific account/region
cdk bootstrap aws://123456789012/us-east-1

# Verify bootstrap
aws cloudformation describe-stacks --stack-name CDKToolkit
```

### Step 4: Domain and DNS Setup

#### 4.1 Route53 Hosted Zone Setup

If you don't already have a hosted zone:

```bash
# Create hosted zone (replace with your domain)
aws route53 create-hosted-zone \
  --name lockhead.cloud \
  --caller-reference $(date +%s)

# Get hosted zone ID
aws route53 list-hosted-zones \
  --query 'HostedZones[?Name==`lockhead.cloud.`].Id' \
  --output text
```

#### 4.2 Cross-Account DNS Setup (Optional)

If your Route53 hosted zone is in a different AWS account:

**In the DNS Account:**
```bash
# Create cross-account role
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

# Get role ARN
aws iam get-role --role-name CrossAccountDNSRole --query 'Role.Arn' --output text
```

**Test cross-account access:**
```bash
# From infrastructure account
aws sts assume-role \
  --role-arn arn:aws:iam::DNS-ACCOUNT-ID:role/CrossAccountDNSRole \
  --role-session-name test-session \
  --external-id minecraft-finder-dns-access
```

### Step 5: Configuration

#### 5.1 Environment Configuration

Create configuration files for each environment:

```bash
# Copy example configuration
cp config/dev.json.example config/dev.json

# Edit configuration
nano config/dev.json
```

#### 5.2 Required Configuration Updates

Update these values in your configuration files:

1. **Hosted Zone ID:**
   ```bash
   # Find your hosted zone ID
   aws route53 list-hosted-zones \
     --query 'HostedZones[?Name==`lockhead.cloud.`].Id' \
     --output text
   
   # Update in config file
   sed -i 's/REPLACE_WITH_HOSTED_ZONE_ID/Z1234567890ABC/' config/dev.json
   ```

2. **Cross-Account Role ARN (if applicable):**
   ```bash
   # Update with your cross-account role ARN
   sed -i 's|REPLACE_WITH_CROSS_ACCOUNT_ROLE_ARN|arn:aws:iam::123456789012:role/CrossAccountDNSRole|' config/dev.json
   ```

3. **Domain Names:**
   ```bash
   # Update domain names for each environment
   # dev.json: "dev-minecraft.lockhead.cloud"
   # staging.json: "staging-minecraft.lockhead.cloud"  
   # prod.json: "minecraft.lockhead.cloud"
   ```

#### 5.3 Validate Configuration

```bash
# Validate all configurations
npm run validate-config

# Validate specific environment
npm run validate-config dev

# Verbose validation
npm run validate-config --verbose
```

### Step 6: Initial Deployment

#### 6.1 Development Environment Deployment

```bash
# Deploy to development
ENVIRONMENT=dev npm run deploy

# Or use the deployment script
./scripts/deploy-dev.sh -v
```

#### 6.2 Verify Deployment

```bash
# Check stack status
aws cloudformation describe-stacks \
  --stack-name WebHostingStack-dev \
  --query 'Stacks[0].StackStatus'

# Get deployment outputs
cat cdk-outputs-dev.json

# Test the deployed infrastructure
curl -I https://$(jq -r '.["WebHostingStack-dev"].CloudFrontDomainName' cdk-outputs-dev.json)
```

### Step 7: GitHub Actions Setup (Optional)

#### 7.1 Configure GitHub Secrets

In your GitHub repository settings, add these secrets:

```bash
# Required secrets:
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_ACCOUNT_ID=123456789012
DOMAIN_NAME=dev-minecraft.lockhead.cloud
HOSTED_ZONE_ID=Z1234567890ABC
CROSS_ACCOUNT_ROLE_ARN=arn:aws:iam::123456789012:role/CrossAccountDNSRole
```

#### 7.2 Test GitHub Actions

```bash
# Push to main branch to trigger deployment
git add .
git commit -m "Initial setup"
git push origin main

# Or manually trigger workflow in GitHub Actions UI
```

## 🔧 Environment-Specific Setup

### Development Environment

**Purpose:** Quick iteration and testing
**Features:** 
- Lower cache TTLs for easier testing
- Basic monitoring to reduce costs
- Relaxed security for development convenience

```bash
# Quick development setup
cp config/dev.json.example config/dev.json
# Edit with your values
./scripts/deploy-dev.sh
```

### Staging Environment

**Purpose:** Production-like testing
**Features:**
- Production-like security settings
- Enhanced monitoring
- Performance optimization

```bash
# Staging setup with validation
cp config/dev.json config/staging.json
# Update environment-specific values
./scripts/deploy-staging.sh --verbose
```

### Production Environment

**Purpose:** Live application hosting
**Features:**
- Maximum security hardening
- Comprehensive monitoring
- Cost optimization
- Compliance tagging

```bash
# Production setup (use with caution)
cp config/staging.json config/prod.json
# Update for production settings
ENVIRONMENT=prod npm run deploy
```

## 🔒 Security Configuration

### IAM Roles and Policies

#### Deployment User Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudformation:*",
        "s3:*",
        "cloudfront:*",
        "acm:*",
        "rum:*",
        "iam:PassRole",
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "sts:AssumeRole"
      ],
      "Resource": "*"
    }
  ]
}
```

#### Cross-Account DNS Role Policy
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

### Security Best Practices

1. **Use least privilege IAM policies**
2. **Enable MFA for AWS accounts**
3. **Rotate access keys regularly**
4. **Use AWS Secrets Manager for sensitive data**
5. **Enable CloudTrail for audit logging**

## 💰 Cost Management Setup

### Budget Configuration

```bash
# Create budget for development environment
aws budgets create-budget \
  --account-id 123456789012 \
  --budget '{
    "BudgetName": "MinecraftFinder-Dev-Budget",
    "BudgetLimit": {
      "Amount": "50",
      "Unit": "USD"
    },
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST",
    "CostFilters": {
      "TagKey": ["Project"],
      "TagValue": ["MinecraftOreFinder"]
    }
  }'
```

### Cost Monitoring

1. **Set up AWS Cost Explorer**
2. **Configure budget alerts**
3. **Use cost allocation tags**
4. **Monitor CloudFront and S3 usage**

## 📊 Monitoring Setup

### CloudWatch RUM Integration

The infrastructure automatically sets up CloudWatch RUM. To integrate with your Flutter app:

```javascript
// Add to web/index.html
import { AwsRum } from 'aws-rum-web';

const config = {
  sessionSampleRate: 1.0,
  identityPoolId: 'YOUR_IDENTITY_POOL_ID',
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
```

### CloudWatch Dashboards

```bash
# Create custom dashboard
aws cloudwatch put-dashboard \
  --dashboard-name "MinecraftFinder-Dev" \
  --dashboard-body file://dashboard-config.json
```

## 🧪 Testing and Validation

### Infrastructure Testing

```bash
# Run all tests
npm test

# Run specific test suites
npm test -- --testNamePattern="S3Bucket"
npm test -- --testNamePattern="CloudFront"

# Run tests with coverage
npm test -- --coverage
```

### End-to-End Testing

```bash
# Deploy to development
./scripts/deploy-dev.sh

# Test domain resolution
nslookup dev-minecraft.lockhead.cloud

# Test HTTPS certificate
curl -I https://dev-minecraft.lockhead.cloud

# Test CloudFront caching
curl -H "Cache-Control: no-cache" -I https://dev-minecraft.lockhead.cloud
```

## 🚨 Troubleshooting Common Setup Issues

### Issue: CDK Bootstrap Fails

**Solution:**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Check permissions
aws iam get-user
aws iam list-attached-user-policies --user-name YOUR_USERNAME

# Force re-bootstrap
cdk bootstrap --force
```

### Issue: Configuration Validation Fails

**Solution:**
```bash
# Check configuration syntax
jq . config/dev.json

# Validate specific issues
npm run validate-config dev --verbose

# Check for placeholder values
grep -n "REPLACE_WITH_" config/dev.json
```

### Issue: Cross-Account Role Assumption Fails

**Solution:**
```bash
# Test role assumption
aws sts assume-role \
  --role-arn "$(jq -r '.domainConfig.crossAccountRoleArn' config/dev.json)" \
  --role-session-name test-session \
  --external-id minecraft-finder-dns-access

# Check trust policy
aws iam get-role --role-name CrossAccountDNSRole
```

### Issue: Domain Resolution Problems

**Solution:**
```bash
# Check DNS propagation
dig dev-minecraft.lockhead.cloud

# Check Route53 records
aws route53 list-resource-record-sets \
  --hosted-zone-id "$(jq -r '.domainConfig.hostedZoneId' config/dev.json)"

# Test from different DNS servers
nslookup dev-minecraft.lockhead.cloud 8.8.8.8
```

## 📚 Next Steps

After successful setup:

1. **Deploy Flutter Application:**
   ```bash
   cd ../flutter_app
   flutter build web --release
   aws s3 sync build/web/ s3://YOUR_S3_BUCKET/
   ```

2. **Set up Monitoring:**
   - Configure CloudWatch alarms
   - Set up cost monitoring
   - Enable RUM in Flutter app

3. **Configure CI/CD:**
   - Set up GitHub Actions secrets
   - Test automated deployment
   - Configure branch protection rules

4. **Security Hardening:**
   - Review IAM policies
   - Enable additional security features
   - Set up security monitoring

5. **Performance Optimization:**
   - Configure CloudFront caching
   - Optimize Flutter build
   - Monitor Core Web Vitals

## 🤝 Getting Help

If you encounter issues during setup:

1. **Check the troubleshooting guide:** `TROUBLESHOOTING.md`
2. **Review AWS documentation:** Links in README.md
3. **Check configuration:** `npm run validate-config --verbose`
4. **Test components individually:** Use the debug commands above
5. **Seek community help:** Stack Overflow, AWS forums, GitHub issues

## 📄 Configuration Reference

For detailed configuration options, see:
- `config/README.md` - Configuration system documentation
- `config/*.json.example` - Example configuration files
- `src/types/config.ts` - Configuration schema and types

This setup guide should get you up and running with the AWS web hosting infrastructure. Take your time with each step and don't hesitate to refer to the troubleshooting guide if you encounter any issues.