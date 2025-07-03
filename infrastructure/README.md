# Minecraft Ore Finder - Web Hosting Infrastructure

This CDK project provides AWS infrastructure for hosting the Minecraft Ore Finder Flutter web application using S3, CloudFront, and CloudWatch RUM monitoring.

## Architecture

- **S3 Bucket**: Static website hosting for Flutter web build
- **CloudFront**: Global CDN with custom domain and SSL
- **ACM Certificate**: SSL/TLS certificate for custom domain
- **CloudWatch RUM**: Real user monitoring and analytics
- **Route53**: DNS management (cross-account)

## Prerequisites

- Node.js 18+ and npm
- AWS CLI configured with appropriate permissions
- AWS CDK CLI installed (`npm install -g aws-cdk`)
- Cross-account IAM role for DNS management

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Configure environment-specific settings in `config/` directory:
   - Update `hostedZoneId` with your Route53 hosted zone ID
   - Update `crossAccountRoleArn` with your cross-account role ARN
   - Adjust domain names and other settings as needed

3. Bootstrap CDK (if not already done):
   ```bash
   cdk bootstrap
   ```

## Configuration

The project uses environment-specific configuration files:

- `config/dev.json` - Development environment
- `config/staging.json` - Staging environment  
- `config/prod.json` - Production environment

### Required Configuration Updates

Before deployment, update the following placeholders in your config files:

- `REPLACE_WITH_HOSTED_ZONE_ID`: Your Route53 hosted zone ID
- `REPLACE_WITH_CROSS_ACCOUNT_ROLE_ARN`: ARN of the cross-account role for DNS operations

## Available Scripts

- `npm run build` - Compile TypeScript
- `npm run watch` - Watch mode compilation
- `npm run test` - Run unit tests
- `npm run lint` - Run ESLint
- `npm run cdk` - Run CDK commands
- `npm run deploy` - Deploy the stack
- `npm run destroy` - Destroy the stack

## Deployment

Set the environment and deploy:

```bash
# Development
ENVIRONMENT=dev npm run deploy

# Staging  
ENVIRONMENT=staging npm run deploy

# Production
ENVIRONMENT=prod npm run deploy
```

## Environment Variables

- `ENVIRONMENT` - Target environment (dev/staging/prod)
- `CDK_DEFAULT_ACCOUNT` - AWS account ID
- `CDK_DEFAULT_REGION` - AWS region

## Cross-Account Setup

This infrastructure requires cross-account access for DNS management. Ensure you have:

1. An IAM role in the DNS management account with Route53 permissions
2. Trust relationship allowing the deployment account to assume the role
3. The role ARN configured in your environment config files

## Monitoring

CloudWatch RUM is configured to collect:
- Page load performance metrics
- JavaScript errors
- User interaction data
- Core Web Vitals (LCP, FID, CLS)

## Cost Optimization

The infrastructure includes several cost optimization features:
- S3 lifecycle policies for old versions
- CloudFront caching strategies
- RUM sampling rates
- Appropriate storage classes

## Security

Security features implemented:
- S3 bucket with no public access
- CloudFront Origin Access Control (OAC)
- HTTPS enforcement
- Security headers
- Least privilege IAM policies

## Troubleshooting

Common issues and solutions:

1. **Certificate validation timeout**: Ensure DNS propagation is complete
2. **Cross-account role assumption failed**: Verify role ARN and trust policy
3. **Domain not resolving**: Check Route53 record creation

For more detailed troubleshooting, check the CDK deployment logs.