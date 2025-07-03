#!/bin/bash

# Development Environment Deployment Script
# Quick deployment script specifically for development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[DEV]${NC} $1"
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
SKIP_BUILD=false
SKIP_TESTS=false
VERBOSE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
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
            cat << EOF
Usage: $0 [OPTIONS]

Quick deployment script for development environment.

OPTIONS:
    -s, --skip-build        Skip Flutter build process
    -t, --skip-tests        Skip running tests
    -v, --verbose           Enable verbose output
    -h, --help              Show this help message

EXAMPLES:
    $0                      # Full development deployment
    $0 -s                   # Deploy infrastructure only
    $0 -t -v                # Deploy with verbose output, skip tests

This script is optimized for development with:
- Faster deployment times
- Relaxed validation
- Development-specific optimizations
- Quick iteration support

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

print_status "🚀 Starting development environment deployment..."

# Check if we're in the right directory
if [[ ! -f "package.json" ]]; then
    print_error "Please run this script from the infrastructure directory"
    exit 1
fi

# Quick validation
print_status "📋 Quick validation..."
if [[ ! -f "config/dev.json" ]]; then
    print_error "Development configuration file not found: config/dev.json"
    exit 1
fi

# Check for placeholder values
if grep -q "REPLACE_WITH_" config/dev.json; then
    print_warning "⚠️  Configuration contains placeholder values"
    print_warning "Please update config/dev.json with actual values before deployment"
    
    # Show which placeholders need to be replaced
    echo "Placeholder values found:"
    grep -n "REPLACE_WITH_" config/dev.json || true
    echo ""
    
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Deployment cancelled"
        exit 1
    fi
fi

# Install dependencies if needed
if [[ ! -d "node_modules" ]]; then
    print_status "📦 Installing dependencies..."
    npm ci
fi

# Build TypeScript
print_status "🏗️ Building CDK application..."
npm run build

# Run tests unless skipped
if [[ "$SKIP_TESTS" != "true" ]]; then
    print_status "🧪 Running tests..."
    npm test
else
    print_warning "⏭️ Skipping tests as requested"
fi

# Validate configuration
print_status "✅ Validating development configuration..."
npm run validate-config:dev

# CDK Bootstrap check
print_status "🚀 Checking CDK bootstrap..."
npx cdk bootstrap || print_warning "CDK bootstrap may have failed, continuing..."

# Show diff
print_status "📋 Showing deployment diff..."
npx cdk diff --context environment=dev || true

# Deploy
print_status "🚀 Deploying to development environment..."
npx cdk deploy WebHostingStack-dev \
    --context environment=dev \
    --require-approval never \
    --outputs-file cdk-outputs-dev.json \
    --progress events

# Check deployment outputs
if [[ -f "cdk-outputs-dev.json" ]]; then
    print_success "✅ Development deployment completed successfully!"
    
    # Extract and display key outputs
    CLOUDFRONT_DOMAIN=$(jq -r '.["WebHostingStack-dev"].CloudFrontDomainName // empty' cdk-outputs-dev.json)
    S3_BUCKET=$(jq -r '.["WebHostingStack-dev"].S3BucketName // empty' cdk-outputs-dev.json)
    
    echo ""
    print_success "🌐 Development Environment URLs:"
    if [[ -n "$CLOUDFRONT_DOMAIN" ]]; then
        print_success "   CloudFront: https://$CLOUDFRONT_DOMAIN"
    fi
    
    # Check if custom domain is configured
    CUSTOM_DOMAIN=$(jq -r '.domainConfig.domainName // empty' config/dev.json)
    if [[ -n "$CUSTOM_DOMAIN" && "$CUSTOM_DOMAIN" != "null" ]]; then
        print_success "   Custom Domain: https://$CUSTOM_DOMAIN"
    fi
    
    echo ""
    print_status "📊 Development Resources:"
    if [[ -n "$S3_BUCKET" ]]; then
        print_status "   S3 Bucket: $S3_BUCKET"
    fi
    
    echo ""
    print_status "🔧 Next Steps:"
    echo "   1. Build and deploy Flutter app: cd ../flutter_app && flutter build web"
    echo "   2. Upload to S3: aws s3 sync build/web/ s3://$S3_BUCKET/"
    echo "   3. Invalidate CloudFront cache for immediate updates"
    echo "   4. Test your application at the URLs above"
    
else
    print_error "❌ Deployment may have failed - no outputs file found"
    exit 1
fi

print_success "🎉 Development deployment completed!"