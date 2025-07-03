# Quick Setup Guide for Flutter Web Deployment

## Current Status ✅

Your infrastructure is **ready for deployment** with these fixes applied:
- ✅ Flutter app builds successfully for web
- ✅ Infrastructure code compiles without errors
- ✅ All CDK constructs are properly configured

## Required Configuration Steps

### 1. Update Domain Configuration

You need to replace placeholder values in your config files:

```bash
# Edit the dev configuration
nano infrastructure/config/dev.json
```

Replace these values:
- `REPLACE_WITH_HOSTED_ZONE_ID` → Your actual Route53 hosted zone ID
- `REPLACE_WITH_CROSS_ACCOUNT_ROLE_ARN` → Your cross-account role ARN (or same account role)

### 2. Find Your Hosted Zone ID

```bash
# List your hosted zones
aws route53 list-hosted-zones

# Or find specific domain
aws route53 list-hosted-zones --query 'HostedZones[?Name==`lockhead.cloud.`].Id' --output text
```

### 3. Create Cross-Account Role (if needed)

If you're using the same AWS account for both infrastructure and DNS:

```bash
# Create a simple role for DNS management
aws iam create-role --role-name MinecraftFinderDNSRole --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "lambda.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}'

# Attach Route53 permissions
aws iam attach-role-policy \
  --role-name MinecraftFinderDNSRole \
  --policy-arn arn:aws:iam::aws:policy/Route53FullAccess
```

Then use: `arn:aws:iam::YOUR-ACCOUNT-ID:role/MinecraftFinderDNSRole`

### 4. Deploy to Development

```bash
cd infrastructure

# Install dependencies
npm install

# Deploy to dev environment
ENVIRONMENT=dev npm run deploy
```

## Alternative: Simplified Configuration

If you want to skip custom domains for now, you can modify the config to use CloudFront's default domain:

```json
{
  "domainConfig": {
    "domainName": "",
    "hostedZoneId": "",
    "crossAccountRoleArn": "",
    "certificateRegion": "us-east-1"
  }
}
```

This will deploy without custom domain setup and you can access via the CloudFront distribution URL.

## Next Steps After Deployment

1. **Get the CloudFront URL** from the CDK output
2. **Upload your Flutter web build** to the S3 bucket
3. **Test the application** in your browser
4. **Set up CI/CD** using the provided GitHub Actions workflow

## Troubleshooting

If deployment fails:
1. Check AWS credentials: `aws sts get-caller-identity`
2. Ensure CDK is bootstrapped: `npx cdk bootstrap`
3. Validate config: `npm run validate-config:dev`
4. Check CloudFormation events in AWS Console

## Files Fixed

The following issues were resolved:
- ✅ S3 bucket construct missing return statements
- ✅ CloudFront distribution API compatibility
- ✅ Monitoring dashboard CloudWatch imports
- ✅ TypeScript compilation errors

Your infrastructure is now ready for deployment! 🚀