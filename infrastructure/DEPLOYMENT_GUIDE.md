# Deployment Guide

This comprehensive deployment guide covers all aspects of deploying the AWS web hosting infrastructure for the Minecraft Ore Finder Flutter application.

## 🚀 Quick Deployment

### One-Command Deployment

```bash
# Development environment
./scripts/deploy-dev.sh

# Staging environment  
./scripts/deploy-staging.sh

# Production environment (use with caution)
ENVIRONMENT=prod npm run deploy
```

### Prerequisites Check

```bash
# Verify all tools are installed
node --version    # Should be 18+
npm --version
aws --version     # Should be 2.0+
cdk --version     # Should be 2.120+
flutter --version # Should be 3.32+

# Verify AWS access
aws sts get-caller-identity
```

## 📋 Deployment Options

### 1. Local Development Deployment

**Best for:** Quick iteration and testing

```bash
# Quick development deployment
cd infrastructure
./scripts/deploy-dev.sh

# With options
./scripts/deploy-dev.sh -s -v  # Skip build, verbose output
```

**Features:**
- Fast deployment (5-10 minutes)
- Lower cache TTLs for easier testing
- Basic monitoring to reduce costs
- Random resource suffixes for uniqueness

### 2. Staging Deployment

**Best for:** Production-like testing

```bash
# Full staging deployment with validation
cd infrastructure
./scripts/deploy-staging.sh --verbose

# Dry run to see what would be deployed
./scripts/deploy-staging.sh --dry-run
```

**Features:**
- Production-like security settings
- Enhanced monitoring and logging
- Performance optimization features
- Comprehensive validation

### 3. Production Deployment

**Best for:** Live application hosting

```bash
# Production deployment (requires careful consideration)
cd infrastructure
ENVIRONMENT=prod npm run deploy

# Or use the main deployment script
../scripts/deploy.sh -e prod -v
```

**Features:**
- Maximum security hardening
- Comprehensive monitoring
- Cost optimization
- Compliance tagging

### 4. GitHub Actions Deployment

**Best for:** Automated CI/CD

**Automatic Triggers:**
- Push to `main` branch → Deploy to development
- Manual workflow dispatch → Choose environment

**Manual Trigger:**
1. Go to GitHub Actions tab
2. Select "Deploy Web Hosting Infrastructure"
3. Click "Run workflow"
4. Choose environment and options

## 🔧 Deployment Scripts

### Main Deployment Script (`scripts/deploy.sh`)

Comprehensive deployment script with full Flutter build and infrastructure deployment:

```bash
# Basic usage
./scripts/deploy.sh

# With options
./scripts/deploy.sh -e staging -v -s -t
```

**Options:**
- `-e, --environment ENV` - Target environment (dev|staging|prod)
- `-s, --skip-build` - Skip Flutter build process
- `-t, --skip-tests` - Skip running tests
- `-v, --verbose` - Enable verbose output
- `-h, --help` - Show help message

### Development Script (`infrastructure/scripts/deploy-dev.sh`)

Quick deployment script optimized for development:

```bash
# Quick development deployment
./scripts/deploy-dev.sh

# With options
./scripts/deploy-dev.sh -s -t -v
```

**Options:**
- `-s, --skip-build` - Skip Flutter build
- `-t, --skip-tests` - Skip tests
- `-v, --verbose` - Verbose output

### Staging Script (`infrastructure/scripts/deploy-staging.sh`)

Production-like deployment with comprehensive validation:

```bash
# Full staging deployment
./scripts/deploy-staging.sh

# Dry run
./scripts/deploy-staging.sh --dry-run

# Skip validation (not recommended)
./scripts/deploy-staging.sh --skip-validation
```

**Options:**
- `--skip-validation` - Skip comprehensive validation
- `--dry-run` - Show deployment plan without deploying
- `-v, --verbose` - Verbose output

## 📊 Deployment Process

### Standard Deployment Flow

1. **Pre-deployment Validation**
   - Check required tools and versions
   - Validate AWS credentials and permissions
   - Validate configuration files
   - Check for placeholder values

2. **Flutter Application Build** (if not skipped)
   - Install Flutter dependencies
   - Run code analysis and tests
   - Build web application for production
   - Generate build information

3. **Infrastructure Deployment**
   - Install CDK dependencies
   - Build TypeScript code
   - Run infrastructure tests
   - Bootstrap CDK (if needed)
   - Deploy CDK stack

4. **Asset Deployment** (if Flutter build completed)
   - Upload static assets to S3
   - Set appropriate cache headers
   - Invalidate CloudFront cache

5. **Post-deployment Validation**
   - Verify stack deployment
   - Test domain resolution
   - Validate SSL certificates
   - Check monitoring setup

### Deployment Timeline

| Environment | Typical Duration | Components |
|-------------|------------------|------------|
| Development | 5-10 minutes | Basic infrastructure, minimal validation |
| Staging | 15-25 minutes | Full infrastructure, comprehensive validation |
| Production | 20-30 minutes | Full infrastructure, security validation, monitoring |

## 🔍 Monitoring Deployment

### Real-time Monitoring

```bash
# Watch CloudFormation events
aws cloudformation describe-stack-events \
  --stack-name WebHostingStack-dev \
  --query 'StackEvents[0:10].[Timestamp,ResourceStatus,ResourceType,LogicalResourceId]' \
  --output table

# Monitor CDK deployment
cdk deploy --progress events --verbose

# Watch S3 sync progress
aws s3 sync build/web/ s3://bucket-name/ --dryrun
```

### Deployment Logs

```bash
# CDK deployment logs
tail -f ~/.cdk/logs/cdk.log

# CloudFormation stack events
aws logs tail /aws/cloudformation/WebHostingStack-dev --follow

# GitHub Actions logs (download from UI)
```

## 🚨 Deployment Troubleshooting

### Common Issues

#### 1. Configuration Validation Fails

```bash
# Check configuration syntax
jq . config/dev.json

# Validate configuration
npm run validate-config dev --verbose

# Check for placeholder values
grep -n "REPLACE_WITH_" config/dev.json
```

#### 2. CDK Bootstrap Issues

```bash
# Check bootstrap status
cdk bootstrap --show-template

# Force re-bootstrap
cdk bootstrap --force

# Check bootstrap stack
aws cloudformation describe-stacks --stack-name CDKToolkit
```

#### 3. Certificate Validation Timeout

```bash
# Check DNS propagation
dig TXT _acme-challenge.dev-minecraft.lockhead.cloud

# Test cross-account role
aws sts assume-role \
  --role-arn "$(jq -r '.domainConfig.crossAccountRoleArn' config/dev.json)" \
  --role-session-name test-session
```

#### 4. Asset Upload Failures

```bash
# Check S3 bucket permissions
aws s3api get-bucket-policy --bucket YOUR_BUCKET_NAME

# Test S3 access
aws s3 ls s3://YOUR_BUCKET_NAME/

# Check CloudFront distribution
aws cloudfront get-distribution --id YOUR_DISTRIBUTION_ID
```

### Debug Commands

```bash
# CDK debugging
cdk diff --verbose --context environment=dev
cdk synth --verbose --context environment=dev

# AWS CLI debugging
aws --debug cloudformation describe-stacks --stack-name WebHostingStack-dev

# Configuration debugging
npm run validate-config --verbose
```

## 🔄 Rollback Procedures

### CDK Rollback

```bash
# Automatic rollback on failure
cdk deploy --rollback

# Manual rollback to previous version
aws cloudformation cancel-update-stack --stack-name WebHostingStack-dev
aws cloudformation continue-update-rollback --stack-name WebHostingStack-dev
```

### Asset Rollback

```bash
# List S3 object versions
aws s3api list-object-versions --bucket YOUR_BUCKET_NAME --prefix index.html

# Restore previous version
aws s3api copy-object \
  --copy-source YOUR_BUCKET_NAME/index.html?versionId=VERSION_ID \
  --bucket YOUR_BUCKET_NAME \
  --key index.html

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

### Emergency Procedures

```bash
# Emergency cache clear
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"

# Emergency DNS change (if needed)
aws route53 change-resource-record-sets \
  --hosted-zone-id YOUR_HOSTED_ZONE_ID \
  --change-batch file://emergency-dns-change.json

# Stack deletion (last resort)
cdk destroy WebHostingStack-dev --force
```

## 📈 Post-Deployment Tasks

### Immediate Verification

```bash
# Test domain resolution
nslookup dev-minecraft.lockhead.cloud

# Test HTTPS certificate
curl -I https://dev-minecraft.lockhead.cloud

# Test application loading
curl -s https://dev-minecraft.lockhead.cloud | grep -o '<title>.*</title>'

# Check CloudFront caching
curl -H "Cache-Control: no-cache" -I https://dev-minecraft.lockhead.cloud
```

### Monitoring Setup

```bash
# Check RUM application
aws rum get-app-monitor --name minecraft-finder-dev

# Verify CloudWatch metrics
aws cloudwatch list-metrics --namespace AWS/CloudFront

# Check cost allocation tags
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Project,Values=MinecraftOreFinder
```

### Performance Validation

```bash
# Test page load speed
curl -w "@curl-format.txt" -o /dev/null -s https://dev-minecraft.lockhead.cloud

# Check Core Web Vitals (use browser dev tools)
# - Largest Contentful Paint (LCP)
# - First Input Delay (FID)
# - Cumulative Layout Shift (CLS)

# Validate caching headers
curl -I https://dev-minecraft.lockhead.cloud/main.dart.js
```

## 🔒 Security Validation

### Post-Deployment Security Checks

```bash
# Check S3 bucket public access
aws s3api get-public-access-block --bucket YOUR_BUCKET_NAME

# Verify CloudFront security headers
curl -I https://dev-minecraft.lockhead.cloud | grep -E "(Strict-Transport-Security|X-Frame-Options|X-Content-Type-Options)"

# Test HTTPS enforcement
curl -I http://dev-minecraft.lockhead.cloud  # Should redirect to HTTPS

# Verify certificate
openssl s_client -connect dev-minecraft.lockhead.cloud:443 -servername dev-minecraft.lockhead.cloud
```

### Security Monitoring

```bash
# Enable CloudTrail (if not already enabled)
aws cloudtrail create-trail \
  --name minecraft-finder-audit-trail \
  --s3-bucket-name your-cloudtrail-bucket

# Set up security monitoring
aws cloudwatch put-metric-alarm \
  --alarm-name "UnauthorizedAPICallsAlarm" \
  --alarm-description "Alert on unauthorized API calls" \
  --metric-name "ErrorCount" \
  --namespace "CloudWatchLogs" \
  --statistic "Sum" \
  --period 300 \
  --threshold 1 \
  --comparison-operator "GreaterThanOrEqualToThreshold"
```

## 💰 Cost Monitoring

### Post-Deployment Cost Setup

```bash
# Create budget for environment
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget file://budget-config.json

# Set up cost anomaly detection
aws ce create-anomaly-detector \
  --anomaly-detector file://anomaly-detector-config.json

# Monitor current costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

### Cost Optimization

```bash
# Check S3 storage classes
aws s3api list-objects-v2 --bucket YOUR_BUCKET_NAME --query 'Contents[].StorageClass'

# Monitor CloudFront cache hit ratio
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name CacheHitRate \
  --dimensions Name=DistributionId,Value=YOUR_DISTRIBUTION_ID \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-31T23:59:59Z \
  --period 86400 \
  --statistics Average

# Review RUM costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --filter file://rum-cost-filter.json
```

## 📚 Environment-Specific Considerations

### Development Environment

**Optimizations:**
- Lower cache TTLs for faster iteration
- Basic monitoring to reduce costs
- Random resource suffixes for uniqueness
- Relaxed security for development convenience

**Post-Deployment:**
- Test frequently with cache invalidation
- Monitor costs closely (budget: $50/month)
- Use for feature development and testing

### Staging Environment

**Optimizations:**
- Production-like settings for realistic testing
- Enhanced monitoring for performance validation
- Security hardening enabled
- Extended metrics for comprehensive testing

**Post-Deployment:**
- Comprehensive testing of all features
- Performance benchmarking
- Security validation
- Load testing preparation

### Production Environment

**Optimizations:**
- Maximum security hardening
- Comprehensive monitoring with cost-controlled sampling
- Optimized cache settings for performance
- Full compliance tagging

**Post-Deployment:**
- 24/7 monitoring setup
- Disaster recovery testing
- Performance optimization
- Regular security audits

## 🤝 Team Collaboration

### Deployment Responsibilities

| Role | Responsibilities |
|------|------------------|
| **Developer** | Local development deployment, feature testing |
| **DevOps Engineer** | Staging/production deployment, infrastructure maintenance |
| **QA Engineer** | Staging environment testing, performance validation |
| **Security Engineer** | Security validation, compliance checks |
| **Product Manager** | Production deployment approval, cost monitoring |

### Communication

```bash
# Deployment notifications (integrate with Slack/Teams)
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"🚀 Deployment to staging completed successfully!"}' \
  YOUR_SLACK_WEBHOOK_URL

# Status page updates (if applicable)
# Update status page with deployment information
```

## 📋 Deployment Checklist

### Pre-Deployment

- [ ] Configuration validated (`npm run validate-config`)
- [ ] AWS credentials configured and tested
- [ ] Cross-account role accessible (if applicable)
- [ ] Flutter application builds successfully
- [ ] All tests passing
- [ ] Security review completed (for production)
- [ ] Stakeholder approval obtained (for production)

### During Deployment

- [ ] Monitor deployment progress
- [ ] Watch for error messages
- [ ] Verify each deployment phase completes
- [ ] Check CloudFormation events
- [ ] Monitor resource creation

### Post-Deployment

- [ ] Domain resolution tested
- [ ] HTTPS certificate validated
- [ ] Application functionality verified
- [ ] Performance metrics checked
- [ ] Security headers validated
- [ ] Monitoring configured
- [ ] Cost tracking enabled
- [ ] Documentation updated
- [ ] Team notified of deployment

## 🔗 Related Documentation

- **[Setup Guide](SETUP.md)** - Initial setup and configuration
- **[Troubleshooting Guide](TROUBLESHOOTING.md)** - Common issues and solutions
- **[AWS Permissions Guide](AWS_PERMISSIONS.md)** - Required permissions and security
- **[Configuration Guide](config/README.md)** - Environment configuration details
- **[GitHub Actions Workflow](.github/workflows/deploy-web-hosting.yml)** - CI/CD pipeline

This deployment guide provides comprehensive coverage of all deployment scenarios and should serve as your primary reference for deploying the AWS web hosting infrastructure.