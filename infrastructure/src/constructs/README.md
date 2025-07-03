# AWS CDK Constructs

This directory contains custom AWS CDK constructs for the web hosting infrastructure.

## DNS Management Construct

The `DnsManagementConstruct` provides cross-account DNS management capabilities for Route53 operations.

### Features

- **Cross-account Route53 operations**: Manages DNS records in a Route53 hosted zone located in a different AWS account
- **CNAME record management**: Creates and manages CNAME records pointing custom subdomains to CloudFront distributions
- **Comprehensive error handling**: Includes proper error handling for cross-account failures and DNS propagation issues
- **Input validation**: Validates domain names, CloudFront domain names, hosted zone IDs, and IAM role ARNs
- **Automatic cleanup**: Handles cleanup of DNS records during stack deletion

### Usage

```typescript
import { DnsManagementConstruct } from './constructs/dns-management';

const dnsManagement = new DnsManagementConstruct(this, 'DnsManagement', {
  domainConfig: {
    domainName: 'app.minecraft.lockhead.cloud',
    hostedZoneId: 'Z1234567890ABC',
    crossAccountRoleArn: 'arn:aws:iam::987654321098:role/CrossAccountDNSRole',
    certificateRegion: 'us-east-1'
  },
  cloudFrontDomainName: 'd123456789.cloudfront.net',
  environment: 'prod',
  tags: {
    Environment: 'prod',
    Project: 'minecraft-finder'
  }
});
```

### Requirements

- The cross-account IAM role must have permissions to manage Route53 records in the target hosted zone
- The domain name must be within the hosted zone's domain
- The CloudFront domain name must be a valid CloudFront distribution domain

### Cross-Account Setup

The construct requires a cross-account IAM role in the DNS management account with the following permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:GetHostedZone",
        "route53:ListResourceRecordSets",
        "route53:ChangeResourceRecordSets",
        "route53:GetChange"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/Z1234567890ABC",
        "arn:aws:route53:::change/*"
      ]
    }
  ]
}
```

The role's trust policy must allow the application account to assume it:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### Error Handling

The construct includes comprehensive error handling for:

- Invalid input parameters (domain names, ARNs, etc.)
- Cross-account role assumption failures
- DNS record creation/deletion failures
- DNS propagation timeouts
- Hosted zone access issues

### Testing

The construct includes comprehensive unit tests covering:

- Input validation
- AWS resource creation
- Error handling scenarios
- Cross-account operations
- Lambda function code validation

Run tests with:

```bash
npm test -- --testPathPattern=dns-management.test.ts
```