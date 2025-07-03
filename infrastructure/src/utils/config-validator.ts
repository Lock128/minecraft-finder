import { DeploymentConfig, Environment } from '../types/config';

/**
 * Configuration validation result
 */
export interface ValidationResult {
  isValid: boolean;
  errors: string[];
  warnings: string[];
}

/**
 * Validates a deployment configuration comprehensively
 * @param config The configuration to validate
 * @returns Validation result with errors and warnings
 */
export function validateDeploymentConfig(config: DeploymentConfig): ValidationResult {
  const errors: string[] = [];
  const warnings: string[] = [];

  // Basic structure validation
  validateBasicStructure(config, errors);
  
  // Environment-specific validation
  validateEnvironmentSpecific(config, errors, warnings);
  
  // Security validation
  validateSecurity(config, errors, warnings);
  
  // Cost optimization validation
  validateCostOptimization(config, warnings);
  
  // Performance validation
  validatePerformance(config, warnings);

  return {
    isValid: errors.length === 0,
    errors,
    warnings
  };
}

/**
 * Validates basic configuration structure
 */
function validateBasicStructure(config: DeploymentConfig, errors: string[]): void {
  // Required top-level properties
  const requiredProps = [
    'environment', 'environmentConfig', 'domainConfig', 'monitoringConfig',
    'cachingConfig', 's3Config', 'resourceNaming', 'costAllocation', 'tags'
  ];

  requiredProps.forEach(prop => {
    if (!(prop in config) || config[prop as keyof DeploymentConfig] === null || config[prop as keyof DeploymentConfig] === undefined) {
      errors.push(`Missing required property: ${prop}`);
    }
  });

  // Validate environment value
  if (config.environment && !['dev', 'staging', 'prod'].includes(config.environment)) {
    errors.push(`Invalid environment: ${config.environment}. Must be one of: dev, staging, prod`);
  }
}

/**
 * Validates environment-specific requirements
 */
function validateEnvironmentSpecific(config: DeploymentConfig, errors: string[], warnings: string[]): void {
  if (!config.environmentConfig) return;

  const { environment, environmentConfig } = config;

  // Production-specific validations
  if (environmentConfig.isProduction || environment === 'prod') {
    if (config.monitoringConfig?.samplingRate > 0.2) {
      warnings.push('High RUM sampling rate in production may increase costs significantly');
    }

    if (!config.s3Config?.versioning) {
      errors.push('S3 versioning must be enabled in production');
    }

    if (config.cachingConfig?.htmlTtl < 3600) {
      warnings.push('Low HTML TTL in production may increase origin requests');
    }

    if (!environmentConfig.featureFlags.enableSecurityHardening) {
      warnings.push('Security hardening should be enabled in production');
    }

    // Validate required tags for production
    const requiredProdTags = ['CostCenter', 'ProjectCode', 'Department', 'Owner'];
    requiredProdTags.forEach(tag => {
      if (!config.tags[tag]) {
        errors.push(`Missing required production tag: ${tag}`);
      }
    });
  }

  // Development-specific validations
  if (environment === 'dev') {
    if (config.cachingConfig?.maxTtl > 86400) {
      warnings.push('High cache TTL in development may make testing difficult');
    }

    if (config.monitoringConfig?.enableExtendedMetrics) {
      warnings.push('Extended metrics in development may increase costs unnecessarily');
    }
  }

  // Staging-specific validations
  if (environment === 'staging') {
    if (!config.monitoringConfig?.enableExtendedMetrics) {
      warnings.push('Extended metrics should be enabled in staging for production readiness testing');
    }
  }
}

/**
 * Validates security configuration
 */
function validateSecurity(config: DeploymentConfig, errors: string[], warnings: string[]): void {
  // Domain configuration security
  if (config.domainConfig) {
    if (config.domainConfig.certificateRegion !== 'us-east-1') {
      errors.push('Certificate must be in us-east-1 region for CloudFront');
    }

    // Check for placeholder values
    const placeholders = [
      'REPLACE_WITH_HOSTED_ZONE_ID',
      'REPLACE_WITH_CROSS_ACCOUNT_ROLE_ARN'
    ];

    if (placeholders.includes(config.domainConfig.hostedZoneId)) {
      errors.push('Hosted zone ID contains placeholder value');
    }

    if (placeholders.includes(config.domainConfig.crossAccountRoleArn)) {
      errors.push('Cross-account role ARN contains placeholder value');
    }

    // Validate ARN format
    if (config.domainConfig.crossAccountRoleArn && 
        !config.domainConfig.crossAccountRoleArn.startsWith('arn:aws:iam::')) {
      errors.push('Invalid cross-account role ARN format');
    }
  }

  // S3 security
  if (config.s3Config?.publicReadAccess) {
    errors.push('S3 bucket should not have public read access when using CloudFront');
  }

  // Monitoring security
  if (config.monitoringConfig?.samplingRate > 0.8) {
    warnings.push('Very high RUM sampling rate may impact user privacy');
  }
}

/**
 * Validates cost optimization settings
 */
function validateCostOptimization(config: DeploymentConfig, warnings: string[]): void {
  // S3 lifecycle rules
  if (config.s3Config?.lifecycleRules.length === 0) {
    warnings.push('No S3 lifecycle rules configured - consider adding rules for cost optimization');
  }

  config.s3Config?.lifecycleRules.forEach((rule, index) => {
    if (!rule.transitionToIADays && !rule.expirationDays) {
      warnings.push(`S3 lifecycle rule ${index + 1} has no transitions or expiration - may not provide cost benefits`);
    }

    if (rule.transitionToIADays && rule.transitionToIADays < 30) {
      warnings.push(`S3 lifecycle rule ${index + 1} transitions to IA too quickly (< 30 days) - may increase costs`);
    }
  });

  // CloudFront caching
  if (config.cachingConfig) {
    if (config.cachingConfig.staticAssetsTtl < 86400) {
      warnings.push('Low static assets TTL may increase CloudFront costs');
    }

    if (config.cachingConfig.defaultTtl < 3600) {
      warnings.push('Low default TTL may increase origin requests and costs');
    }
  }

  // Budget threshold
  if (config.costAllocation?.budgetThreshold) {
    if (config.environment === 'prod' && config.costAllocation.budgetThreshold < 100) {
      warnings.push('Production budget threshold seems low - consider reviewing');
    }

    if (config.environment === 'dev' && config.costAllocation.budgetThreshold > 100) {
      warnings.push('Development budget threshold seems high - consider reducing');
    }
  }
}

/**
 * Validates performance configuration
 */
function validatePerformance(config: DeploymentConfig, warnings: string[]): void {
  // Caching performance
  if (config.cachingConfig) {
    if (config.cachingConfig.htmlTtl > 3600 && config.environment !== 'prod') {
      warnings.push('High HTML TTL in non-production may make development/testing difficult');
    }

    if (config.cachingConfig.maxTtl < config.cachingConfig.staticAssetsTtl) {
      warnings.push('Max TTL is less than static assets TTL - this may cause unexpected behavior');
    }
  }

  // Monitoring performance
  if (config.monitoringConfig) {
    const highImpactMetrics = [
      'PerformanceResourceTiming',
      'LargestContentfulPaint',
      'CumulativeLayoutShift'
    ];

    const enabledHighImpactMetrics = config.monitoringConfig.enabledMetrics.filter(
      metric => highImpactMetrics.includes(metric)
    );

    if (enabledHighImpactMetrics.length === 0) {
      warnings.push('No performance metrics enabled - consider enabling key performance metrics');
    }
  }

  // Resource naming performance
  if (config.resourceNaming?.includeRandomSuffix && config.environment === 'prod') {
    warnings.push('Random suffixes in production may make resource identification difficult');
  }
}

/**
 * Validates configuration against environment limits
 * @param config The configuration to validate
 * @returns Validation result
 */
export function validateEnvironmentLimits(config: DeploymentConfig): ValidationResult {
  const errors: string[] = [];
  const warnings: string[] = [];

  if (!config.environmentConfig?.limits) {
    errors.push('Environment limits not configured');
    return { isValid: false, errors, warnings };
  }

  const limits = config.environmentConfig.limits;

  // Validate cache TTL limits
  if (config.cachingConfig?.maxTtl > limits.maxCacheTtl) {
    errors.push(`Max TTL ${config.cachingConfig.maxTtl} exceeds environment limit ${limits.maxCacheTtl}`);
  }

  // Validate RUM sampling rate limits
  if (config.monitoringConfig?.samplingRate > limits.maxRumSamplingRate) {
    errors.push(`RUM sampling rate ${config.monitoringConfig.samplingRate} exceeds environment limit ${limits.maxRumSamplingRate}`);
  }

  // Validate S3 lifecycle limits
  config.s3Config?.lifecycleRules.forEach((rule, index) => {
    if (rule.expirationDays && rule.expirationDays > limits.maxS3LifecycleDays) {
      errors.push(`S3 lifecycle rule ${index + 1} expiration ${rule.expirationDays} exceeds environment limit ${limits.maxS3LifecycleDays}`);
    }
  });

  return {
    isValid: errors.length === 0,
    errors,
    warnings
  };
}

/**
 * Generates a configuration validation report
 * @param config The configuration to validate
 * @returns Formatted validation report
 */
export function generateValidationReport(config: DeploymentConfig): string {
  const result = validateDeploymentConfig(config);
  const limitsResult = validateEnvironmentLimits(config);

  const report = [
    `Configuration Validation Report for ${config.environment} environment`,
    '='.repeat(60),
    '',
    `Overall Status: ${result.isValid && limitsResult.isValid ? 'VALID' : 'INVALID'}`,
    '',
  ];

  if (result.errors.length > 0 || limitsResult.errors.length > 0) {
    report.push('ERRORS:');
    [...result.errors, ...limitsResult.errors].forEach((error, index) => {
      report.push(`  ${index + 1}. ${error}`);
    });
    report.push('');
  }

  if (result.warnings.length > 0 || limitsResult.warnings.length > 0) {
    report.push('WARNINGS:');
    [...result.warnings, ...limitsResult.warnings].forEach((warning, index) => {
      report.push(`  ${index + 1}. ${warning}`);
    });
    report.push('');
  }

  if (result.errors.length === 0 && limitsResult.errors.length === 0) {
    report.push('✅ Configuration is valid and ready for deployment');
  } else {
    report.push('❌ Configuration has errors that must be fixed before deployment');
  }

  return report.join('\n');
}