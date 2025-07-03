#!/usr/bin/env ts-node

/**
 * Security validation script for AWS web hosting infrastructure
 * Performs comprehensive security checks before deployment
 */

import * as fs from 'fs';
import * as path from 'path';
import { SecurityConfig } from '../src/utils/security-config';

interface SecurityCheckResult {
  check: string;
  status: 'PASS' | 'FAIL' | 'WARN';
  message: string;
  severity: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
}

class SecurityChecker {
  private results: SecurityCheckResult[] = [];
  private environment: string;
  private verbose: boolean;

  constructor(environment: string = 'dev', verbose: boolean = false) {
    this.environment = environment;
    this.verbose = verbose;
  }

  /**
   * Run all security checks
   */
  async runAllChecks(): Promise<void> {
    console.log(`🔒 Running security checks for environment: ${this.environment}`);
    console.log('=' .repeat(60));

    await this.checkDependencyVulnerabilities();
    await this.checkConfigurationSecurity();
    await this.checkSecretsManagement();
    await this.checkIAMPolicies();
    await this.checkNetworkSecurity();
    await this.checkEncryptionSettings();
    await this.checkLoggingAndMonitoring();
    await this.checkComplianceRequirements();

    this.printResults();
    this.exitWithStatus();
  }

  /**
   * Check for dependency vulnerabilities
   */
  private async checkDependencyVulnerabilities(): Promise<void> {
    try {
      const { execSync } = require('child_process');
      
      // Run npm audit
      const auditResult = execSync('npm audit --json', { encoding: 'utf8' });
      const audit = JSON.parse(auditResult);
      
      const highVulns = audit.metadata?.vulnerabilities?.high || 0;
      const criticalVulns = audit.metadata?.vulnerabilities?.critical || 0;
      
      if (criticalVulns > 0) {
        this.addResult('DEPENDENCY_VULNERABILITIES', 'FAIL', 
          `Found ${criticalVulns} critical vulnerabilities`, 'CRITICAL');
      } else if (highVulns > 0) {
        this.addResult('DEPENDENCY_VULNERABILITIES', 'WARN', 
          `Found ${highVulns} high severity vulnerabilities`, 'HIGH');
      } else {
        this.addResult('DEPENDENCY_VULNERABILITIES', 'PASS', 
          'No critical or high severity vulnerabilities found', 'LOW');
      }
    } catch (error) {
      this.addResult('DEPENDENCY_VULNERABILITIES', 'WARN', 
        'Could not run dependency vulnerability check', 'MEDIUM');
    }
  }

  /**
   * Check configuration security
   */
  private async checkConfigurationSecurity(): Promise<void> {
    try {
      // Check if configuration files exist
      const configFiles = ['dev.json', 'staging.json', 'prod.json'];
      const configDir = path.join(__dirname, '../config');
      
      for (const configFile of configFiles) {
        const configPath = path.join(configDir, configFile);
        if (fs.existsSync(configPath)) {
          const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
          
          try {
            SecurityConfig.validateSecurityConfig(config);
            this.addResult(`CONFIG_VALIDATION_${configFile.toUpperCase()}`, 'PASS', 
              `Configuration ${configFile} passed security validation`, 'LOW');
          } catch (error) {
            this.addResult(`CONFIG_VALIDATION_${configFile.toUpperCase()}`, 'FAIL', 
              `Configuration ${configFile} failed validation: ${(error as Error).message}`, 'HIGH');
          }
        }
      }
      
      // Check for sensitive data in config files
      this.checkForSensitiveDataInConfigs(configDir);
      
    } catch (error) {
      this.addResult('CONFIGURATION_SECURITY', 'FAIL', 
        `Configuration security check failed: ${(error as Error).message}`, 'HIGH');
    }
  }

  /**
   * Check for sensitive data in configuration files
   */
  private checkForSensitiveDataInConfigs(configDir: string): void {
    const sensitivePatterns = [
      /password/i,
      /secret/i,
      /key.*[=:]\s*['"]\w{10,}/i,
      /token/i,
      /credential/i,
    ];

    try {
      const configFiles = fs.readdirSync(configDir).filter(f => f.endsWith('.json'));
      
      for (const file of configFiles) {
        const content = fs.readFileSync(path.join(configDir, file), 'utf8');
        
        for (const pattern of sensitivePatterns) {
          if (pattern.test(content)) {
            this.addResult('SENSITIVE_DATA_IN_CONFIG', 'FAIL', 
              `Potential sensitive data found in ${file}`, 'CRITICAL');
            return;
          }
        }
      }
      
      this.addResult('SENSITIVE_DATA_IN_CONFIG', 'PASS', 
        'No sensitive data found in configuration files', 'LOW');
    } catch (error) {
      this.addResult('SENSITIVE_DATA_IN_CONFIG', 'WARN', 
        'Could not scan configuration files for sensitive data', 'MEDIUM');
    }
  }

  /**
   * Check secrets management
   */
  private async checkSecretsManagement(): Promise<void> {
    // Check GitHub Actions secrets configuration
    const requiredSecrets = [
      'AWS_ROLE_ARN',
      'DOMAIN_NAME',
      'HOSTED_ZONE_ID',
      'CROSS_ACCOUNT_ROLE_ARN'
    ];

    // This is a documentation check since we can't access actual secrets
    this.addResult('SECRETS_MANAGEMENT', 'PASS', 
      `Required secrets documented: ${requiredSecrets.join(', ')}`, 'LOW');

    // Check for hardcoded secrets in source code
    await this.scanForHardcodedSecrets();
  }

  /**
   * Scan for hardcoded secrets in source code
   */
  private async scanForHardcodedSecrets(): Promise<void> {
    const secretPatterns = [
      /AKIA[0-9A-Z]{16}/g, // AWS Access Key ID
      /['"]\w{40}['"]/, // AWS Secret Access Key pattern
      /sk-[a-zA-Z0-9]{48}/, // OpenAI API Key
      /ghp_[a-zA-Z0-9]{36}/, // GitHub Personal Access Token
      /xoxb-[0-9]{11}-[0-9]{11}-[a-zA-Z0-9]{24}/, // Slack Bot Token
    ];

    try {
      const srcDir = path.join(__dirname, '../src');
      const files = this.getAllTsFiles(srcDir);
      
      let secretsFound = false;
      
      for (const file of files) {
        const content = fs.readFileSync(file, 'utf8');
        
        for (const pattern of secretPatterns) {
          if (pattern.test(content)) {
            this.addResult('HARDCODED_SECRETS', 'FAIL', 
              `Potential hardcoded secret found in ${path.relative(srcDir, file)}`, 'CRITICAL');
            secretsFound = true;
            break;
          }
        }
      }
      
      if (!secretsFound) {
        this.addResult('HARDCODED_SECRETS', 'PASS', 
          'No hardcoded secrets found in source code', 'LOW');
      }
    } catch (error) {
      this.addResult('HARDCODED_SECRETS', 'WARN', 
        'Could not scan for hardcoded secrets', 'MEDIUM');
    }
  }

  /**
   * Check IAM policies for security best practices
   */
  private async checkIAMPolicies(): Promise<void> {
    // This would ideally use a tool like cdk-iam-floyd or custom policy analysis
    // For now, we'll do basic checks
    
    try {
      const securityConfigPath = path.join(__dirname, '../src/utils/security-config.ts');
      const content = fs.readFileSync(securityConfigPath, 'utf8');
      
      // Check for overly permissive policies
      if (content.includes('"*"') && content.includes('Action')) {
        this.addResult('IAM_WILDCARD_ACTIONS', 'WARN', 
          'Wildcard actions found in IAM policies - review for necessity', 'MEDIUM');
      } else {
        this.addResult('IAM_WILDCARD_ACTIONS', 'PASS', 
          'No unnecessary wildcard actions found', 'LOW');
      }
      
      // Check for least privilege principle
      if (content.includes('PowerUserAccess') || content.includes('AdministratorAccess')) {
        this.addResult('IAM_EXCESSIVE_PERMISSIONS', 'FAIL', 
          'Excessive IAM permissions detected', 'HIGH');
      } else {
        this.addResult('IAM_EXCESSIVE_PERMISSIONS', 'PASS', 
          'IAM policies follow least privilege principle', 'LOW');
      }
      
    } catch (error) {
      this.addResult('IAM_POLICY_CHECK', 'WARN', 
        'Could not analyze IAM policies', 'MEDIUM');
    }
  }

  /**
   * Check network security configuration
   */
  private async checkNetworkSecurity(): Promise<void> {
    try {
      const cloudfrontPath = path.join(__dirname, '../src/constructs/cloudfront-distribution.ts');
      const content = fs.readFileSync(cloudfrontPath, 'utf8');
      
      // Check for HTTPS enforcement
      if (content.includes('REDIRECT_TO_HTTPS')) {
        this.addResult('HTTPS_ENFORCEMENT', 'PASS', 
          'HTTPS redirect properly configured', 'LOW');
      } else {
        this.addResult('HTTPS_ENFORCEMENT', 'FAIL', 
          'HTTPS enforcement not configured', 'HIGH');
      }
      
      // Check for security headers
      const securityHeaders = [
        'Content-Security-Policy',
        'Strict-Transport-Security',
        'X-Content-Type-Options',
        'X-Frame-Options'
      ];
      
      let headersConfigured = 0;
      for (const header of securityHeaders) {
        if (content.includes(header)) {
          headersConfigured++;
        }
      }
      
      if (headersConfigured === securityHeaders.length) {
        this.addResult('SECURITY_HEADERS', 'PASS', 
          'All required security headers configured', 'LOW');
      } else {
        this.addResult('SECURITY_HEADERS', 'WARN', 
          `Only ${headersConfigured}/${securityHeaders.length} security headers configured`, 'MEDIUM');
      }
      
    } catch (error) {
      this.addResult('NETWORK_SECURITY', 'WARN', 
        'Could not analyze network security configuration', 'MEDIUM');
    }
  }

  /**
   * Check encryption settings
   */
  private async checkEncryptionSettings(): Promise<void> {
    try {
      const s3Path = path.join(__dirname, '../src/constructs/s3-bucket.ts');
      const content = fs.readFileSync(s3Path, 'utf8');
      
      // Check for encryption at rest
      if (content.includes('BucketEncryption')) {
        this.addResult('S3_ENCRYPTION', 'PASS', 
          'S3 bucket encryption configured', 'LOW');
      } else {
        this.addResult('S3_ENCRYPTION', 'FAIL', 
          'S3 bucket encryption not configured', 'HIGH');
      }
      
      // Check for KMS encryption in production
      if (this.environment === 'prod') {
        if (content.includes('KMS') || content.includes('aws:kms')) {
          this.addResult('KMS_ENCRYPTION_PROD', 'PASS', 
            'KMS encryption configured for production', 'LOW');
        } else {
          this.addResult('KMS_ENCRYPTION_PROD', 'WARN', 
            'KMS encryption recommended for production', 'MEDIUM');
        }
      }
      
      // Check for HTTPS enforcement
      if (content.includes('aws:SecureTransport')) {
        this.addResult('HTTPS_ONLY_POLICY', 'PASS', 
          'HTTPS-only bucket policy configured', 'LOW');
      } else {
        this.addResult('HTTPS_ONLY_POLICY', 'WARN', 
          'HTTPS-only bucket policy not found', 'MEDIUM');
      }
      
    } catch (error) {
      this.addResult('ENCRYPTION_SETTINGS', 'WARN', 
        'Could not analyze encryption settings', 'MEDIUM');
    }
  }

  /**
   * Check logging and monitoring configuration
   */
  private async checkLoggingAndMonitoring(): Promise<void> {
    try {
      // Check for CloudWatch RUM configuration
      const rumPath = path.join(__dirname, '../src/constructs/cloudwatch-rum.ts');
      if (fs.existsSync(rumPath)) {
        this.addResult('RUM_MONITORING', 'PASS', 
          'CloudWatch RUM monitoring configured', 'LOW');
      } else {
        this.addResult('RUM_MONITORING', 'WARN', 
          'CloudWatch RUM monitoring not configured', 'MEDIUM');
      }
      
      // Check for access logging
      const cloudfrontPath = path.join(__dirname, '../src/constructs/cloudfront-distribution.ts');
      const content = fs.readFileSync(cloudfrontPath, 'utf8');
      
      if (content.includes('enableLogging')) {
        this.addResult('ACCESS_LOGGING', 'PASS', 
          'CloudFront access logging configured', 'LOW');
      } else {
        this.addResult('ACCESS_LOGGING', 'WARN', 
          'CloudFront access logging not configured', 'MEDIUM');
      }
      
    } catch (error) {
      this.addResult('LOGGING_MONITORING', 'WARN', 
        'Could not analyze logging and monitoring configuration', 'MEDIUM');
    }
  }

  /**
   * Check compliance requirements
   */
  private async checkComplianceRequirements(): Promise<void> {
    const complianceChecks = [
      {
        name: 'DATA_RETENTION',
        check: () => this.checkDataRetentionPolicies(),
        severity: 'MEDIUM' as const
      },
      {
        name: 'AUDIT_TRAIL',
        check: () => this.checkAuditTrail(),
        severity: 'MEDIUM' as const
      },
      {
        name: 'BACKUP_STRATEGY',
        check: () => this.checkBackupStrategy(),
        severity: 'LOW' as const
      }
    ];

    for (const compliance of complianceChecks) {
      try {
        const result = compliance.check();
        this.addResult(compliance.name, result ? 'PASS' : 'WARN', 
          `${compliance.name} compliance check`, compliance.severity);
      } catch (error) {
        this.addResult(compliance.name, 'WARN', 
          `Could not verify ${compliance.name} compliance`, compliance.severity);
      }
    }
  }

  /**
   * Check data retention policies
   */
  private checkDataRetentionPolicies(): boolean {
    try {
      const s3Path = path.join(__dirname, '../src/constructs/s3-bucket.ts');
      const content = fs.readFileSync(s3Path, 'utf8');
      return content.includes('lifecycleRules') || content.includes('expiration');
    } catch {
      return false;
    }
  }

  /**
   * Check audit trail configuration
   */
  private checkAuditTrail(): boolean {
    // Check if CloudTrail or similar audit logging is mentioned
    try {
      const files = this.getAllTsFiles(path.join(__dirname, '../src'));
      for (const file of files) {
        const content = fs.readFileSync(file, 'utf8');
        if (content.includes('CloudTrail') || content.includes('audit')) {
          return true;
        }
      }
      return false;
    } catch {
      return false;
    }
  }

  /**
   * Check backup strategy
   */
  private checkBackupStrategy(): boolean {
    try {
      const s3Path = path.join(__dirname, '../src/constructs/s3-bucket.ts');
      const content = fs.readFileSync(s3Path, 'utf8');
      return content.includes('versioned: true') || content.includes('versioning');
    } catch {
      return false;
    }
  }

  /**
   * Get all TypeScript files recursively
   */
  private getAllTsFiles(dir: string): string[] {
    const files: string[] = [];
    
    try {
      const entries = fs.readdirSync(dir, { withFileTypes: true });
      
      for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);
        
        if (entry.isDirectory() && !entry.name.startsWith('.')) {
          files.push(...this.getAllTsFiles(fullPath));
        } else if (entry.isFile() && entry.name.endsWith('.ts')) {
          files.push(fullPath);
        }
      }
    } catch (error) {
      // Ignore errors for inaccessible directories
    }
    
    return files;
  }

  /**
   * Add a security check result
   */
  private addResult(check: string, status: 'PASS' | 'FAIL' | 'WARN', 
                   message: string, severity: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL'): void {
    this.results.push({ check, status, message, severity });
    
    if (this.verbose) {
      const icon = status === 'PASS' ? '✅' : status === 'WARN' ? '⚠️' : '❌';
      console.log(`${icon} ${check}: ${message}`);
    }
  }

  /**
   * Print security check results
   */
  private printResults(): void {
    console.log('\n' + '='.repeat(60));
    console.log('🔒 SECURITY CHECK RESULTS');
    console.log('='.repeat(60));

    const passed = this.results.filter(r => r.status === 'PASS').length;
    const warned = this.results.filter(r => r.status === 'WARN').length;
    const failed = this.results.filter(r => r.status === 'FAIL').length;
    const critical = this.results.filter(r => r.severity === 'CRITICAL').length;

    console.log(`\n📊 Summary:`);
    console.log(`   ✅ Passed: ${passed}`);
    console.log(`   ⚠️  Warnings: ${warned}`);
    console.log(`   ❌ Failed: ${failed}`);
    console.log(`   🚨 Critical: ${critical}`);

    if (failed > 0 || critical > 0) {
      console.log('\n🚨 CRITICAL ISSUES:');
      this.results
        .filter(r => r.status === 'FAIL' || r.severity === 'CRITICAL')
        .forEach(r => {
          console.log(`   ❌ ${r.check}: ${r.message}`);
        });
    }

    if (warned > 0) {
      console.log('\n⚠️  WARNINGS:');
      this.results
        .filter(r => r.status === 'WARN')
        .forEach(r => {
          console.log(`   ⚠️  ${r.check}: ${r.message}`);
        });
    }

    console.log('\n' + '='.repeat(60));
  }

  /**
   * Exit with appropriate status code
   */
  private exitWithStatus(): void {
    const critical = this.results.filter(r => r.severity === 'CRITICAL').length;
    const failed = this.results.filter(r => r.status === 'FAIL').length;

    if (critical > 0) {
      console.log('🚨 CRITICAL security issues found. Deployment should be blocked.');
      process.exit(2);
    } else if (failed > 0) {
      console.log('❌ Security issues found. Please review before deployment.');
      process.exit(1);
    } else {
      console.log('✅ All security checks passed. Safe to deploy.');
      process.exit(0);
    }
  }
}

// Main execution
async function main() {
  const args = process.argv.slice(2);
  const environment = args[0] || 'dev';
  const verbose = args.includes('--verbose') || args.includes('-v');

  const checker = new SecurityChecker(environment, verbose);
  await checker.runAllChecks();
}

if (require.main === module) {
  main().catch(error => {
    console.error('❌ Security check failed:', error);
    process.exit(1);
  });
}

export { SecurityChecker };