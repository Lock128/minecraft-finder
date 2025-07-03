#!/bin/bash

# Web Hosting Deployment Script
# This script provides local deployment capabilities for testing and troubleshooting

set -e

# Default values
ENVIRONMENT="dev"
SKIP_BUILD=false
SKIP_TESTS=false
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
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

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy Flutter web application to AWS using CDK infrastructure.

OPTIONS:
    -e, --environment ENV    Target environment (dev|staging|prod) [default: dev]
    -s, --skip-build        Skip Flutter build process
    -t, --skip-tests        Skip running tests
    -v, --verbose           Enable verbose output
    -h, --help              Show this help message

EXAMPLES:
    $0                      # Deploy to dev environment
    $0 -e prod              # Deploy to production
    $0 -s -e staging        # Deploy to staging without rebuilding Flutter
    $0 -t -v                # Deploy with verbose output, skip tests

REQUIRED ENVIRONMENT VARIABLES:
    AWS_ACCESS_KEY_ID       AWS access key
    AWS_SECRET_ACCESS_KEY   AWS secret access key
    AWS_REGION              AWS region [default: us-east-1]
    DOMAIN_NAME             Custom domain name
    HOSTED_ZONE_ID          Route53 hosted zone ID
    CROSS_ACCOUNT_ROLE_ARN  Cross-account role ARN

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -s|--skip-build)
            SKIP_BUILD=true
            shift
            ;;
        -t|--skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT. Must be dev, staging, or prod."
    exit 1
fi

# Set verbose mode
if [[ "$VERBOSE" == "true" ]]; then
    set -x
fi

# Check required tools
check_requirements() {
    print_status "Checking requirements..."
    
    local missing_tools=()
    
    if ! command -v flutter &> /dev/null; then
        missing_tools+=("flutter")
    fi
    
    if ! command -v node &> /dev/null; then
        missing_tools+=("node")
    fi
    
    if ! command -v npm &> /dev/null; then
        missing_tools+=("npm")
    fi
    
    if ! command -v aws &> /dev/null; then
        missing_tools+=("aws")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_error "Please install the missing tools and try again."
        exit 1
    fi
    
    print_success "All required tools are available"
}

# Check environment variables
check_environment() {
    print_status "Checking environment variables..."
    
    local missing_vars=()
    
    if [[ -z "$AWS_ACCESS_KEY_ID" ]]; then
        missing_vars+=("AWS_ACCESS_KEY_ID")
    fi
    
    if [[ -z "$AWS_SECRET_ACCESS_KEY" ]]; then
        missing_vars+=("AWS_SECRET_ACCESS_KEY")
    fi
    
    if [[ -z "$DOMAIN_NAME" ]]; then
        missing_vars+=("DOMAIN_NAME")
    fi
    
    if [[ -z "$HOSTED_ZONE_ID" ]]; then
        missing_vars+=("HOSTED_ZONE_ID")
    fi
    
    if [[ -z "$CROSS_ACCOUNT_ROLE_ARN" ]]; then
        missing_vars+=("CROSS_ACCOUNT_ROLE_ARN")
    fi
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        print_error "Missing required environment variables: ${missing_vars[*]}"
        print_error "Please set the missing variables and try again."
        exit 1
    fi
    
    # Set default AWS region if not provided
    export AWS_REGION="${AWS_REGION:-us-east-1}"
    
    print_success "Environment variables are configured"
}

# Build Flutter web application
build_flutter() {
    if [[ "$SKIP_BUILD" == "true" ]]; then
        print_warning "Skipping Flutter build as requested"
        return 0
    fi
    
    print_status "Building Flutter web application..."
    
    cd flutter_app
    
    # Get dependencies
    print_status "Installing Flutter dependencies..."
    flutter pub get
    
    # Run analysis
    if [[ "$SKIP_TESTS" != "true" ]]; then
        print_status "Analyzing Flutter code..."
        flutter analyze --fatal-infos
        
        print_status "Running Flutter tests..."
        flutter test
    else
        print_warning "Skipping tests as requested"
    fi
    
    # Build web application
    print_status "Building Flutter web for production..."
    flutter build web --release --web-renderer html --base-href /
    
    # Generate build info
    local build_hash=$(git rev-parse --short HEAD)
    local build_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    cat > build/web/build-info.json << EOF
{
  "buildHash": "$build_hash",
  "buildTime": "$build_time",
  "gitCommit": "$(git rev-parse HEAD)",
  "gitBranch": "$(git rev-parse --abbrev-ref HEAD)",
  "environment": "$ENVIRONMENT"
}
EOF
    
    cd ..
    
    print_success "Flutter build completed successfully"
}

# Deploy CDK infrastructure
deploy_infrastructure() {
    print_status "Deploying CDK infrastructure..."
    
    cd infrastructure
    
    # Install dependencies
    print_status "Installing CDK dependencies..."
    npm ci
    
    # Build TypeScript
    print_status "Building CDK application..."
    npm run build
    
    # Run tests
    if [[ "$SKIP_TESTS" != "true" ]]; then
        print_status "Running CDK tests..."
        npm test
    fi
    
    # Bootstrap CDK if needed
    print_status "Checking CDK bootstrap..."
    npx cdk bootstrap "aws://${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text)}/${AWS_REGION}" || true
    
    # Generate diff
    print_status "Generating CDK diff..."
    npx cdk diff --context environment="$ENVIRONMENT" || true
    
    # Deploy stack
    local stack_name="WebHostingStack-$ENVIRONMENT"
    
    print_status "Deploying CDK stack: $stack_name"
    npx cdk deploy "$stack_name" \
        --context environment="$ENVIRONMENT" \
        --context domainName="$DOMAIN_NAME" \
        --context hostedZoneId="$HOSTED_ZONE_ID" \
        --context crossAccountRoleArn="$CROSS_ACCOUNT_ROLE_ARN" \
        --require-approval never \
        --outputs-file cdk-outputs.json \
        --progress events
    
    # Extract outputs
    if [[ -f cdk-outputs.json ]]; then
        CLOUDFRONT_DISTRIBUTION_ID=$(jq -r ".[\"$stack_name\"].CloudFrontDistributionId // empty" cdk-outputs.json)
        S3_BUCKET_NAME=$(jq -r ".[\"$stack_name\"].S3BucketName // empty" cdk-outputs.json)
        CLOUDFRONT_DOMAIN=$(jq -r ".[\"$stack_name\"].CloudFrontDomainName // empty" cdk-outputs.json)
        
        print_success "Infrastructure deployed successfully"
        print_status "CloudFront Distribution ID: $CLOUDFRONT_DISTRIBUTION_ID"
        print_status "S3 Bucket Name: $S3_BUCKET_NAME"
        print_status "CloudFront Domain: $CLOUDFRONT_DOMAIN"
    else
        print_error "CDK outputs file not found"
        exit 1
    fi
    
    cd ..
}

# Deploy assets to S3
deploy_assets() {
    if [[ "$SKIP_BUILD" == "true" ]]; then
        print_warning "Skipping asset deployment (build was skipped)"
        return 0
    fi
    
    print_status "Deploying assets to S3..."
    
    if [[ -z "$S3_BUCKET_NAME" ]]; then
        print_error "S3 bucket name not available"
        exit 1
    fi
    
    # Sync static assets with long cache
    print_status "Uploading static assets with cache headers..."
    aws s3 sync flutter_app/build/web/ "s3://$S3_BUCKET_NAME/" \
        --delete \
        --cache-control "public, max-age=31536000" \
        --exclude "*.html" \
        --exclude "*.json" \
        --exclude "manifest.json" \
        --exclude "flutter_service_worker.js"
    
    # Upload HTML and service worker with no-cache
    print_status "Uploading HTML files with no-cache headers..."
    aws s3 sync flutter_app/build/web/ "s3://$S3_BUCKET_NAME/" \
        --cache-control "no-cache, no-store, must-revalidate" \
        --include "*.html" \
        --include "manifest.json" \
        --include "flutter_service_worker.js"
    
    print_success "Assets uploaded successfully"
}

# Invalidate CloudFront cache
invalidate_cache() {
    if [[ "$SKIP_BUILD" == "true" ]]; then
        print_warning "Skipping cache invalidation (build was skipped)"
        return 0
    fi
    
    print_status "Invalidating CloudFront cache..."
    
    if [[ -z "$CLOUDFRONT_DISTRIBUTION_ID" ]]; then
        print_error "CloudFront distribution ID not available"
        exit 1
    fi
    
    local invalidation_id=$(aws cloudfront create-invalidation \
        --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" \
        --paths "/*" \
        --query 'Invalidation.Id' \
        --output text)
    
    print_status "Invalidation ID: $invalidation_id"
    print_status "Waiting for invalidation to complete..."
    
    aws cloudfront wait invalidation-completed \
        --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" \
        --id "$invalidation_id"
    
    print_success "CloudFront cache invalidated successfully"
}

# Main deployment function
main() {
    print_status "Starting deployment to $ENVIRONMENT environment..."
    
    # Check requirements
    check_requirements
    check_environment
    
    # Build and deploy
    build_flutter
    deploy_infrastructure
    deploy_assets
    invalidate_cache
    
    # Success message
    print_success "🎉 Deployment completed successfully!"
    
    if [[ -n "$CLOUDFRONT_DOMAIN" ]]; then
        print_success "🌐 Application URL: https://$CLOUDFRONT_DOMAIN"
    fi
    
    if [[ -n "$DOMAIN_NAME" ]]; then
        print_success "🔗 Custom Domain: https://$DOMAIN_NAME"
    fi
}

# Run main function
main "$@"