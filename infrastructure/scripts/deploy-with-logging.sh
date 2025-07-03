#!/bin/bash

# Enhanced deployment script with comprehensive logging and error handling
# This script provides detailed logging for all deployment operations

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/deployment_${TIMESTAMP}.log"
ERROR_LOG_FILE="$LOG_DIR/deployment_errors_${TIMESTAMP}.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Logging functions
log_info() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[INFO]${NC} $message"
    echo "[$timestamp] [INFO] $message" >> "$LOG_FILE"
}

log_warn() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[WARN]${NC} $message"
    echo "[$timestamp] [WARN] $message" >> "$LOG_FILE"
}

log_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[ERROR]${NC} $message" >&2
    echo "[$timestamp] [ERROR] $message" >> "$LOG_FILE"
    echo "[$timestamp] [ERROR] $message" >> "$ERROR_LOG_FILE"
}

log_success() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[SUCCESS]${NC} $message"
    echo "[$timestamp] [SUCCESS] $message" >> "$LOG_FILE"
}

# Error handling
handle_error() {
    local exit_code=$?
    local line_number=$1
    log_error "Script failed at line $line_number with exit code $exit_code"
    log_error "Command that failed: ${BASH_COMMAND}"
    
    # Capture stack trace
    log_error "Stack trace:"
    local frame=0
    while caller $frame >> "$ERROR_LOG_FILE" 2>&1; do
        ((frame++))
    done
    
    # Cleanup on error
    cleanup_on_error
    
    exit $exit_code
}

# Set error trap
trap 'handle_error $LINENO' ERR

# Cleanup function
cleanup_on_error() {
    log_warn "Performing cleanup after error..."
    
    # Add any cleanup operations here
    # For example, removing temporary files, reverting changes, etc.
    
    log_info "Cleanup completed"
}

# Validation functions
validate_environment() {
    local env="$1"
    log_info "Validating environment: $env"
    
    if [[ ! "$env" =~ ^(dev|staging|prod)$ ]]; then
        log_error "Invalid environment: $env. Must be one of: dev, staging, prod"
        return 1
    fi
    
    log_success "Environment validation passed"
}

validate_aws_credentials() {
    log_info "Validating AWS credentials..."
    
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured or invalid"
        log_error "Please run 'aws configure' or set AWS_PROFILE environment variable"
        return 1
    fi
    
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    local user_arn=$(aws sts get-caller-identity --query Arn --output text)
    
    log_info "AWS Account ID: $account_id"
    log_info "AWS User/Role: $user_arn"
    log_success "AWS credentials validation passed"
}

validate_region() {
    local region="$1"
    log_info "Validating AWS region: $region"
    
    if ! aws ec2 describe-regions --region-names "$region" &> /dev/null; then
        log_error "Invalid AWS region: $region"
        return 1
    fi
    
    log_success "Region validation passed"
}

validate_cdk_bootstrap() {
    local region="$1"
    log_info "Checking CDK bootstrap status in region: $region"
    
    local bootstrap_stack_name="CDKToolkit"
    if ! aws cloudformation describe-stacks --stack-name "$bootstrap_stack_name" --region "$region" &> /dev/null; then
        log_warn "CDK not bootstrapped in region $region"
        log_info "Run: cdk bootstrap aws://ACCOUNT-NUMBER/$region"
        return 1
    fi
    
    log_success "CDK bootstrap validation passed"
}

validate_configuration() {
    local env="$1"
    local config_file="$PROJECT_ROOT/config/${env}.json"
    
    log_info "Validating configuration file: $config_file"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi
    
    # Validate JSON syntax
    if ! jq empty "$config_file" 2>/dev/null; then
        log_error "Invalid JSON in configuration file: $config_file"
        return 1
    fi
    
    # Check for placeholder values
    local placeholders=("REPLACE_WITH_" "your-domain.com" "example.com")
    for placeholder in "${placeholders[@]}"; do
        if grep -q "$placeholder" "$config_file"; then
            log_error "Configuration contains placeholder value: $placeholder"
            log_error "Please update the configuration file with actual values"
            return 1
        fi
    done
    
    log_success "Configuration validation passed"
}

# Pre-deployment checks
run_pre_deployment_checks() {
    local env="$1"
    local region="$2"
    
    log_info "Running pre-deployment checks..."
    
    validate_environment "$env"
    validate_aws_credentials
    validate_region "$region"
    validate_cdk_bootstrap "$region"
    validate_configuration "$env"
    
    log_success "All pre-deployment checks passed"
}

# Build and test functions
run_tests() {
    log_info "Running tests..."
    
    cd "$PROJECT_ROOT"
    
    # Run TypeScript compilation
    log_info "Compiling TypeScript..."
    if ! npm run build 2>&1 | tee -a "$LOG_FILE"; then
        log_error "TypeScript compilation failed"
        return 1
    fi
    
    # Run unit tests
    log_info "Running unit tests..."
    if ! npm test 2>&1 | tee -a "$LOG_FILE"; then
        log_error "Unit tests failed"
        return 1
    fi
    
    # Run linting
    log_info "Running linting..."
    if ! npm run lint 2>&1 | tee -a "$LOG_FILE"; then
        log_warn "Linting issues found (not blocking deployment)"
    fi
    
    log_success "Tests completed successfully"
}

# CDK deployment functions
synthesize_stack() {
    local env="$1"
    local region="$2"
    
    log_info "Synthesizing CDK stack for environment: $env"
    
    cd "$PROJECT_ROOT"
    
    # Set environment variables
    export ENVIRONMENT="$env"
    export AWS_DEFAULT_REGION="$region"
    
    # Synthesize the stack
    if ! npx cdk synth 2>&1 | tee -a "$LOG_FILE"; then
        log_error "CDK synthesis failed"
        return 1
    fi
    
    log_success "CDK synthesis completed successfully"
}

deploy_stack() {
    local env="$1"
    local region="$2"
    local auto_approve="${3:-false}"
    
    log_info "Deploying CDK stack for environment: $env"
    
    cd "$PROJECT_ROOT"
    
    # Set environment variables
    export ENVIRONMENT="$env"
    export AWS_DEFAULT_REGION="$region"
    
    # Prepare deployment command
    local deploy_cmd="npx cdk deploy"
    
    if [[ "$auto_approve" == "true" ]]; then
        deploy_cmd="$deploy_cmd --require-approval never"
        log_info "Auto-approval enabled"
    fi
    
    # Add additional deployment options
    deploy_cmd="$deploy_cmd --verbose --progress events"
    
    # Execute deployment
    log_info "Executing deployment command: $deploy_cmd"
    
    if ! $deploy_cmd 2>&1 | tee -a "$LOG_FILE"; then
        log_error "CDK deployment failed"
        return 1
    fi
    
    log_success "CDK deployment completed successfully"
}

# Post-deployment functions
run_post_deployment_checks() {
    local env="$1"
    
    log_info "Running post-deployment checks..."
    
    # Check stack status
    local stack_name=$(get_stack_name "$env")
    local stack_status=$(aws cloudformation describe-stacks --stack-name "$stack_name" --query 'Stacks[0].StackStatus' --output text 2>/dev/null || echo "NOT_FOUND")
    
    if [[ "$stack_status" == "CREATE_COMPLETE" ]] || [[ "$stack_status" == "UPDATE_COMPLETE" ]]; then
        log_success "Stack deployment status: $stack_status"
    else
        log_error "Stack deployment status: $stack_status"
        return 1
    fi
    
    # Get stack outputs
    log_info "Stack outputs:"
    aws cloudformation describe-stacks --stack-name "$stack_name" --query 'Stacks[0].Outputs' --output table 2>&1 | tee -a "$LOG_FILE"
    
    log_success "Post-deployment checks completed"
}

get_stack_name() {
    local env="$1"
    echo "minecraft-ore-finder-web-hosting-$env"
}

# Rollback function
rollback_deployment() {
    local env="$1"
    
    log_warn "Initiating rollback for environment: $env"
    
    cd "$PROJECT_ROOT"
    
    # Set environment variables
    export ENVIRONMENT="$env"
    
    # Attempt rollback
    if ! npx cdk deploy --rollback 2>&1 | tee -a "$LOG_FILE"; then
        log_error "Rollback failed"
        return 1
    fi
    
    log_success "Rollback completed successfully"
}

# Main deployment function
deploy() {
    local env="$1"
    local region="${2:-us-east-1}"
    local auto_approve="${3:-false}"
    local skip_tests="${4:-false}"
    
    log_info "Starting deployment process..."
    log_info "Environment: $env"
    log_info "Region: $region"
    log_info "Auto-approve: $auto_approve"
    log_info "Skip tests: $skip_tests"
    log_info "Log file: $LOG_FILE"
    
    # Record deployment start time
    local start_time=$(date +%s)
    
    # Run pre-deployment checks
    run_pre_deployment_checks "$env" "$region"
    
    # Run tests (unless skipped)
    if [[ "$skip_tests" != "true" ]]; then
        run_tests
    else
        log_warn "Skipping tests as requested"
    fi
    
    # Synthesize stack
    synthesize_stack "$env" "$region"
    
    # Deploy stack
    deploy_stack "$env" "$region" "$auto_approve"
    
    # Run post-deployment checks
    run_post_deployment_checks "$env"
    
    # Calculate deployment time
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_success "Deployment completed successfully in ${duration} seconds"
    log_info "Deployment logs saved to: $LOG_FILE"
    
    # Generate deployment summary
    generate_deployment_summary "$env" "$region" "$duration"
}

# Generate deployment summary
generate_deployment_summary() {
    local env="$1"
    local region="$2"
    local duration="$3"
    
    local summary_file="$LOG_DIR/deployment_summary_${TIMESTAMP}.json"
    
    cat > "$summary_file" << EOF
{
  "deployment": {
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "environment": "$env",
    "region": "$region",
    "duration_seconds": $duration,
    "status": "success",
    "log_file": "$LOG_FILE",
    "stack_name": "$(get_stack_name "$env")"
  }
}
EOF
    
    log_info "Deployment summary saved to: $summary_file"
}

# Usage function
usage() {
    cat << EOF
Usage: $0 <environment> [options]

Arguments:
  environment     Target environment (dev|staging|prod)

Options:
  -r, --region REGION        AWS region (default: us-east-1)
  -y, --auto-approve         Auto-approve deployment changes
  -s, --skip-tests          Skip running tests
  -h, --help                Show this help message

Examples:
  $0 dev
  $0 staging --region us-west-2
  $0 prod --auto-approve
  $0 dev --skip-tests --region eu-west-1

EOF
}

# Main script logic
main() {
    local env=""
    local region="us-east-1"
    local auto_approve="false"
    local skip_tests="false"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--region)
                region="$2"
                shift 2
                ;;
            -y|--auto-approve)
                auto_approve="true"
                shift
                ;;
            -s|--skip-tests)
                skip_tests="true"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                if [[ -z "$env" ]]; then
                    env="$1"
                else
                    log_error "Unexpected argument: $1"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate required arguments
    if [[ -z "$env" ]]; then
        log_error "Environment argument is required"
        usage
        exit 1
    fi
    
    # Start deployment
    deploy "$env" "$region" "$auto_approve" "$skip_tests"
}

# Run main function with all arguments
main "$@"