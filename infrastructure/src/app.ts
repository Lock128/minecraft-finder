#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { loadConfig, getEnvironment } from './utils/config-loader';

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
    
    // TODO: Import and create WebHostingStack once implemented
    // const { WebHostingStack } = await import('./stacks/web-hosting-stack');
    // 
    // new WebHostingStack(app, `MinecraftFinderWebHosting-${environment}`, {
    //   config,
    //   env: {
    //     account: process.env.CDK_DEFAULT_ACCOUNT,
    //     region: process.env.CDK_DEFAULT_REGION,
    //   },
    // });
    
    console.log('CDK app initialized successfully');
    console.log(`Configuration loaded for ${environment} environment`);
    
  } catch (error) {
    console.error('Failed to initialize CDK app:', error);
    process.exit(1);
  }
}

// Run the main function
main().catch((error) => {
  console.error('Unhandled error in CDK app:', error);
  process.exit(1);
});