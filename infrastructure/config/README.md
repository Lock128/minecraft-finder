# Environment Configuration System

This directory contains environment-specific configuration files for the AWS web hosting infrastructure. The configuration system provides comprehensive management of deployment settings, resource naming, cost allocation, and environment-specific features.

## Configuration Files

- `dev.json` - Development environment configuration
- `staging.json` - Staging environment configuration  
- `prod.json` - Production environment configuration

## Configuration Structure

Each configuration file contains the following sections:

### Environment Configuration
```json
{
  "environmentConfig": {
    "name": "dev",
    "description": "Development environment for testing and development",
    "isProduction": false,
    "allowedRegions": ["us-east-1", "us-west-2"],
    "featureFlags": {
      "enableAdvancedMonitoring": false,
      "enableCostOptimization": true,
      "enableSecurityHardening": false,
      "enablePerformanceOptimization": false
    },
    "limits": {
      "maxCacheTtl": 86400,
      "maxRumSamplingRate": 0.5,
      "maxS3LifecycleDays": 90
    }
  }
}
```

### Domain Configuration
```json
{
  "domainConfig": {
    "domainName": "dev-minecraft.lockhead.cloud",
    "hostedZoneId": "REPLACE_WITH_HOSTED_ZONE_ID",
    "crossAccountRoleArn": "REPLACE_WITH_CROSS_ACCOUNT_ROLE_ARN",
    "certificateRegion": "us-east-1"
  }
}
```

### Resource Naming Configuration
```json
{
  "resourceNaming": {
    "resourcePrefix": "minecraft-finder",
    "resourceSuffix": "dev",
    "includeEnvironment": true,
    "includeRandomSuffix": true,
    "customPatterns": {
      "s3Bucket": "minecraft-finder-web-dev-{random}",
      "cloudFrontDistribution": "minecraft-finder-cf-dev",
      "certificate": "minecraft-finder-cert-dev",
      "rumApplication": "minecraft-finder-rum-dev"
    }
  }
}
```

### Cost Allocation Configuration
```json
{
  "costAllocation": {
    "costCenter": "Engineering-Development",
    "projectCode": "MINECRAFT-FINDER-DEV",
    "department": "Engineering",
    "budgetThreshold": 50,
    "enableDetailedBilling": true,
    "customCostTags": {
      "BillingGroup": "Development",
      "Owner": "DevTeam",
      "Purpose": "Development"
    }
  }
}
```

## Environment-Specific Features

### Development Environment
- **Lower cache TTLs** for easier testing
- **Basic monitoring** to reduce costs
- **Relaxed security** for development convenience
- **Higher lifecycle limits** for debugging
- **Random suffixes** for resource uniqueness

### Staging Environment
- **Production-like settings** for realistic testing
- **Enhanced monitoring** for performance validation
- **Security hardening enabled** for testing
- **Moderate resource limits**
- **Extended metrics** for comprehensive testing

### Production Environment
- **Optimized cache settings** for performance
- **Full monitoring** with cost-controlled sampling
- **Maximum security hardening**
- **Strict resource limits**
- **No random suffixes** for predictable naming
- **Comprehensive tagging** for compliance

## Configuration Validation

The configuration system includes comprehensive validation:

### Automatic Validation
- **Structure validation** - Ensures all required fields are present
- **Type validation** - Validates data types and formats
- **Environment limits** - Enforces environment-specific constraints
- **Security validation** - Checks for security best practices
- **Cost optimization** - Validates cost-effective settings

### Manual Validation
Use the validation CLI tool to check configurations:

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

## Setup Instructions

### 1. Replace Placeholder Values

Before deployment, replace the following placeholder values in each configuration file:

- `REPLACE_WITH_HOSTED_ZONE_ID` - Your Route53 hosted zone ID
- `REPLACE_WITH_CROSS_ACCOUNT_ROLE_ARN` - ARN of the cross-account role for DNS management

### 2. Customize Configuration

Adjust the following settings based on your requirements:

- **Domain names** - Set appropriate subdomains for each environment
- **Budget thresholds** - Set realistic budget limits
- **Cost centers** - Update with your organization's cost centers
- **Resource naming** - Customize prefixes and patterns
- **Feature flags** - Enable/disable features per environment

### 3. Validate Configuration

Always validate your configuration before deployment:

```bash
npm run validate-config
```

### 4. Deploy Infrastructure

Deploy using the CDK with environment-specific configuration:

```bash
# Deploy development environment
ENVIRONMENT=dev npm run deploy

# Deploy staging environment  
ENVIRONMENT=staging npm run deploy

# Deploy production environment
ENVIRONMENT=prod npm run deploy
```

## Cost Management

### Cost Allocation Tags

All resources are automatically tagged with cost allocation information:

- **CostCenter** - Department cost center
- **ProjectCode** - Project identifier for billing
- **Department** - Responsible department
- **BillingGroup** - Billing group classification
- **Environment** - Environment tier (dev/staging/prod)

### Budget Monitoring

Each environment can have a budget threshold configured:

- **Development**: $50/month (default)
- **Staging**: $100/month (default)
- **Production**: $500/month (default)

### Cost Optimization Features

- **S3 Lifecycle Rules** - Automatic transition to cheaper storage classes
- **CloudFront Caching** - Optimized cache settings to reduce origin requests
- **RUM Sampling** - Controlled sampling rates to manage monitoring costs
- **Resource Cleanup** - Automatic cleanup of old versions and unused resources

## Security Considerations

### Environment-Specific Security

- **Development**: Basic security for ease of development
- **Staging**: Production-like security for testing
- **Production**: Maximum security hardening

### Security Features

- **S3 Bucket Policies** - Block public access, CloudFront-only access
- **CloudFront Security** - HTTPS enforcement, security headers
- **Certificate Management** - Automatic SSL/TLS certificate provisioning
- **Cross-Account Access** - Secure role-based DNS management

### Compliance Tags

Production environments include compliance-related tags:

- **DataClassification** - Data sensitivity level
- **ComplianceRequired** - Whether compliance frameworks apply
- **BackupRequired** - Backup requirements
- **MonitoringLevel** - Required monitoring level

## Troubleshooting

### Common Issues

1. **Placeholder Values Not Replaced**
   - Error: "Missing or placeholder hosted zone ID"
   - Solution: Replace all `REPLACE_WITH_*` values with actual values

2. **Invalid Environment**
   - Error: "Invalid environment: xyz"
   - Solution: Use only 'dev', 'staging', or 'prod'

3. **Region Restrictions**
   - Error: "Region not allowed for environment"
   - Solution: Check `allowedRegions` in environment configuration

4. **Limit Violations**
   - Error: "Max TTL exceeds environment limit"
   - Solution: Adjust values to stay within environment limits

### Validation Errors

Run the validation tool to identify and fix configuration issues:

```bash
npm run validate-config --verbose
```

### Getting Help

- Check the validation report for detailed error descriptions
- Review the configuration schema in `src/types/config.ts`
- Examine working configurations in other environments
- Run tests to verify configuration loading: `npm test`

## Best Practices

### Configuration Management

1. **Version Control** - Always commit configuration changes
2. **Validation** - Validate before every deployment
3. **Documentation** - Document any custom changes
4. **Testing** - Test configuration changes in development first

### Environment Promotion

1. **Development → Staging** - Test all features and performance
2. **Staging → Production** - Validate security and compliance
3. **Rollback Plan** - Always have a rollback strategy

### Cost Management

1. **Regular Review** - Review costs monthly
2. **Budget Alerts** - Set up budget alerts for each environment
3. **Resource Cleanup** - Regularly clean up unused resources
4. **Optimization** - Continuously optimize based on usage patterns

### Security

1. **Least Privilege** - Use minimal required permissions
2. **Regular Audits** - Audit configurations quarterly
3. **Compliance** - Ensure production meets compliance requirements
4. **Monitoring** - Monitor for security events and anomalies