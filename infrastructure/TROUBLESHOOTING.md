# Troubleshooting Guide

This comprehensive troubleshooting guide covers common issues, debugging techniques, and solutions for the AWS web hosting infrastructure.

## 🚨 Quick Diagnosis

### Health Check Commands

Run these commands to quickly diagnose common issues:

```bash
# Check CDK and AWS CLI versions
cdk --version
aws --version

# Verify AWS credentials
aws sts get-caller-identity

# Validate configuration
npm run validate-config

# Check CDK bootstrap status
cdk bootstrap --show-template

# Test cross-account role assumption
aws sts assume-role \
  --role-arn "$(jq -r '.domainConfig.crossAccountRoleArn' config/dev.json)" \
  --role-session-name troubleshooting-test
```

### Quick Status Check

```bash
# Check stack status
aws cloudformation describe-stacks \
  --stack-name WebHostingStack-dev \
  --query 'Stacks[0].StackStatus'

# Check CloudFront distribution status
aws cloudfront list-distributions \
  --query 'DistributionList.Items[?Comment==`minecraft-finder-cf-dev`].Status'

# Check certificate status
aws acm list-certificates \
  --region us-east-1 \
  --query 'CertificateSummaryList[?DomainName==`dev-minecraft.lockhead.cloud`].Status'
```

## 🔧 Common Issues and Solutions

### 1. Certificate Validation Issues

#### Problem: Certificate validation timeout or failure

**Symptoms:**
- CDK deployment hangs at certificate creation
- Error: "Certificate validation timed out"
- Certificate status remains "PENDING_VALIDATION"

**Root Causes:**
- DNS propagation delays
- Incorrect Route53 hosted zone configuration
- Cross-account role permission issues
- DNS validation records not created

**Solutions:**

1. **Check DNS propagation:**
   ```bash
   # Check if validation records exist
   dig TXT _acme-challenge.dev-minecraft.lockhead.cloud
   
   # Check from multiple DNS servers
   nslookup -type=TXT _acme-challenge.dev-minecraft.lockhead.cloud 8.8.8.8
   nslookup -type=TXT _acme-challenge.dev-minecraft.lockhead.cloud 1.1.1.1
   ```

2. **Verify Route53 configuration:**
   ```bash
   # List hosted zones
   aws route53 list-hosted-zones
   
   # Check specific hosted zone records
   aws route53 list-resource-record-sets \
     --hosted-zone-id YOUR_HOSTED_ZONE_ID \
     --query 'ResourceRecordSets[?Type==`TXT`]'
   ```

3. **Test cross-account role:**
   ```bash
   # Assume the cross-account role
   aws sts assume-role \
     --role-arn "arn:aws:iam::DNS-ACCOUNT:role/CrossAccountDNSRole" \
     --role-session-name certificate-validation-test
   
   # Use temporary credentials to test Route53 access
   export AWS_ACCESS_KEY_ID=temp_key
   export AWS_SECRET_ACCESS_KEY=temp_secret
   export AWS_SESSION_TOKEN=temp_token
   
   aws route53 list-hosted-zones
   ```

4. **Manual certificate validation:**
   ```bash
   # Get certificate ARN
   CERT_ARN=$(aws acm list-certificates \
     --region us-east-1 \
     --query 'CertificateSummaryList[0].CertificateArn' \
     --output text)
   
   # Get validation records
   aws acm describe-certificate \
     --certificate-arn $CERT_ARN \
     --region us-east-1 \
     --query 'Certificate.DomainValidationOptions'
   ```

### 2. Cross-Account Role Issues

#### Problem: Cannot assume cross-account role

**Symptoms:**
- Error: "User is not authorized to perform: sts:AssumeRole"
- Error: "Access denied when calling AssumeRole"
- DNS operations fail during deployment

**Root Causes:**
- Incorrect role ARN format
- Missing trust relationship
- Insufficient permissions on role
- External ID mismatch

**Solutions:**

1. **Verify role ARN format:**
   ```bash
   # Correct format
   arn:aws:iam::123456789012:role/CrossAccountDNSRole
   
   # Check your configuration
   jq -r '.domainConfig.crossAccountRoleArn' config/dev.json
   ```

2. **Check trust relationship:**
   ```bash
   # Get role trust policy
   aws iam get-role \
     --role-name CrossAccountDNSRole \
     --query 'Role.AssumeRolePolicyDocument'
   ```

   **Expected trust policy:**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "AWS": "arn:aws:iam::INFRASTRUCTURE-ACCOUNT:root"
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
   ```

3. **Verify role permissions:**
   ```bash
   # List attached policies
   aws iam list-attached-role-policies --role-name CrossAccountDNSRole
   
   # Check inline policies
   aws iam list-role-policies --role-name CrossAccountDNSRole
   ```

4. **Test role assumption:**
   ```bash
   # Test with external ID
   aws sts assume-role \
     --role-arn "arn:aws:iam::DNS-ACCOUNT:role/CrossAccountDNSRole" \
     --role-session-name test-session \
     --external-id "minecraft-finder-dns-access"
   ```

### 3. Domain Resolution Issues

#### Problem: Custom domain doesn't resolve to CloudFront

**Symptoms:**
- Domain returns DNS resolution errors
- Domain resolves to wrong IP address
- SSL certificate errors on custom domain

**Root Causes:**
- Missing or incorrect CNAME record
- DNS propagation delays
- CloudFront distribution not configured for custom domain
- Certificate not associated with distribution

**Solutions:**

1. **Check DNS records:**
   ```bash
   # Check CNAME record
   dig CNAME dev-minecraft.lockhead.cloud
   
   # Check A record (should point to CloudFront)
   dig A dev-minecraft.lockhead.cloud
   
   # Trace DNS resolution
   nslookup dev-minecraft.lockhead.cloud
   ```

2. **Verify CloudFront configuration:**
   ```bash
   # Get distribution details
   aws cloudfront get-distribution \
     --id YOUR_DISTRIBUTION_ID \
     --query 'Distribution.DistributionConfig.Aliases'
   
   # Check certificate association
   aws cloudfront get-distribution \
     --id YOUR_DISTRIBUTION_ID \
     --query 'Distribution.DistributionConfig.ViewerCertificate'
   ```

3. **Check Route53 records:**
   ```bash
   # List all records in hosted zone
   aws route53 list-resource-record-sets \
     --hosted-zone-id YOUR_HOSTED_ZONE_ID
   
   # Check specific CNAME record
   aws route53 list-resource-record-sets \
     --hosted-zone-id YOUR_HOSTED_ZONE_ID \
     --query 'ResourceRecordSets[?Name==`dev-minecraft.lockhead.cloud.`]'
   ```

4. **Test SSL certificate:**
   ```bash
   # Check certificate details
   openssl s_client -connect dev-minecraft.lockhead.cloud:443 -servername dev-minecraft.lockhead.cloud
   
   # Check certificate chain
   curl -vI https://dev-minecraft.lockhead.cloud
   ```

### 4. Flutter Build Issues

#### Problem: Flutter build fails in CI/CD or locally

**Symptoms:**
- Flutter build command fails
- Missing dependencies errors
- Web renderer issues
- Build artifacts not generated

**Root Causes:**
- Incorrect Flutter version
- Missing dependencies
- Build configuration issues
- Platform-specific problems

**Solutions:**

1. **Check Flutter installation:**
   ```bash
   # Check Flutter version
   flutter --version
   
   # Check Flutter doctor
   flutter doctor -v
   
   # Check web support
   flutter config --enable-web
   flutter devices
   ```

2. **Clean and rebuild:**
   ```bash
   cd flutter_app
   
   # Clean Flutter cache
   flutter clean
   
   # Get dependencies
   flutter pub get
   
   # Analyze code
   flutter analyze
   
   # Run tests
   flutter test
   
   # Build web
   flutter build web --release --web-renderer html --base-href /
   ```

3. **Check build configuration:**
   ```bash
   # Verify pubspec.yaml
   cat pubspec.yaml
   
   # Check web directory
   ls -la web/
   
   # Verify index.html
   cat web/index.html
   ```

4. **Debug build issues:**
   ```bash
   # Build with verbose output
   flutter build web --verbose --release
   
   # Check build output
   ls -la build/web/
   
   # Verify build artifacts
   file build/web/main.dart.js
   ```

### 5. CDK Deployment Failures

#### Problem: CDK deployment fails with various errors

**Symptoms:**
- CloudFormation stack creation/update fails
- Resource creation errors
- Rollback scenarios
- Timeout errors

**Root Causes:**
- Insufficient AWS permissions
- Resource naming conflicts
- Dependency issues
- Configuration errors

**Solutions:**

1. **Check CDK version and bootstrap:**
   ```bash
   # Check CDK version
   cdk --version
   
   # Check bootstrap status
   cdk bootstrap --show-template
   
   # Re-bootstrap if needed
   cdk bootstrap --force
   ```

2. **Validate CDK template:**
   ```bash
   # Synthesize template
   cdk synth --context environment=dev
   
   # Validate template
   aws cloudformation validate-template \
     --template-body file://cdk.out/WebHostingStack-dev.template.json
   ```

3. **Check CloudFormation events:**
   ```bash
   # Get stack events
   aws cloudformation describe-stack-events \
     --stack-name WebHostingStack-dev \
     --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]'
   
   # Get detailed error messages
   aws cloudformation describe-stack-events \
     --stack-name WebHostingStack-dev \
     --query 'StackEvents[?ResourceStatusReason!=null].{Resource:LogicalResourceId,Status:ResourceStatus,Reason:ResourceStatusReason}'
   ```

4. **Debug resource conflicts:**
   ```bash
   # Check for existing resources
   aws s3 ls | grep minecraft-finder
   aws cloudfront list-distributions --query 'DistributionList.Items[?Comment==`minecraft-finder-cf-dev`]'
   
   # Check resource limits
   aws service-quotas get-service-quota \
     --service-code cloudfront \
     --quota-code L-24B04930
   ```

### 6. GitHub Actions Failures

#### Problem: GitHub Actions workflow fails

**Symptoms:**
- Workflow fails at various steps
- Authentication errors
- Build or deployment failures
- Timeout issues

**Root Causes:**
- Missing or incorrect secrets
- Insufficient permissions
- Environment configuration issues
- Resource conflicts

**Solutions:**

1. **Check GitHub secrets:**
   ```bash
   # Required secrets (check in GitHub repository settings):
   # - AWS_ACCESS_KEY_ID
   # - AWS_SECRET_ACCESS_KEY
   # - AWS_ACCOUNT_ID
   # - DOMAIN_NAME
   # - HOSTED_ZONE_ID
   # - CROSS_ACCOUNT_ROLE_ARN
   ```

2. **Verify AWS credentials:**
   ```bash
   # Test credentials locally
   aws sts get-caller-identity
   
   # Check permissions
   aws iam get-user
   aws iam list-attached-user-policies --user-name YOUR_USERNAME
   ```

3. **Debug workflow steps:**
   - Check individual job logs in GitHub Actions
   - Look for specific error messages
   - Verify environment variables are set
   - Check artifact uploads/downloads

4. **Test workflow locally:**
   ```bash
   # Use act to test GitHub Actions locally
   act -j build-flutter
   act -j deploy-infrastructure
   ```

### 7. S3 and CloudFront Issues

#### Problem: Assets not loading or caching issues

**Symptoms:**
- 403 Forbidden errors
- Assets not updating
- Cache not working properly
- CORS errors

**Root Causes:**
- Incorrect S3 bucket policies
- CloudFront cache settings
- Origin Access Control issues
- CORS configuration problems

**Solutions:**

1. **Check S3 bucket configuration:**
   ```bash
   # Check bucket policy
   aws s3api get-bucket-policy --bucket YOUR_BUCKET_NAME
   
   # Check public access block
   aws s3api get-public-access-block --bucket YOUR_BUCKET_NAME
   
   # Check CORS configuration
   aws s3api get-bucket-cors --bucket YOUR_BUCKET_NAME
   ```

2. **Verify CloudFront settings:**
   ```bash
   # Get distribution configuration
   aws cloudfront get-distribution-config --id YOUR_DISTRIBUTION_ID
   
   # Check cache behaviors
   aws cloudfront get-distribution-config \
     --id YOUR_DISTRIBUTION_ID \
     --query 'DistributionConfig.CacheBehaviors'
   
   # Check origin access control
   aws cloudfront get-distribution-config \
     --id YOUR_DISTRIBUTION_ID \
     --query 'DistributionConfig.Origins.Items[0].OriginAccessControlId'
   ```

3. **Test asset access:**
   ```bash
   # Test direct S3 access (should fail)
   curl -I https://YOUR_BUCKET_NAME.s3.amazonaws.com/index.html
   
   # Test CloudFront access (should work)
   curl -I https://YOUR_CLOUDFRONT_DOMAIN/index.html
   
   # Check cache headers
   curl -H "Cache-Control: no-cache" -I https://YOUR_CLOUDFRONT_DOMAIN/index.html
   ```

4. **Invalidate cache:**
   ```bash
   # Create invalidation
   aws cloudfront create-invalidation \
     --distribution-id YOUR_DISTRIBUTION_ID \
     --paths "/*"
   
   # Check invalidation status
   aws cloudfront list-invalidations --distribution-id YOUR_DISTRIBUTION_ID
   ```

## 🔍 Debugging Techniques

### Enable Verbose Logging

1. **CDK Verbose Mode:**
   ```bash
   cdk deploy --verbose --context environment=dev
   cdk diff --verbose --context environment=dev
   ```

2. **AWS CLI Debug Mode:**
   ```bash
   aws --debug cloudformation describe-stacks --stack-name WebHostingStack-dev
   aws --debug s3 ls s3://your-bucket-name/
   ```

3. **NPM Debug Mode:**
   ```bash
   DEBUG=* npm run deploy
   npm run validate-config --verbose
   ```

### Log Analysis

1. **CloudFormation Logs:**
   ```bash
   # Get all stack events
   aws cloudformation describe-stack-events --stack-name WebHostingStack-dev
   
   # Filter failed events
   aws cloudformation describe-stack-events \
     --stack-name WebHostingStack-dev \
     --query 'StackEvents[?contains(ResourceStatus, `FAILED`)]'
   ```

2. **CloudFront Logs:**
   ```bash
   # Enable CloudFront logging (if not already enabled)
   aws cloudfront get-distribution-config --id YOUR_DISTRIBUTION_ID
   
   # Check access logs
   aws s3 ls s3://your-cloudfront-logs-bucket/ --recursive
   ```

3. **GitHub Actions Logs:**
   - Download workflow logs from GitHub Actions UI
   - Check individual step outputs
   - Look for environment variable issues

### Network Debugging

1. **DNS Resolution:**
   ```bash
   # Check DNS propagation
   dig +trace dev-minecraft.lockhead.cloud
   
   # Check from different locations
   nslookup dev-minecraft.lockhead.cloud 8.8.8.8
   nslookup dev-minecraft.lockhead.cloud 1.1.1.1
   ```

2. **SSL/TLS Testing:**
   ```bash
   # Test SSL certificate
   openssl s_client -connect dev-minecraft.lockhead.cloud:443
   
   # Check certificate chain
   curl -vI https://dev-minecraft.lockhead.cloud
   
   # Test with different TLS versions
   openssl s_client -tls1_2 -connect dev-minecraft.lockhead.cloud:443
   ```

3. **HTTP Testing:**
   ```bash
   # Test with curl
   curl -vI https://dev-minecraft.lockhead.cloud
   
   # Test with different user agents
   curl -H "User-Agent: Mozilla/5.0" https://dev-minecraft.lockhead.cloud
   
   # Test CORS
   curl -H "Origin: https://example.com" \
        -H "Access-Control-Request-Method: GET" \
        -H "Access-Control-Request-Headers: X-Requested-With" \
        -X OPTIONS \
        https://dev-minecraft.lockhead.cloud
   ```

## 🚨 Emergency Procedures

### Rollback Deployment

1. **CDK Rollback:**
   ```bash
   # Get previous stack template
   aws cloudformation get-template \
     --stack-name WebHostingStack-dev \
     --template-stage Processed
   
   # Rollback to previous version
   cdk deploy --rollback
   ```

2. **Manual CloudFormation Rollback:**
   ```bash
   # Cancel current update
   aws cloudformation cancel-update-stack --stack-name WebHostingStack-dev
   
   # Continue rollback if stuck
   aws cloudformation continue-update-rollback --stack-name WebHostingStack-dev
   ```

### Emergency Asset Restoration

1. **Restore from S3 Versions:**
   ```bash
   # List object versions
   aws s3api list-object-versions --bucket YOUR_BUCKET_NAME --prefix index.html
   
   # Restore previous version
   aws s3api copy-object \
     --copy-source YOUR_BUCKET_NAME/index.html?versionId=VERSION_ID \
     --bucket YOUR_BUCKET_NAME \
     --key index.html
   ```

2. **Emergency Cache Clear:**
   ```bash
   # Immediate cache invalidation
   aws cloudfront create-invalidation \
     --distribution-id YOUR_DISTRIBUTION_ID \
     --paths "/*"
   ```

### Service Recovery

1. **Recreate Critical Resources:**
   ```bash
   # Recreate S3 bucket (if deleted)
   aws s3 mb s3://your-bucket-name
   
   # Recreate CloudFront distribution (if needed)
   # Use CDK to recreate: cdk deploy --force
   ```

2. **DNS Recovery:**
   ```bash
   # Recreate DNS records
   aws route53 change-resource-record-sets \
     --hosted-zone-id YOUR_HOSTED_ZONE_ID \
     --change-batch file://dns-change-batch.json
   ```

## 📞 Getting Help

### Self-Service Resources

1. **Documentation:**
   - [AWS CDK Documentation](https://docs.aws.amazon.com/cdk/)
   - [CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
   - [Route53 Documentation](https://docs.aws.amazon.com/route53/)

2. **AWS Support:**
   - AWS Support Center (if you have a support plan)
   - AWS Forums
   - AWS re:Post

3. **Community Resources:**
   - Stack Overflow (tag: aws-cdk, cloudfront, route53)
   - GitHub Issues for AWS CDK
   - Reddit r/aws

### Escalation Process

1. **Level 1 - Self-Service:**
   - Check this troubleshooting guide
   - Review AWS documentation
   - Search community forums

2. **Level 2 - Team Support:**
   - Contact your team lead or DevOps engineer
   - Review with infrastructure team
   - Check internal documentation

3. **Level 3 - AWS Support:**
   - Open AWS Support case (if available)
   - Provide detailed error logs
   - Include CloudFormation stack events

### Information to Collect

When seeking help, collect this information:

1. **Environment Details:**
   ```bash
   # System information
   uname -a
   node --version
   npm --version
   cdk --version
   aws --version
   
   # AWS account and region
   aws sts get-caller-identity
   echo $AWS_REGION
   ```

2. **Error Information:**
   - Complete error messages
   - CloudFormation stack events
   - GitHub Actions workflow logs
   - CDK deployment output

3. **Configuration:**
   - Sanitized configuration files (remove sensitive data)
   - CDK synthesized templates
   - AWS resource configurations

4. **Timeline:**
   - When the issue started
   - Recent changes made
   - Steps taken to resolve

## 🔧 Preventive Measures

### Regular Maintenance

1. **Weekly Checks:**
   ```bash
   # Check certificate expiration
   aws acm list-certificates --region us-east-1
   
   # Check CloudFront distribution health
   aws cloudfront list-distributions
   
   # Check S3 bucket metrics
   aws s3api get-bucket-metrics-configuration --bucket YOUR_BUCKET_NAME
   ```

2. **Monthly Reviews:**
   - Review AWS costs and usage
   - Update dependencies (CDK, Node.js, Flutter)
   - Review security configurations
   - Test disaster recovery procedures

3. **Quarterly Audits:**
   - Security audit of IAM roles and policies
   - Performance review of CloudFront metrics
   - Cost optimization review
   - Documentation updates

### Monitoring and Alerting

1. **Set up CloudWatch Alarms:**
   ```bash
   # CloudFront error rate alarm
   aws cloudwatch put-metric-alarm \
     --alarm-name "CloudFront-HighErrorRate" \
     --alarm-description "CloudFront 4xx/5xx error rate too high" \
     --metric-name "4xxErrorRate" \
     --namespace "AWS/CloudFront" \
     --statistic "Average" \
     --period 300 \
     --threshold 5.0 \
     --comparison-operator "GreaterThanThreshold"
   ```

2. **Cost Monitoring:**
   - Set up AWS Budgets for each environment
   - Configure cost anomaly detection
   - Review Cost Explorer regularly

3. **Health Checks:**
   - Set up Route53 health checks for custom domains
   - Monitor certificate expiration dates
   - Track deployment success rates

This troubleshooting guide should help you diagnose and resolve most common issues with the AWS web hosting infrastructure. Keep it updated as you encounter and resolve new issues.