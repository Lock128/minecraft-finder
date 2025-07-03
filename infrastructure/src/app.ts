#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { loadConfig, getEnvironment, validateRegion, getConfigSummary } from './utils/config-loader';
import { generateValidationReport } from './utils/config-validator';
import { WebHostingStack } from './stacks/web-hosting-stack';

/**
 * Main CDK application entry point
 * This file initializes the CDK app and creates the web hosting stack
 */
async function main() {
  const app = new cdk.App();
  
  // Get environment from context or environment variables
  const environment = getEnvironment();
  console.log(`Deploying for environment: ${environment}`);
  
  try {
    // Load configuration for the target environment
    const config = loadConfig(environment);
    console.log(`Configuration loaded for ${config.environment} environment`);
    
    // Validate configuration comprehensively
    const validationReport = generateValidationReport(config);
    console.log('\n' + validationReport + '\n');
    
    // Get current region and validate it's allowed
    const currentRegion = config.domainConfig.certificateRegion;
    validateRegion(config, currentRegion);
    
    // Log configuration summary
    const configSummary = getConfigSummary(config);
    console.log('Configuration Summary:');
    console.log(JSON.stringify(configSummary, null, 2));
    
    // Generate environment-specific stack name using resource naming
    const stackName = `${config.resourceNaming.resourcePrefix}-web-hosting-${config.environment}`;
    
    // Create the main web hosting stack
    const webHostingStack = new WebHostingStack(app, stackName, {
      config,
      env: {
        account: process.env.CDK_DEFAULT_ACCOUNT,
        region: currentRegion, // Must be us-east-1 for CloudFront
      },
      description: `${config.environmentConfig.description} - Web hosting infrastructure for Minecraft Ore Finder`,
      stackName,
      tags: {
        ...config.tags,
        StackPurpose: 'WebHosting',
        Application: 'MinecraftOreFinder',
        ConfigVersion: '2.0',
        DeploymentTimestamp: new Date().toISOString(),
      },
    });
    
    // Log deployment information
    console.log('\n=== Deployment Information ===');
    console.log(`Stack name: ${webHostingStack.stackName}`);
    console.log(`Environment: ${environment} (${config.environmentConfig.isProduction ? 'Production' : 'Non-Production'})`);
    console.log(`Region: ${currentRegion}`);
    console.log(`Domain: ${config.domainConfig.domainName}`);
    console.log(`Cost Center: ${config.costAllocation.costCenter}`);
    console.log(`Project Code: ${config.costAllocation.projectCode}`);
    console.log(`Budget Threshold: $${config.costAllocation.budgetThreshold || 'Not set'}`);
    
    // Log feature flags
    console.log('\n=== Feature Flags ===');
    Object.entries(config.environmentConfig.featureFlags).forEach(([flag, enabled]) => {
      console.log(`${flag}: ${enabled ? '✅' : '❌'}`);
    });
    
    // Log environment limits
    console.log('\n=== Environment Limits ===');
    console.log(`Max Cache TTL: ${config.environmentConfig.limits.maxCacheTtl}s`);
    console.log(`Max RUM Sampling Rate: ${config.environmentConfig.limits.maxRumSamplingRate}`);
    console.log(`Max S3 Lifecycle Days: ${config.environmentConfig.limits.maxS3LifecycleDays}`);
    
    // Synthesize the app
    console.log(`\nCDK app created with ${app.node.children.length} stack(s)`);
    
  } catch (error) {
    console.error('Failed to initialize CDK app:', error);
    if (error instanceof Error) {
      console.error('Error details:', error.message);
      if (error.stack) {
        console.error('Stack trace:', error.stack);
      }
    }
    process.exit(1);
  }
}

// Run the main function
main().catch((error) => {
  console.error('Unhandled error in CDK app:', error);
  process.exit(1);
});