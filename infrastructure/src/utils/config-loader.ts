import * as fs from 'fs';
import * as path from 'path';
import { DeploymentConfig, Environment } from '../types/config';

/**
 * Loads deployment configuration for the specified environment
 * @param environment The target environment
 * @returns The deployment configuration
 */
export function loadConfig(environment: Environment): DeploymentConfig {
  const configPath = path.join(__dirname, '../../config', `${environment}.json`);
  
  if (!fs.existsSync(configPath)) {
    throw new Error(`Configuration file not found for environment: ${environment}`);
  }

  try {
    const configData = fs.readFileSync(configPath, 'utf8');
    const config = JSON.parse(configData) as DeploymentConfig;
    
    // Validate required configuration
    validateConfig(config);
    
    return config;
  } catch (error) {
    throw new Error(`Failed to load configuration for environment ${environment}: ${error}`);
  }
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

  // Validate domain configuration
  if (!config.domainConfig) {
    errors.push('Missing domain configuration');
  } else {
    if (!config.domainConfig.domainName) {
      errors.push('Missing domain name');
    }
    if (!config.domainConfig.hostedZoneId || config.domainConfig.hostedZoneId === 'REPLACE_WITH_HOSTED_ZONE_ID') {
      errors.push('Missing or placeholder hosted zone ID');
    }
    if (!config.domainConfig.crossAccountRoleArn || config.domainConfig.crossAccountRoleArn === 'REPLACE_WITH_CROSS_ACCOUNT_ROLE_ARN') {
      errors.push('Missing or placeholder cross-account role ARN');
    }
    if (config.domainConfig.certificateRegion !== 'us-east-1') {
      errors.push('Certificate region must be us-east-1 for CloudFront');
    }
  }

  // Validate monitoring configuration
  if (!config.monitoringConfig) {
    errors.push('Missing monitoring configuration');
  } else {
    if (!config.monitoringConfig.rumAppName) {
      errors.push('Missing RUM application name');
    }
    if (config.monitoringConfig.samplingRate < 0 || config.monitoringConfig.samplingRate > 1) {
      errors.push('RUM sampling rate must be between 0 and 1');
    }
  }

  // Validate caching configuration
  if (!config.cachingConfig) {
    errors.push('Missing caching configuration');
  } else {
    if (config.cachingConfig.defaultTtl < 0) {
      errors.push('Default TTL must be non-negative');
    }
    if (config.cachingConfig.maxTtl < config.cachingConfig.defaultTtl) {
      errors.push('Max TTL must be greater than or equal to default TTL');
    }
  }

  // Validate S3 configuration
  if (!config.s3Config) {
    errors.push('Missing S3 configuration');
  } else {
    if (!config.s3Config.bucketNamePrefix) {
      errors.push('Missing S3 bucket name prefix');
    }
  }

  if (errors.length > 0) {
    throw new Error(`Configuration validation failed:\n${errors.join('\n')}`);
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