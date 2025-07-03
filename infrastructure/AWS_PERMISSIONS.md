# AWS Permissions Guide

This document provides comprehensive information about AWS permissions required for deploying and managing the web hosting infrastructure.

## 🔐 Overview

The infrastructure requires specific AWS permissions across multiple services. This guide covers:
- Required permissions for deployment
- Cross-account setup for DNS management
- GitHub Actions permissions
- Security best practices
- Troubleshooting permission issues

## 📋 Required AWS Services

The infrastructure uses these AWS services:
- **CloudFormation** - Infrastructure as Code deployment
- **S3** - Static website hosting and CDK assets
- **CloudFront** - Content Delivery Network
- **ACM** - SSL/TLS certificates
- **Route53** - DNS management (cross-account)
- **CloudWatch RUM** - Real User Monitoring
- **IAM** - Identity and Access Management
- **STS** - Security Token Service (for cross-account access)

## 🏗️ Deployment Account Permissions

### Comprehensive IAM Policy

Create an IAM policy with these permissions for your deployment user/role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CloudFormationPermissions",
      "Effect": "Allow",
      "Action": [
        "cloudformation:CreateStack",
        "cloudformation:UpdateStack",
        "cloudformation:DeleteStack",
        "cloudformation:DescribeStacks",
        "cloudformation:DescribeStackEvents",
        "cloudformation:DescribeStackResources",
        "cloudformation:GetTemplate",
        "cloudformation:ListStacks",
        "cloudformation:ListStackResources",
        "cloudformation:ValidateTemplate",
        "cloudformation:CreateChangeSet",
        "cloudformation:DescribeChangeSet",
        "cloudformation:ExecuteChangeSet",
        "cloudformation:DeleteChangeSet",
        "cloudformation:ListChangeSets",
        "cloudformation:GetStackPolicy",
        "cloudformation:SetStackPolicy",
        "cloudformation:CancelUpdateStack",
        "cloudformation:ContinueUpdateRollback"
      ],
      "Resource": [
        "arn:aws:cloudformation:*:*:stack/WebHostingStack-*/*",
        "arn:aws:cloudformation:*:*:stack/CDKToolkit/*"
      ]
    },
    {
      "Sid": "S3Permissions",
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:GetBucketLocation",
        "s3:GetBucketPolicy",
        "s3:PutBucketPolicy",
        "s3:DeleteBucketPolicy",
        "s3:GetBucketVersioning",
        "s3:PutBucketVersioning",
        "s3:GetBucketWebsite",
        "s3:PutBucketWebsite",
        "s3:DeleteBucketWebsite",
        "s3:GetBucketCORS",
        "s3:PutBucketCORS",
        "s3:DeleteBucketCORS",
        "s3:GetBucketLifecycleConfiguration",
        "s3:PutBucketLifecycleConfiguration",
        "s3:DeleteBucketLifecycleConfiguration",
        "s3:GetBucketPublicAccessBlock",
        "s3:PutBucketPublicAccessBlock",
        "s3:GetBucketNotification",
        "s3:PutBucketNotification",
        "s3:GetBucketTagging",
        "s3:PutBucketTagging",
        "s3:DeleteBucketTagging",
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:GetObjectVersion",
        "s3:DeleteObjectVersion",
        "s3:ListBucketVersions"
      ],
      "Resource": [
        "arn:aws:s3:::minecraft-finder-*",
        "arn:aws:s3:::minecraft-finder-*/*",
        "arn:aws:s3:::cdk-*",
        "arn:aws:s3:::cdk-*/*"
      ]
    },
    {
      "Sid": "CloudFrontPermissions",
      "Effect": "Allow",
      "Action": [
        "cloudfront:CreateDistribution",
        "cloudfront:UpdateDistribution",
        "cloudfront:DeleteDistribution",
        "cloudfront:GetDistribution",
        "cloudfront:GetDistributionConfig",
        "cloudfront:ListDistributions",
        "cloudfront:CreateOriginAccessControl",
        "cloudfront:UpdateOriginAccessControl",
        "cloudfront:DeleteOriginAccessControl",
        "cloudfront:GetOriginAccessControl",
        "cloudfront:GetOriginAccessControlConfig",
        "cloudfront:ListOriginAccessControls",
        "cloudfront:CreateInvalidation",
        "cloudfront:GetInvalidation",
        "cloudfront:ListInvalidations",
        "cloudfront:TagResource",
        "cloudfront:UntagResource",
        "cloudfront:ListTagsForResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ACMPermissions",
      "Effect": "Allow",
      "Action": [
        "acm:RequestCertificate",
        "acm:DeleteCertificate",
        "acm:DescribeCertificate",
        "acm:ListCertificates",
        "acm:GetCertificate",
        "acm:AddTagsToCertificate",
        "acm:RemoveTagsFromCertificate",
        "acm:ListTagsForCertificate"
      ],
      "Resource": "*"
    },
    {
      "Sid": "RUMPermissions",
      "Effect": "Allow",
      "Action": [
        "rum:CreateAppMonitor",
        "rum:UpdateAppMonitor",
        "rum:DeleteAppMonitor",
        "rum:GetAppMonitor",
        "rum:ListAppMonitors",
        "rum:TagResource",
        "rum:UntagResource",
        "rum:ListTagsForResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMPermissions",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:PassRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:GetRolePolicy",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:ListRoleTags"
      ],
      "Resource": [
        "arn:aws:iam::*:role/WebHostingStack-*",
        "arn:aws:iam::*:role/cdk-*"
      ]
    },
    {
      "Sid": "STSPermissions",
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole",
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Route53ReadPermissions",
      "Effect": "Allow",
      "Action": [
        "route53:GetHostedZone",
        "route53:ListHostedZones"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchPermissions",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Resource": "arn:aws:logs:*:*:log-group:/aws/lambda/WebHostingStack-*"
    }
  ]
}
```

### Minimal IAM Policy (Development Only)

For development environments, you can use a more permissive policy:

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
        "sts:*",
        "route53:GetHostedZone",
        "route53:ListHostedZones",
        "logs:*"
      ],
      "Resource": "*"
    }
  ]
}
```

**⚠️ Warning:** Only use the minimal policy for development. Production should use the comprehensive policy with specific resource restrictions.

## 🌐 Cross-Account DNS Setup

### DNS Account Configuration

If your Route53 hosted zone is in a different AWS account, set up cross-account access:

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
  --assume-role-policy-document file://trust-policy.json \
  --description "Cross-account role for Minecraft Finder DNS management"
```

#### 2. Attach Route53 Permissions

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

```bash
# Create and attach the policy
aws iam create-policy \
  --policy-name CrossAccountDNSPolicy \
  --policy-document file://dns-policy.json

aws iam attach-role-policy \
  --role-name CrossAccountDNSRole \
  --policy-arn arn:aws:iam::DNS-ACCOUNT-ID:policy/CrossAccountDNSPolicy
```

#### 3. Test Cross-Account Access

```bash
# Test role assumption from infrastructure account
aws sts assume-role \
  --role-arn arn:aws:iam::DNS-ACCOUNT-ID:role/CrossAccountDNSRole \
  --role-session-name test-session \
  --external-id minecraft-finder-dns-access

# Test Route53 access with temporary credentials
export AWS_ACCESS_KEY_ID=temp_key_from_assume_role
export AWS_SECRET_ACCESS_KEY=temp_secret_from_assume_role
export AWS_SESSION_TOKEN=temp_token_from_assume_role

aws route53 list-hosted-zones
```

## 🤖 GitHub Actions Permissions

### Required GitHub Secrets

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

### GitHub Actions IAM User

Create a dedicated IAM user for GitHub Actions:

```bash
# Create IAM user
aws iam create-user --user-name github-actions-minecraft-finder

# Attach the deployment policy
aws iam attach-user-policy \
  --user-name github-actions-minecraft-finder \
  --policy-arn arn:aws:iam::ACCOUNT-ID:policy/MinecraftFinderDeploymentPolicy

# Create access keys
aws iam create-access-key --user-name github-actions-minecraft-finder
```

### OIDC Provider Setup (Recommended)

For enhanced security, use OIDC instead of long-lived access keys:

```bash
# Create OIDC provider
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# Create role for GitHub Actions
cat > github-actions-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT-ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR-GITHUB-USERNAME/minecraft-ore-finder:*"
        }
      }
    }
  ]
}
EOF

aws iam create-role \
  --role-name GitHubActionsRole \
  --assume-role-policy-document file://github-actions-trust-policy.json
```

## 🔒 Security Best Practices

### Principle of Least Privilege

1. **Use specific resource ARNs** instead of wildcards where possible
2. **Limit actions** to only what's needed for deployment
3. **Use conditions** to restrict access based on context
4. **Regular audit** of permissions and access patterns

### Resource-Specific Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:*"],
      "Resource": [
        "arn:aws:s3:::minecraft-finder-web-*",
        "arn:aws:s3:::minecraft-finder-web-*/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": ["cloudformation:*"],
      "Resource": [
        "arn:aws:cloudformation:*:*:stack/WebHostingStack-*/*"
      ]
    }
  ]
}
```

### Conditional Access

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["sts:AssumeRole"],
      "Resource": "arn:aws:iam::*:role/CrossAccountDNSRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "minecraft-finder-dns-access"
        },
        "IpAddress": {
          "aws:SourceIp": ["203.0.113.0/24"]
        }
      }
    }
  ]
}
```

### MFA Requirements

For production deployments, consider requiring MFA:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["*"],
      "Resource": "*",
      "Condition": {
        "Bool": {
          "aws:MultiFactorAuthPresent": "true"
        },
        "NumericLessThan": {
          "aws:MultiFactorAuthAge": "3600"
        }
      }
    }
  ]
}
```

## 🧪 Testing Permissions

### Permission Testing Script

```bash
#!/bin/bash
# test-permissions.sh

echo "Testing AWS permissions for Minecraft Finder deployment..."

# Test basic AWS access
echo "1. Testing basic AWS access..."
aws sts get-caller-identity || exit 1

# Test S3 permissions
echo "2. Testing S3 permissions..."
aws s3 ls || exit 1

# Test CloudFormation permissions
echo "3. Testing CloudFormation permissions..."
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE || exit 1

# Test CloudFront permissions
echo "4. Testing CloudFront permissions..."
aws cloudfront list-distributions || exit 1

# Test ACM permissions
echo "5. Testing ACM permissions..."
aws acm list-certificates --region us-east-1 || exit 1

# Test RUM permissions
echo "6. Testing RUM permissions..."
aws rum list-app-monitors || exit 1

# Test cross-account role assumption (if configured)
if [[ -n "$CROSS_ACCOUNT_ROLE_ARN" ]]; then
    echo "7. Testing cross-account role assumption..."
    aws sts assume-role \
        --role-arn "$CROSS_ACCOUNT_ROLE_ARN" \
        --role-session-name permission-test \
        --external-id minecraft-finder-dns-access || exit 1
fi

echo "✅ All permission tests passed!"
```

### CDK Permission Test

```bash
# Test CDK bootstrap permissions
cdk bootstrap --show-template

# Test CDK synthesis (doesn't require AWS permissions)
cdk synth --context environment=dev

# Test CDK diff (requires read permissions)
cdk diff --context environment=dev
```

## 🚨 Troubleshooting Permission Issues

### Common Permission Errors

#### 1. "User is not authorized to perform: cloudformation:CreateStack"

**Solution:**
```bash
# Check CloudFormation permissions
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::ACCOUNT-ID:user/USERNAME \
  --action-names cloudformation:CreateStack \
  --resource-arns arn:aws:cloudformation:us-east-1:ACCOUNT-ID:stack/WebHostingStack-dev/*
```

#### 2. "Access Denied" when assuming cross-account role

**Solution:**
```bash
# Check trust relationship
aws iam get-role --role-name CrossAccountDNSRole --query 'Role.AssumeRolePolicyDocument'

# Verify external ID
aws sts assume-role \
  --role-arn arn:aws:iam::DNS-ACCOUNT:role/CrossAccountDNSRole \
  --role-session-name test \
  --external-id minecraft-finder-dns-access
```

#### 3. "Certificate validation failed" due to Route53 permissions

**Solution:**
```bash
# Test Route53 access with assumed role
aws sts assume-role \
  --role-arn "$CROSS_ACCOUNT_ROLE_ARN" \
  --role-session-name cert-validation \
  --external-id minecraft-finder-dns-access

# Use temporary credentials to test Route53
export AWS_ACCESS_KEY_ID=temp_key
export AWS_SECRET_ACCESS_KEY=temp_secret
export AWS_SESSION_TOKEN=temp_token

aws route53 list-hosted-zones
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --change-batch file://test-change-batch.json
```

### Permission Debugging Commands

```bash
# Check current identity
aws sts get-caller-identity

# List attached policies for user
aws iam list-attached-user-policies --user-name USERNAME

# List attached policies for role
aws iam list-attached-role-policies --role-name ROLENAME

# Get policy document
aws iam get-policy --policy-arn POLICY_ARN
aws iam get-policy-version --policy-arn POLICY_ARN --version-id v1

# Simulate policy
aws iam simulate-principal-policy \
  --policy-source-arn USER_OR_ROLE_ARN \
  --action-names ACTION_NAME \
  --resource-arns RESOURCE_ARN
```

## 📋 Permission Checklist

Before deployment, verify:

- [ ] **AWS CLI configured** with appropriate credentials
- [ ] **Deployment user/role** has comprehensive IAM policy attached
- [ ] **Cross-account role** created in DNS account (if applicable)
- [ ] **Trust relationship** configured correctly
- [ ] **External ID** matches configuration
- [ ] **GitHub secrets** configured (for CI/CD)
- [ ] **Resource naming** follows policy restrictions
- [ ] **Regional restrictions** considered (certificates in us-east-1)
- [ ] **MFA requirements** met (if configured)
- [ ] **IP restrictions** considered (if configured)

## 🔄 Permission Maintenance

### Regular Tasks

1. **Monthly:**
   - Review access logs in CloudTrail
   - Audit unused permissions
   - Rotate access keys

2. **Quarterly:**
   - Review and update IAM policies
   - Test cross-account access
   - Validate GitHub Actions permissions

3. **Annually:**
   - Complete security audit
   - Review compliance requirements
   - Update documentation

### Automated Monitoring

Set up CloudWatch alarms for:
- Failed AssumeRole attempts
- Unusual API call patterns
- Permission denied errors

```bash
# Create CloudWatch alarm for failed role assumptions
aws cloudwatch put-metric-alarm \
  --alarm-name "FailedAssumeRole" \
  --alarm-description "Alert on failed cross-account role assumptions" \
  --metric-name "ErrorCount" \
  --namespace "AWS/CloudTrail" \
  --statistic "Sum" \
  --period 300 \
  --threshold 5 \
  --comparison-operator "GreaterThanThreshold"
```

This permissions guide should help you set up secure and appropriate access for your AWS web hosting infrastructure. Always follow the principle of least privilege and regularly audit your permissions.