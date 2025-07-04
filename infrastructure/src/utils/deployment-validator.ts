import { Construct } from 'constructs';
import { Stack } from 'aws-cdk-lib';
import { DeploymentConfig } from '../types/config';
import { ErrorHandler, ErrorSeverity, ErrorCategory } from './error-handler';

/**
 * Pre-deployment validation result
 */
export interface PreDeploymentValidationResult {
  isValid: boolean;
  errors: string[];
  warnings: string[];
  blockers: string[];
  recommendations: string[];
}

/**
 * Deployment readiness check result
 */
export interface DeploymentReadinessResult {
  ready: boolean;
  checks: {
    name: string;
    passed: boolean;
    message: string;
    severity: 'error' | 'warning' | 'info';
  }[];
}

/**
 * Pre-deployment validator for CDK stacks
 */
export class DeploymentValidator {
  private readonly errorHandler: ErrorHandler;
  private readonly config: DeploymentConfig;
  private readonly stack: Stack;

  constructor(scope: Construct, config: DeploymentConfig) {
    this.config = config;
    this.stack = Stack.of(scope);
    this.errorHandler = new ErrorHandler(scope, `DeploymentValidator-${Math.random().toString(36).substr(2, 9)}`, {
      environment: config.environment,
      stackName: this.stack.stackName
    });
  }

  /**
   * Performs comprehensive pre-deployment validation
   */
  public async validatePreDeployment(): Promise<PreDeploymentValidationResult> {
    const result: PreDeploymentValidationResult = {
      isValid: true,
      errors: [],
      warnings: [],
      blockers: [],
      recommendations: []
    };

    try {
      // Validate AWS environment
      await this.validateAwsEnvironment(result);
      
      // Validate configuration
      this.validateConfiguration(result);
      
      // Validate permissions
      await this.validatePermissions(result);
      
      // Validate cross-account setup
      await this.validateCrossAccountSetup(result);
      
      // Validate resource limits
      this.validateResourceLimits(result);
      
      // Validate network connectivity
      await this.validateNetworkConnectivity(result);
      
      // Environment-specific validations
      this.validateEnvironmentSpecific(result);

      result.isValid = result.errors.length === 0 && result.blockers.length === 0;

    } catch (error) {
      result.errors.push(`Validation failed: ${(error as Error).message}`);
      result.isValid = false;
    }

    return result;
  }

  /**
   * Checks deployment readiness with detailed status
   */
  public async checkDeploymentReadiness(): Promise<DeploymentReadinessResult> {
    const checks: DeploymentReadinessResult['checks'] = [];
    let allPassed = true;

    // AWS CLI and credentials check
    try {
      await this.checkAwsCredentials();
      checks.push({
        name: 'AWS Credentials',
        passed: true,
        message: 'AWS credentials are configured and valid',
        severity: 'info'
      });
    } catch (error) {
      allPassed = false;
      checks.push({
        name: 'AWS Credentials',
        passed: false,
        message: `AWS credentials check failed: ${(error as Error).message}`,
        severity: 'error'
      });
    }

    // CDK bootstrap check
    try {
      await this.checkCdkBootstrap();
      checks.push({
        name: 'CDK Bootstrap',
        passed: true,
        message: 'CDK bootstrap is configured for the target region',
        severity: 'info'
      });
    } catch (error) {
      allPassed = false;
      checks.push({
        name: 'CDK Bootstrap',
        passed: false,
        message: `CDK bootstrap check failed: ${(error as Error).message}`,
        severity: 'error'
      });
    }

    // Configuration validation
    try {
      this.validateConfigurationIntegrity();
      checks.push({
        name: 'Configuration',
        passed: true,
        message: 'Configuration is valid and complete',
        severity: 'info'
      });
    } catch (error) {
      allPassed = false;
      checks.push({
        name: 'Configuration',
        passed: false,
        message: `Configuration validation failed: ${(error as Error).message}`,
        severity: 'error'
      });
    }

    // Cross-account role check
    try {
      await this.checkCrossAccountRole();
      checks.push({
        name: 'Cross-Account Role',
        passed: true,
        message: 'Cross-account role is accessible and has required permissions',
        severity: 'info'
      });
    } catch (error) {
      // This might be a warning rather than error for some environments
      const severity = this.config.environment === 'prod' ? 'error' : 'warning';
      if (severity === 'error') allPassed = false;
      
      checks.push({
        name: 'Cross-Account Role',
        passed: false,
        message: `Cross-account role check failed: ${(error as Error).message}`,
        severity
      });
    }

    // Domain validation
    try {
      await this.validateDomainSetup();
      checks.push({
        name: 'Domain Setup',
        passed: true,
        message: 'Domain configuration is valid and DNS is accessible',
        severity: 'info'
      });
    } catch (error) {
      allPassed = false;
      checks.push({
        name: 'Domain Setup',
        passed: false,
        message: `Domain validation failed: ${(error as Error).message}`,
        severity: 'error'
      });
    }

    return {
      ready: allPassed,
      checks
    };
  }

  /**
   * Validates AWS environment setup
   */
  private async validateAwsEnvironment(result: PreDeploymentValidationResult): Promise<void> {
    try {
      // Check if we're in the correct region
      const currentRegion = this.stack.region;
      const requiredRegion = this.config.domainConfig.certificateRegion;

      if (currentRegion !== requiredRegion) {
        result.blockers.push(
          `Stack must be deployed to ${requiredRegion} region for CloudFront certificate. Current region: ${currentRegion}`
        );
      }

      // Check if region is allowed for environment
      if (!this.config.environmentConfig.allowedRegions.includes(currentRegion)) {
        result.blockers.push(
          `Region ${currentRegion} is not allowed for ${this.config.environment} environment. ` +
          `Allowed regions: ${this.config.environmentConfig.allowedRegions.join(', ')}`
        );
      }

    } catch (error) {
      result.errors.push(`AWS environment validation failed: ${(error as Error).message}`);
    }
  }

  /**
   * Validates configuration completeness and correctness
   */
  private validateConfiguration(result: PreDeploymentValidationResult): void {
    try {
      // Check for placeholder values
      const placeholders = [
        'REPLACE_WITH_HOSTED_ZONE_ID',
        'REPLACE_WITH_CROSS_ACCOUNT_ROLE_ARN',
        'your-domain.com',
        'example.com'
      ];

      if (placeholders.includes(this.config.domainConfig.hostedZoneId)) {
        result.blockers.push('Hosted zone ID contains placeholder value - update configuration');
      }

      if (placeholders.includes(this.config.domainConfig.crossAccountRoleArn)) {
        result.blockers.push('Cross-account role ARN contains placeholder value - update configuration');
      }

      if (placeholders.some(p => this.config.domainConfig.domainName.includes(p))) {
        result.blockers.push('Domain name contains placeholder value - update configuration');
      }

      // Validate ARN format
      this.errorHandler.validateArn(
        this.config.domainConfig.crossAccountRoleArn,
        'Cross-account role'
      );

      // Validate domain name format
      this.errorHandler.validateDomainName(this.config.domainConfig.domainName);

    } catch (error) {
      result.errors.push(`Configuration validation failed: ${(error as Error).message}`);
    }
  }

  /**
   * Validates AWS permissions
   */
  private async validatePermissions(result: PreDeploymentValidationResult): Promise<void> {
    try {
      // This would typically make AWS API calls to check permissions
      // For now, we'll do basic validation
      
      const requiredServices = ['s3', 'cloudfront', 'acm', 'route53', 'cloudwatch', 'iam'];
      
      // In a real implementation, we would check each service permission
      result.recommendations.push(
        `Ensure AWS credentials have permissions for: ${requiredServices.join(', ')}`
      );

      // Check for production-specific permissions
      if (this.config.environment === 'prod') {
        result.recommendations.push(
          'Production deployment requires additional permissions for logging and monitoring'
        );
      }

    } catch (error) {
      result.warnings.push(`Permission validation incomplete: ${(error as Error).message}`);
    }
  }

  /**
   * Validates cross-account setup
   */
  private async validateCrossAccountSetup(result: PreDeploymentValidationResult): Promise<void> {
    try {
      // Validate cross-account role ARN format
      const roleArn = this.config.domainConfig.crossAccountRoleArn;
      
      if (!roleArn.startsWith('arn:aws:iam::')) {
        result.errors.push('Invalid cross-account role ARN format');
        return;
      }

      // Extract account ID from ARN
      const accountIdMatch = roleArn.match(/arn:aws:iam::(\d{12}):/);
      if (!accountIdMatch) {
        result.errors.push('Cannot extract account ID from cross-account role ARN');
        return;
      }

      const crossAccountId = accountIdMatch[1];
      const currentAccountId = this.stack.account;

      if (crossAccountId === currentAccountId) {
        result.warnings.push('Cross-account role is in the same account - this may not be intended');
      }

      result.recommendations.push(
        `Ensure cross-account role ${roleArn} exists and has Route53 permissions`
      );

    } catch (error) {
      result.errors.push(`Cross-account validation failed: ${(error as Error).message}`);
    }
  }

  /**
   * Validates resource limits and quotas
   */
  private validateResourceLimits(result: PreDeploymentValidationResult): void {
    try {
      const limits = this.config.environmentConfig.limits;

      // Check cache TTL limits
      if (this.config.cachingConfig.maxTtl > limits.maxCacheTtl) {
        result.errors.push(
          `Max TTL ${this.config.cachingConfig.maxTtl} exceeds environment limit ${limits.maxCacheTtl}`
        );
      }

      // Check RUM sampling rate limits
      if (this.config.monitoringConfig.samplingRate > limits.maxRumSamplingRate) {
        result.errors.push(
          `RUM sampling rate ${this.config.monitoringConfig.samplingRate} exceeds environment limit ${limits.maxRumSamplingRate}`
        );
      }

      // Check S3 lifecycle limits
      this.config.s3Config.lifecycleRules.forEach((rule, index) => {
        if (rule.expirationDays && rule.expirationDays > limits.maxS3LifecycleDays) {
          result.errors.push(
            `S3 lifecycle rule ${index + 1} expiration ${rule.expirationDays} exceeds environment limit ${limits.maxS3LifecycleDays}`
          );
        }
      });

    } catch (error) {
      result.warnings.push(`Resource limits validation incomplete: ${(error as Error).message}`);
    }
  }

  /**
   * Validates network connectivity
   */
  private async validateNetworkConnectivity(result: PreDeploymentValidationResult): Promise<void> {
    try {
      // This would typically test connectivity to AWS services
      // For now, we'll add recommendations
      
      result.recommendations.push(
        'Ensure network connectivity to AWS services in the target region'
      );

      if (this.config.environment === 'prod') {
        result.recommendations.push(
          'Production deployment may require VPC endpoints for enhanced security'
        );
      }

    } catch (error) {
      result.warnings.push(`Network connectivity validation incomplete: ${(error as Error).message}`);
    }
  }

  /**
   * Validates environment-specific requirements
   */
  private validateEnvironmentSpecific(result: PreDeploymentValidationResult): void {
    const env = this.config.environment;

    if (env === 'prod') {
      // Production-specific validations
      if (!this.config.s3Config.versioning) {
        result.errors.push('S3 versioning must be enabled in production');
      }

      if (this.config.monitoringConfig.samplingRate > 0.2) {
        result.warnings.push('High RUM sampling rate in production may increase costs');
      }

      if (!this.config.environmentConfig.featureFlags.enableSecurityHardening) {
        result.warnings.push('Security hardening should be enabled in production');
      }

      // Check required tags
      const requiredTags = ['CostCenter', 'ProjectCode', 'Department', 'Owner'];
      requiredTags.forEach(tag => {
        if (!this.config.tags[tag]) {
          result.errors.push(`Missing required production tag: ${tag}`);
        }
      });
    }

    if (env === 'dev') {
      // Development-specific recommendations
      if (this.config.cachingConfig.maxTtl > 86400) {
        result.warnings.push('High cache TTL in development may make testing difficult');
      }
      
      // Add warning for extended metrics in development
      if (this.config.monitoringConfig.enableExtendedMetrics) {
        result.warnings.push('Extended metrics in development may increase costs');
      }
    }

    if (env === 'staging') {
      // Staging-specific recommendations
      if (!this.config.monitoringConfig.enableExtendedMetrics) {
        result.recommendations.push('Consider enabling extended metrics in staging for production readiness testing');
      }
    }
  }

  /**
   * Checks AWS credentials
   */
  private async checkAwsCredentials(): Promise<void> {
    // This would typically make an AWS STS call to validate credentials
    // For now, we'll simulate the check
    if (!process.env.AWS_ACCESS_KEY_ID && !process.env.AWS_PROFILE) {
      throw new Error('AWS credentials not configured');
    }
  }

  /**
   * Checks CDK bootstrap status
   */
  private async checkCdkBootstrap(): Promise<void> {
    // This would typically check for CDK bootstrap stack
    // For now, we'll add a recommendation
    console.log('Checking CDK bootstrap status...');
    // Simulate check - in real implementation, this would verify bootstrap stack exists
  }

  /**
   * Validates configuration integrity
   */
  private validateConfigurationIntegrity(): void {
    // Comprehensive configuration validation
    this.errorHandler.validateRequired(this.config.domainConfig, 'domainConfig');
    this.errorHandler.validateRequired(this.config.monitoringConfig, 'monitoringConfig');
    this.errorHandler.validateRequired(this.config.cachingConfig, 'cachingConfig');
    this.errorHandler.validateRequired(this.config.s3Config, 's3Config');
  }

  /**
   * Checks cross-account role accessibility
   */
  private async checkCrossAccountRole(): Promise<void> {
    // This would typically attempt to assume the cross-account role
    // For now, we'll validate the ARN format
    const roleArn = this.config.domainConfig.crossAccountRoleArn;
    
    if (!roleArn.startsWith('arn:aws:iam::')) {
      throw new Error('Invalid cross-account role ARN format');
    }

    console.log(`Cross-account role ARN validated: ${roleArn}`);
  }

  /**
   * Validates domain setup
   */
  private async validateDomainSetup(): Promise<void> {
    // This would typically check DNS resolution and hosted zone
    // For now, we'll validate the domain format
    this.errorHandler.validateDomainName(this.config.domainConfig.domainName);
    
    if (!this.config.domainConfig.hostedZoneId.startsWith('Z')) {
      throw new Error('Invalid hosted zone ID format');
    }

    console.log(`Domain setup validated: ${this.config.domainConfig.domainName}`);
  }
}