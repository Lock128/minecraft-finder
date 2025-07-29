import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';
import * as cdk from 'aws-cdk-lib';
import { DeploymentConfig, Environment } from '../types/config';

/**
 * Loads deployment configuration for the specified environment
 * @param environment The target environment
 * @param app Optional CDK app for context overrides
 * @returns The deployment configuration
 */
export function loadConfig(environment: Environment, app?: cdk.App): DeploymentConfig {
  const configPath = path.join(__dirname, '../../config', `${environment}.json`);
  
  if (!fs.existsSync(configPath)) {
    throw new Error(`Configuration file not found for environment: ${environment}`);
  }

  try {
    const configData = fs.readFileSync(configPath, 'utf8');
    const config = JSON.parse(configData) as DeploymentConfig;
    
    // Apply context overrides if CDK app is provided
    if (app) {
      applyContextOverrides(config, app);
    }
    
    // Validate required configuration
    validateConfig(config);
    
    // Apply environment-specific processing
    processEnvironmentConfig(config);
    
    return config;
  } catch (error) {
    throw new Error(`Failed to load configuration for environment ${environment}: ${error}`);
  }
}

/**
 * Processes environment-specific configuration settings
 * @param config The configuration to process
 */
function processEnvironmentConfig(config: DeploymentConfig): void {
  // Apply environment limits
  const limits = config.environmentConfig.limits;
  
  // Enforce cache TTL limits
  if (config.cachingConfig.maxTtl > limits.maxCacheTtl) {
    console.warn(`Max TTL ${config.cachingConfig.maxTtl} exceeds limit ${limits.maxCacheTtl}, adjusting`);
    config.cachingConfig.maxTtl = limits.maxCacheTtl;
  }
  
  // Enforce RUM sampling rate limits
  if (config.monitoringConfig.samplingRate > limits.maxRumSamplingRate) {
    console.warn(`RUM sampling rate ${config.monitoringConfig.samplingRate} exceeds limit ${limits.maxRumSamplingRate}, adjusting`);
    config.monitoringConfig.samplingRate = limits.maxRumSamplingRate;
  }
  
  // Enforce S3 lifecycle limits
  config.s3Config.lifecycleRules.forEach(rule => {
    if (rule.expirationDays && rule.expirationDays > limits.maxS3LifecycleDays) {
      console.warn(`S3 lifecycle expiration ${rule.expirationDays} exceeds limit ${limits.maxS3LifecycleDays}, adjusting`);
      rule.expirationDays = limits.maxS3LifecycleDays;
    }
  });
  
  // Merge cost allocation tags into main tags
  if (config.costAllocation.customCostTags) {
    config.tags = { ...config.tags, ...config.costAllocation.customCostTags };
  }
}

/**
 * Applies CDK context overrides to the configuration
 * @param config The configuration to override
 * @param app The CDK app containing context
 */
function applyContextOverrides(config: DeploymentConfig, app: cdk.App): void {
  console.log('🔧 Checking for context overrides...');
  
  // Override domain configuration from context
  const domainName = app.node.tryGetContext('domainName');
  if (domainName) {
    console.log(`🔧 Overriding domain name from context: ${domainName}`);
    config.domainConfig.domainName = domainName;
  } else {
    console.log('🔧 No domainName context found');
  }
  
  const hostedZoneId = app.node.tryGetContext('hostedZoneId');
  if (hostedZoneId) {
    console.log(`🔧 Overriding hosted zone ID from context: ${hostedZoneId}`);
    config.domainConfig.hostedZoneId = hostedZoneId;
  } else {
    console.log('🔧 No hostedZoneId context found');
  }
  
  const crossAccountRoleArn = app.node.tryGetContext('crossAccountRoleArn');
  if (crossAccountRoleArn) {
    console.log(`🔧 Overriding cross-account role ARN from context: ${crossAccountRoleArn}`);
    config.domainConfig.crossAccountRoleArn = crossAccountRoleArn;
  } else {
    console.log('🔧 No crossAccountRoleArn context found');
  }
  
  // Override other context values as needed
  const certificateRegion = app.node.tryGetContext('certificateRegion');
  if (certificateRegion) {
    console.log(`🔧 Overriding certificate region from context: ${certificateRegion}`);
    config.domainConfig.certificateRegion = certificateRegion;
  }
  
  // Debug: show all available context
  console.log('🔧 Available context keys:', Object.keys(app.node.tryGetContext('') || {}));
}

/**
 * Validates the deployment configuration
 * @param config The configuration to validate
 */
function validateConfig(config: DeploymentConfig): void {
  const errors: string[] = [];

  // Validate environment
  if (!config.environment || !['dev', 'staging', 'prod'].includes(config.environment)) {
    errors.push('Invalid or missing environment');
  }

  // Validate environment configuration
  if (!config.environmentConfig) {
    errors.push('Missing environment configuration');
  } else {
    validateEnvironmentConfig(config.environmentConfig, errors);
  }

  // Validate domain configuration
  if (!config.domainConfig) {
    errors.push('Missing domain configuration');
  } else {
    validateDomainConfig(config.domainConfig, errors, config.environment);
  }

  // Validate monitoring configuration
  if (!config.monitoringConfig) {
    errors.push('Missing monitoring configuration');
  } else {
    validateMonitoringConfig(config.monitoringConfig, errors);
  }

  // Validate caching configuration
  if (!config.cachingConfig) {
    errors.push('Missing caching configuration');
  } else {
    validateCachingConfig(config.cachingConfig, errors);
  }

  // Validate S3 configuration
  if (!config.s3Config) {
    errors.push('Missing S3 configuration');
  } else {
    validateS3Config(config.s3Config, errors);
  }

  // Validate resource naming configuration
  if (!config.resourceNaming) {
    errors.push('Missing resource naming configuration');
  } else {
    validateResourceNamingConfig(config.resourceNaming, errors);
  }

  // Validate cost allocation configuration
  if (!config.costAllocation) {
    errors.push('Missing cost allocation configuration');
  } else {
    validateCostAllocationConfig(config.costAllocation, errors);
  }

  // Validate tags
  if (!config.tags || Object.keys(config.tags).length === 0) {
    errors.push('Missing or empty tags configuration');
  }

  if (errors.length > 0) {
    throw new Error(`Configuration validation failed:\n${errors.join('\n')}`);
  }
}

/**
 * Validates environment configuration
 */
function validateEnvironmentConfig(envConfig: any, errors: string[]): void {
  if (!envConfig.name) {
    errors.push('Missing environment name');
  }
  if (!envConfig.description) {
    errors.push('Missing environment description');
  }
  if (typeof envConfig.isProduction !== 'boolean') {
    errors.push('Environment isProduction must be a boolean');
  }
  if (!Array.isArray(envConfig.allowedRegions) || envConfig.allowedRegions.length === 0) {
    errors.push('Environment allowedRegions must be a non-empty array');
  }
  if (!envConfig.featureFlags) {
    errors.push('Missing environment feature flags');
  }
  if (!envConfig.limits) {
    errors.push('Missing environment limits');
  }
}

/**
 * Validates domain configuration
 */
function validateDomainConfig(domainConfig: any, errors: string[], environment?: string): void {
  if (!domainConfig.domainName) {
    errors.push('Missing domain name');
  }
  
  // For dev environment, allow placeholder values but warn about them
  const isDev = environment === 'dev';
  
  if (!domainConfig.hostedZoneId || domainConfig.hostedZoneId === 'REPLACE_WITH_HOSTED_ZONE_ID') {
    if (isDev) {
      console.warn('⚠️  Using placeholder hosted zone ID in dev environment');
    } else {
      errors.push('Missing or placeholder hosted zone ID');
    }
  }
  
  if (!domainConfig.crossAccountRoleArn || domainConfig.crossAccountRoleArn === 'REPLACE_WITH_CROSS_ACCOUNT_ROLE_ARN') {
    if (isDev) {
      console.warn('⚠️  Using placeholder cross-account role ARN in dev environment');
    } else {
      errors.push('Missing or placeholder cross-account role ARN');
    }
  }
  
  if (domainConfig.certificateRegion !== 'us-east-1') {
    errors.push('Certificate region must be us-east-1 for CloudFront');
  }
}

/**
 * Validates monitoring configuration
 */
function validateMonitoringConfig(monitoringConfig: any, errors: string[]): void {
  if (!monitoringConfig.rumAppName) {
    errors.push('Missing RUM application name');
  }
  if (monitoringConfig.samplingRate < 0 || monitoringConfig.samplingRate > 1) {
    errors.push('RUM sampling rate must be between 0 and 1');
  }
  if (!Array.isArray(monitoringConfig.enabledMetrics)) {
    errors.push('Enabled metrics must be an array');
  }
  if (typeof monitoringConfig.enableExtendedMetrics !== 'boolean') {
    errors.push('enableExtendedMetrics must be a boolean');
  }
}

/**
 * Validates caching configuration
 */
function validateCachingConfig(cachingConfig: any, errors: string[]): void {
  if (cachingConfig.defaultTtl < 0) {
    errors.push('Default TTL must be non-negative');
  }
  if (cachingConfig.maxTtl < cachingConfig.defaultTtl) {
    errors.push('Max TTL must be greater than or equal to default TTL');
  }
  if (cachingConfig.staticAssetsTtl < 0) {
    errors.push('Static assets TTL must be non-negative');
  }
  if (cachingConfig.htmlTtl < 0) {
    errors.push('HTML TTL must be non-negative');
  }
}

/**
 * Validates S3 configuration
 */
function validateS3Config(s3Config: any, errors: string[]): void {
  if (!s3Config.bucketNamePrefix) {
    errors.push('Missing S3 bucket name prefix');
  }
  if (typeof s3Config.versioning !== 'boolean') {
    errors.push('S3 versioning must be a boolean');
  }
  if (typeof s3Config.publicReadAccess !== 'boolean') {
    errors.push('S3 publicReadAccess must be a boolean');
  }
  if (!Array.isArray(s3Config.lifecycleRules)) {
    errors.push('S3 lifecycle rules must be an array');
  }
}

/**
 * Validates resource naming configuration
 */
function validateResourceNamingConfig(namingConfig: any, errors: string[]): void {
  if (!namingConfig.resourcePrefix) {
    errors.push('Missing resource prefix');
  }
  if (!namingConfig.resourceSuffix) {
    errors.push('Missing resource suffix');
  }
  if (typeof namingConfig.includeEnvironment !== 'boolean') {
    errors.push('includeEnvironment must be a boolean');
  }
  if (typeof namingConfig.includeRandomSuffix !== 'boolean') {
    errors.push('includeRandomSuffix must be a boolean');
  }
}

/**
 * Validates cost allocation configuration
 */
function validateCostAllocationConfig(costConfig: any, errors: string[]): void {
  if (!costConfig.costCenter) {
    errors.push('Missing cost center');
  }
  if (!costConfig.projectCode) {
    errors.push('Missing project code');
  }
  if (!costConfig.department) {
    errors.push('Missing department');
  }
  if (typeof costConfig.enableDetailedBilling !== 'boolean') {
    errors.push('enableDetailedBilling must be a boolean');
  }
  if (costConfig.budgetThreshold && costConfig.budgetThreshold <= 0) {
    errors.push('Budget threshold must be positive');
  }
}

/**
 * Gets the environment from environment variables or defaults to 'dev'
 * @returns The environment name
 */
export function getEnvironment(): Environment {
  const env = process.env.ENVIRONMENT || process.env.NODE_ENV || 'dev';
  
  if (!['dev', 'staging', 'prod'].includes(env)) {
    console.warn(`Invalid environment '${env}', defaulting to 'dev'`);
    return 'dev';
  }
  
  return env as Environment;
}
/**

 * Generates a resource name based on the naming configuration
 * @param config The deployment configuration
 * @param resourceType The type of resource (s3Bucket, cloudFrontDistribution, etc.)
 * @param baseName Optional base name to use instead of prefix/suffix
 * @returns The generated resource name
 */
export function generateResourceName(
  config: DeploymentConfig,
  resourceType: keyof NonNullable<typeof config.resourceNaming.customPatterns>,
  baseName?: string
): string {
  const naming = config.resourceNaming;
  
  // Check for custom pattern first
  if (naming.customPatterns && naming.customPatterns[resourceType]) {
    let name = naming.customPatterns[resourceType]!;
    
    // Replace placeholders
    if (naming.includeRandomSuffix && name.includes('{random}')) {
      const randomSuffix = generateRandomSuffix();
      name = name.replace('{random}', randomSuffix);
    }
    
    return name;
  }
  
  // Generate standard name
  let parts: string[] = [];
  
  if (baseName) {
    parts.push(baseName);
  } else {
    parts.push(naming.resourcePrefix);
  }
  
  if (naming.includeEnvironment) {
    parts.push(config.environment);
  }
  
  if (naming.resourceSuffix) {
    parts.push(naming.resourceSuffix);
  }
  
  if (naming.includeRandomSuffix) {
    parts.push(generateRandomSuffix());
  }
  
  return parts.join('-').toLowerCase();
}

/**
 * Generates a random suffix for resource uniqueness
 * @returns A random 8-character suffix
 */
function generateRandomSuffix(): string {
  return crypto.randomBytes(4).toString('hex');
}

/**
 * Gets all cost allocation tags for a resource
 * @param config The deployment configuration
 * @param additionalTags Optional additional tags to merge
 * @returns Combined tags including cost allocation tags
 */
export function getCostAllocationTags(
  config: DeploymentConfig,
  additionalTags?: Record<string, string>
): Record<string, string> {
  const costTags = {
    CostCenter: config.costAllocation.costCenter,
    ProjectCode: config.costAllocation.projectCode,
    Department: config.costAllocation.department,
    Environment: config.environment,
    BillingGroup: config.costAllocation.customCostTags?.BillingGroup || config.environment,
    ...config.costAllocation.customCostTags,
    ...config.tags,
    ...additionalTags,
  };
  
  return costTags;
}

/**
 * Validates that the current region is allowed for the environment
 * @param config The deployment configuration
 * @param currentRegion The current AWS region
 * @throws Error if region is not allowed
 */
export function validateRegion(config: DeploymentConfig, currentRegion: string): void {
  if (!config.environmentConfig.allowedRegions.includes(currentRegion)) {
    throw new Error(
      `Region ${currentRegion} is not allowed for environment ${config.environment}. ` +
      `Allowed regions: ${config.environmentConfig.allowedRegions.join(', ')}`
    );
  }
}

/**
 * Gets environment-specific configuration summary for logging
 * @param config The deployment configuration
 * @returns Configuration summary object
 */
export function getConfigSummary(config: DeploymentConfig) {
  return {
    environment: config.environment,
    isProduction: config.environmentConfig.isProduction,
    domain: config.domainConfig.domainName,
    costCenter: config.costAllocation.costCenter,
    projectCode: config.costAllocation.projectCode,
    budgetThreshold: config.costAllocation.budgetThreshold,
    featureFlags: config.environmentConfig.featureFlags,
    limits: config.environmentConfig.limits,
  };
}