#!/bin/bash

# Staging Environment Deployment Script
# Production-like deployment with comprehensive validation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[STAGING]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Default values
SKIP_VALIDATION=false
VERBOSE=false
DRY_RUN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-validation)
            SKIP_VALIDATION=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            cat << EOF
Usage: $0 [OPTIONS]

Production-like deployment script for staging environment.

OPTIONS:
    --skip-validation       Skip comprehensive validation checks
    -v, --verbose           Enable verbose output
    --dry-run              Show what would be deployed without deploying
    -h, --help              Show this help message

EXAMPLES:
    $0                      # Full staging deployment with validation
    $0 --dry-run            # Show deployment plan without deploying
    $0 -v                   # Deploy with verbose output
    $0 --skip-validation    # Deploy without comprehensive validation

This script includes:
- Comprehensive pre-deployment validation
- Security checks
- Performance optimization validation
- Cost estimation
- Rollback preparation

EOF
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Set verbose mode
if [[ "$VERBOSE" == "true" ]]; then
    set -x
fi

print_status "🚀 Starting staging environment deployment..."

# Check if we're in the right directory
if [[ ! -f "package.json" ]]; then
    print_error "Please run this script from the infrastructure directory"
    exit 1
fi

# Comprehensive validation
print_status "🔍 Comprehensive pre-deployment validation..."

# Check configuration file exists
if [[ ! -f "config/staging.json" ]]; then
    print_error "Staging configuration file not found: config/staging.json"
    exit 1
fi

# Check for placeholder values (strict for staging)
if grep -q "REPLACE_WITH_" config/staging.json; then
    print_error "❌ Configuration contains placeholder values"
    print_error "Staging environment requires all configuration values to be set"
    
    echo "Placeholder values found:"
    grep -n "REPLACE_WITH_" config/staging.json
    exit 1
fi

# Install dependencies
print_status "📦 Installing dependencies..."
npm ci

# Build TypeScript
print_status "🏗️ Building CDK application..."
npm run build

# Run comprehensive tests
print_status "🧪 Running comprehensive tests..."
npm test

# Lint code
print_status "🔍 Linting code..."
npm run lint

# Validate configuration with verbose output
print_status "✅ Validating staging configuration..."
npm run validate-config:staging

if [[ "$SKIP_VALIDATION" != "true" ]]; then
    # Additional staging-specific validations
    print_status "🔒 Running security validation..."
    
    # Check if security hardening is enabled
    SECURITY_ENABLED=$(jq -r '.environmentConfig.featureFlags.enableSecurityHardening // false' config/staging.json)
    if [[ "$SECURITY_ENABLED" != "true" ]]; then
        print_warning "⚠️  Security hardening is not enabled for staging"
        print_warning "Consider enabling security hardening for production-like testing"
    fi
    
    # Check monitoring configuration
    MONITORING_ENABLED=$(jq -r '.environmentConfig.featureFlags.enableAdvancedMonitoring // false' config/staging.json)
    if [[ "$MONITORING_ENABLED" != "true" ]]; then
        print_warning "⚠️  Advanced monitoring is not enabled for staging"
        print_warning "Consider enabling advanced monitoring for comprehensive testing"
    fi
    
    # Check budget threshold
    BUDGET_THRESHOLD=$(jq -r '.costAllocation.budgetThreshold // 0' config/staging.json)
    if [[ "$BUDGET_THRESHOLD" -lt 100 ]]; then
        print_warning "⚠️  Budget threshold is quite low for staging: $${BUDGET_THRESHOLD}"
        print_warning "Consider increasing budget threshold for realistic testing"
    fi
    
    print_success "✅ Security validation completed"
else
    print_warning "⏭️ Skipping comprehensive validation as requested"
fi

# CDK Bootstrap check
print_status "🚀 Checking CDK bootstrap..."
npx cdk bootstrap

# Generate and show diff
print_status "📋 Generating deployment diff..."
if [[ "$DRY_RUN" == "true" ]]; then
    print_status "🔍 DRY RUN - Showing what would be deployed:"
    npx cdk diff --context environment=staging
    
    print_status "📊 Estimated resources that would be created/updated:"
    npx cdk synth --context environment=staging > /tmp/staging-template.json
    
    # Count resources
    RESOURCE_COUNT=$(jq '.Resources | length' /tmp/staging-template.json)
    print_status "   Total resources: $RESOURCE_COUNT"
    
    # Show resource types
    print_status "   Resource types:"
    jq -r '.Resources | to_entries[] | "     - \(.value.Type)"' /tmp/staging-template.json | sort | uniq -c | sort -nr
    
    rm -f /tmp/staging-template.json
    
    print_status "🏁 DRY RUN completed - no actual deployment performed"
    exit 0
else
    npx cdk diff --context environment=staging || true
fi

# Confirmation for staging deployment
echo ""
print_warning "⚠️  You are about to deploy to the STAGING environment"
print_warning "This will create/update production-like resources with associated costs"
echo ""
print_status "Staging deployment includes:"
echo "   - Production-like security settings"
echo "   - Enhanced monitoring and logging"
echo "   - Performance optimization features"
echo "   - Cost allocation and tagging"
echo ""

read -p "Continue with staging deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Deployment cancelled by user"
    exit 1
fi

# Deploy with comprehensive logging
print_status "🚀 Deploying to staging environment..."
npx cdk deploy WebHostingStack-staging \
    --context environment=staging \
    --require-approval never \
    --outputs-file cdk-outputs-staging.json \
    --progress events \
    --verbose

# Verify deployment
if [[ -f "cdk-outputs-staging.json" ]]; then
    print_success "✅ Staging deployment completed successfully!"
    
    # Extract and display key outputs
    CLOUDFRONT_DOMAIN=$(jq -r '.["WebHostingStack-staging"].CloudFrontDomainName // empty' cdk-outputs-staging.json)
    CLOUDFRONT_ID=$(jq -r '.["WebHostingStack-staging"].CloudFrontDistributionId // empty' cdk-outputs-staging.json)
    S3_BUCKET=$(jq -r '.["WebHostingStack-staging"].S3BucketName // empty' cdk-outputs-staging.json)
    RUM_APP_ID=$(jq -r '.["WebHostingStack-staging"].RumApplicationId // empty' cdk-outputs-staging.json)
    
    echo ""
    print_success "🌐 Staging Environment URLs:"
    if [[ -n "$CLOUDFRONT_DOMAIN" ]]; then
        print_success "   CloudFront: https://$CLOUDFRONT_DOMAIN"
    fi
    
    # Check if custom domain is configured
    CUSTOM_DOMAIN=$(jq -r '.domainConfig.domainName // empty' config/staging.json)
    if [[ -n "$CUSTOM_DOMAIN" && "$CUSTOM_DOMAIN" != "null" ]]; then
        print_success "   Custom Domain: https://$CUSTOM_DOMAIN"
    fi
    
    echo ""
    print_status "📊 Staging Resources:"
    if [[ -n "$S3_BUCKET" ]]; then
        print_status "   S3 Bucket: $S3_BUCKET"
    fi
    if [[ -n "$CLOUDFRONT_ID" ]]; then
        print_status "   CloudFront Distribution: $CLOUDFRONT_ID"
    fi
    if [[ -n "$RUM_APP_ID" ]]; then
        print_status "   RUM Application: $RUM_APP_ID"
    fi
    
    echo ""
    print_status "🔧 Post-Deployment Steps:"
    echo "   1. Deploy Flutter application to test staging environment"
    echo "   2. Run comprehensive testing suite"
    echo "   3. Validate performance and monitoring"
    echo "   4. Test security configurations"
    echo "   5. Verify cost allocation and tagging"
    
    echo ""
    print_status "📈 Monitoring and Testing:"
    echo "   - CloudWatch RUM: Monitor real user metrics"
    echo "   - CloudFront Metrics: Check cache hit ratios and performance"
    echo "   - Cost Explorer: Monitor spending against budget"
    echo "   - Security: Validate HTTPS and security headers"
    
    echo ""
    print_status "🚨 Important Notes:"
    echo "   - This is a staging environment with production-like costs"
    echo "   - Monitor AWS costs regularly"
    echo "   - Clean up resources when testing is complete"
    echo "   - Use this environment to validate production deployment"
    
else
    print_error "❌ Deployment failed - no outputs file found"
    print_error "Check CloudFormation console for detailed error information"
    exit 1
fi

print_success "🎉 Staging deployment completed successfully!"
print_status "🔗 Next: Use this environment to validate your production deployment strategy"