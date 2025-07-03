#!/usr/bin/env ts-node
/**
 * Configuration validation CLI tool
 * 
 * This script validates deployment configurations for all environments
 * and provides detailed reports on any issues found.
 * 
 * Usage:
 *   npm run validate-config [environment]
 *   
 * Examples:
 *   npm run validate-config          # Validate all environments
 *   npm run validate-config dev      # Validate only dev environment
 *   npm run validate-config --fix    # Validate and attempt to fix issues
 */

import * as fs from 'fs';
import * as path from 'path';
import { loadConfig } from '../src/utils/config-loader';
import { generateValidationReport, validateDeploymentConfig } from '../src/utils/config-validator';
import { Environment } from '../src/types/config';

interface ValidationOptions {
  environment?: Environment;
  fix?: boolean;
  verbose?: boolean;
  output?: string;
}

/**
 * Main validation function
 */
async function main() {
  const options = parseArguments();
  
  console.log('🔍 Configuration Validation Tool');
  console.log('================================\n');
  
  const environments: Environment[] = options.environment 
    ? [options.environment]
    : ['dev', 'staging', 'prod'];
  
  let allValid = true;
  const results: Array<{ env: Environment; valid: boolean; report: string }> = [];
  
  for (const env of environments) {
    console.log(`Validating ${env} environment...`);
    
    try {
      const config = loadConfig(env);
      const report = generateValidationReport(config);
      const validation = validateDeploymentConfig(config);
      
      results.push({
        env,
        valid: validation.isValid,
        report
      });
      
      if (!validation.isValid) {
        allValid = false;
      }
      
      if (options.verbose || !validation.isValid) {
        console.log(report);
        console.log('');
      } else {
        console.log(`✅ ${env} configuration is valid\n`);
      }
      
    } catch (error) {
      console.error(`❌ Failed to validate ${env} configuration:`);
      console.error(error instanceof Error ? error.message : String(error));
      console.log('');
      allValid = false;
      
      results.push({
        env,
        valid: false,
        report: `Validation failed: ${error instanceof Error ? error.message : String(error)}`
      });
    }
  }
  
  // Generate summary
  console.log('=== Validation Summary ===');
  results.forEach(({ env, valid }) => {
    console.log(`${env}: ${valid ? '✅ Valid' : '❌ Invalid'}`);
  });
  
  // Save report if output specified
  if (options.output) {
    const fullReport = generateFullReport(results);
    fs.writeFileSync(options.output, fullReport);
    console.log(`\nFull report saved to: ${options.output}`);
  }
  
  // Exit with appropriate code
  if (!allValid) {
    console.log('\n❌ Some configurations have issues that need to be addressed.');
    process.exit(1);
  } else {
    console.log('\n✅ All configurations are valid!');
    process.exit(0);
  }
}

/**
 * Parse command line arguments
 */
function parseArguments(): ValidationOptions {
  const args = process.argv.slice(2);
  const options: ValidationOptions = {};
  
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    
    switch (arg) {
      case '--fix':
        options.fix = true;
        break;
      case '--verbose':
      case '-v':
        options.verbose = true;
        break;
      case '--output':
      case '-o':
        options.output = args[++i];
        break;
      case '--help':
      case '-h':
        printHelp();
        process.exit(0);
        break;
      default:
        if (['dev', 'staging', 'prod'].includes(arg)) {
          options.environment = arg as Environment;
        } else if (!arg.startsWith('--')) {
          console.error(`Unknown environment: ${arg}`);
          process.exit(1);
        }
    }
  }
  
  return options;
}

/**
 * Print help information
 */
function printHelp() {
  console.log(`
Configuration Validation Tool

Usage:
  npm run validate-config [options] [environment]

Arguments:
  environment    Specific environment to validate (dev, staging, prod)
                If not specified, all environments will be validated

Options:
  --fix         Attempt to fix common configuration issues
  --verbose, -v Show detailed validation reports for all environments
  --output, -o  Save full validation report to specified file
  --help, -h    Show this help message

Examples:
  npm run validate-config                    # Validate all environments
  npm run validate-config dev                # Validate only dev environment
  npm run validate-config --verbose          # Show detailed reports
  npm run validate-config -o report.txt     # Save report to file
  npm run validate-config dev --fix         # Validate dev and attempt fixes
`);
}

/**
 * Generate a full validation report
 */
function generateFullReport(results: Array<{ env: Environment; valid: boolean; report: string }>): string {
  const timestamp = new Date().toISOString();
  
  const report = [
    'Configuration Validation Report',
    '===============================',
    `Generated: ${timestamp}`,
    '',
    'Summary:',
    results.map(({ env, valid }) => `  ${env}: ${valid ? 'VALID' : 'INVALID'}`).join('\n'),
    '',
    'Detailed Reports:',
    '================',
    '',
    ...results.map(({ env, report }) => [
      `Environment: ${env.toUpperCase()}`,
      '-'.repeat(20),
      report,
      ''
    ]).flat()
  ];
  
  return report.join('\n');
}

/**
 * Check if configuration files exist
 */
function checkConfigurationFiles(): boolean {
  const configDir = path.join(__dirname, '../config');
  const environments: Environment[] = ['dev', 'staging', 'prod'];
  
  let allExist = true;
  
  environments.forEach(env => {
    const configPath = path.join(configDir, `${env}.json`);
    if (!fs.existsSync(configPath)) {
      console.error(`❌ Configuration file missing: ${configPath}`);
      allExist = false;
    }
  });
  
  return allExist;
}

// Run the main function if this script is executed directly
if (require.main === module) {
  // Check if configuration files exist first
  if (!checkConfigurationFiles()) {
    console.error('\n❌ Missing configuration files. Please ensure all environment configurations exist.');
    process.exit(1);
  }
  
  main().catch(error => {
    console.error('Unexpected error:', error);
    process.exit(1);
  });
}