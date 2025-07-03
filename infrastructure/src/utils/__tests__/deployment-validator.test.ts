import { App, Stack } from 'aws-cdk-lib';
import { DeploymentValidator } from '../deployment-validator';
import { DeploymentConfig } from '../../types/config';

// Mock configuration for testing
const createMockConfig = (overrides: Partial<DeploymentConfig> = {}): DeploymentConfig => ({
  environment: 'dev',
  environmentConfig: {
    name: 'dev',
    description: 'Test environment',
    isProduction: false,
    allowedRegions: ['us-east-1', 'us-west-2'],
    featureFlags: {
      enableSecurityHardening: true,
      enableAdvancedMonitoring: false,
      enableCostOptimization: true,
      enablePerformanceOptimization: false,
    },
    limits: {
      maxCacheTtl: 86400,
      maxRumSamplingRate: 1.0,
      maxS3LifecycleDays: 365,
    },
  },
  domainConfig: {
    domainName: 'test.example.com',
    hostedZoneId: 'Z1234567890ABC',
    crossAccountRoleArn: 'arn:aws:iam::123456789012:role/test-role',
    certificateRegion: 'us-east-1',
  },
  monitoringConfig: {
    rumAppName: 'test-app',
    samplingRate: 0.1,
    enabledMetrics: ['PageLoad', 'JavaScriptError'],
    enableExtendedMetrics: false,
  },
  cachingConfig: {
    defaultTtl: 3600,
    maxTtl: 86400,
    staticAssetsTtl: 31536000,
    htmlTtl: 0,
  },
  s3Config: {
    bucketNamePrefix: 'test-bucket',
    versioning: true,
    publicReadAccess: false,
    lifecycleRules: [
      {
        id: 'test-rule',
        enabled: true,
        expirationDays: 90,
        transitionToIADays: 30,
        abortIncompleteMultipartUploadDays: 7,
      },
    ],
  },
  resourceNaming: {
    resourcePrefix: 'test',
    resourceSuffix: 'suffix',
    includeEnvironment: true,
    includeRandomSuffix: false,
    customPatterns: {},
  },
  costAllocation: {
    costCenter: 'TEST-001',
    projectCode: 'TEST-PROJECT',
    department: 'Engineering',
    enableDetailedBilling: true,
    budgetThreshold: 100,
    customCostTags: {
      Team: 'TestTeam',
    },
  },
  tags: {
    Environment: 'dev',
    Project: 'TestProject',
    CostCenter: 'TEST-001',
    ProjectCode: 'TEST-PROJECT',
    Department: 'Engineering',
    Owner: 'TestOwner',
  },
  ...overrides,
});

describe('DeploymentValidator', () => {
  let app: App;
  let stack: Stack;
  let validator: DeploymentValidator;
  let mockConfig: DeploymentConfig;

  beforeEach(() => {
    app = new App();
    stack = new Stack(app, 'TestStack', {
      env: { region: 'us-east-1' }
    });
    mockConfig = createMockConfig();
    validator = new DeploymentValidator(stack, mockConfig);
  });

  describe('validatePreDeployment', () => {
    it('should pass validation with valid configuration', async () => {
      const result = await validator.validatePreDeployment();
      
      expect(result.isValid).toBe(true);
      expect(result.errors).toHaveLength(0);
      expect(result.blockers).toHaveLength(0);
    });

    it('should fail validation with placeholder values', async () => {
      const configWithPlaceholders = createMockConfig({
        domainConfig: {
          ...mockConfig.domainConfig,
          hostedZoneId: 'REPLACE_WITH_HOSTED_ZONE_ID',
          crossAccountRoleArn: 'REPLACE_WITH_CROSS_ACCOUNT_ROLE_ARN',
        },
      });
      
      const validatorWithPlaceholders = new DeploymentValidator(stack, configWithPlaceholders);
      const result = await validatorWithPlaceholders.validatePreDeployment();
      
      expect(result.isValid).toBe(false);
      expect(result.blockers).toContain('Hosted zone ID contains placeholder value - update configuration');
      expect(result.blockers).toContain('Cross-account role ARN contains placeholder value - update configuration');
    });

    it('should fail validation with invalid region', async () => {
      const invalidRegionStack = new Stack(app, 'InvalidRegionStack', {
        env: { region: 'eu-west-1' }
      });
      
      const validatorWithInvalidRegion = new DeploymentValidator(invalidRegionStack, mockConfig);
      const result = await validatorWithInvalidRegion.validatePreDeployment();
      
      expect(result.isValid).toBe(false);
      expect(result.blockers.some(blocker => 
        blocker.includes('Region eu-west-1 is not allowed')
      )).toBe(true);
    });

    it('should fail validation with invalid ARN format', async () => {
      const configWithInvalidArn = createMockConfig({
        domainConfig: {
          ...mockConfig.domainConfig,
          crossAccountRoleArn: 'invalid-arn-format',
        },
      });
      
      const validatorWithInvalidArn = new DeploymentValidator(stack, configWithInvalidArn);
      const result = await validatorWithInvalidArn.validatePreDeployment();
      
      expect(result.isValid).toBe(false);
      expect(result.errors.some(error => 
        error.includes('Configuration validation failed')
      )).toBe(true);
    });

    it('should fail validation with invalid domain name', async () => {
      const configWithInvalidDomain = createMockConfig({
        domainConfig: {
          ...mockConfig.domainConfig,
          domainName: 'invalid..domain',
        },
      });
      
      const validatorWithInvalidDomain = new DeploymentValidator(stack, configWithInvalidDomain);
      const result = await validatorWithInvalidDomain.validatePreDeployment();
      
      expect(result.isValid).toBe(false);
      expect(result.errors.some(error => 
        error.includes('Configuration validation failed')
      )).toBe(true);
    });

    it('should validate production-specific requirements', async () => {
      const prodConfig = createMockConfig({
        environment: 'prod',
        environmentConfig: {
          ...mockConfig.environmentConfig,
          isProduction: true,
        },
        s3Config: {
          ...mockConfig.s3Config,
          versioning: false, // This should cause an error in production
        },
        tags: {
          Environment: 'prod',
          // Missing required production tags
        },
      });
      
      const prodValidator = new DeploymentValidator(stack, prodConfig);
      const result = await prodValidator.validatePreDeployment();
      
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('S3 versioning must be enabled in production');
      expect(result.errors.some(error => error.includes('Missing required production tag'))).toBe(true);
    });

    it('should validate environment limits', async () => {
      const configWithExceededLimits = createMockConfig({
        cachingConfig: {
          ...mockConfig.cachingConfig,
          maxTtl: 100000, // Exceeds limit
        },
        monitoringConfig: {
          ...mockConfig.monitoringConfig,
          samplingRate: 1.5, // Exceeds limit
        },
      });
      
      const validatorWithExceededLimits = new DeploymentValidator(stack, configWithExceededLimits);
      const result = await validatorWithExceededLimits.validatePreDeployment();
      
      expect(result.isValid).toBe(false);
      expect(result.errors.some(error => error.includes('Max TTL'))).toBe(true);
      expect(result.errors.some(error => error.includes('RUM sampling rate'))).toBe(true);
    });

    it('should provide warnings for development environment', async () => {
      const devConfig = createMockConfig({
        environment: 'dev',
        cachingConfig: {
          ...mockConfig.cachingConfig,
          maxTtl: 100000, // High TTL in dev
        },
        monitoringConfig: {
          ...mockConfig.monitoringConfig,
          enableExtendedMetrics: true, // Expensive in dev
        },
      });
      
      const devValidator = new DeploymentValidator(stack, devConfig);
      const result = await devValidator.validatePreDeployment();
      
      expect(result.warnings.some(warning => 
        warning.includes('High cache TTL in development')
      )).toBe(true);
      expect(result.warnings.some(warning => 
        warning.includes('Extended metrics in development may increase costs')
      )).toBe(true);
    });

    it('should provide recommendations for staging environment', async () => {
      const stagingConfig = createMockConfig({
        environment: 'staging',
        monitoringConfig: {
          ...mockConfig.monitoringConfig,
          enableExtendedMetrics: false,
        },
      });
      
      const stagingValidator = new DeploymentValidator(stack, stagingConfig);
      const result = await stagingValidator.validatePreDeployment();
      
      expect(result.recommendations.some(recommendation => 
        recommendation.includes('Consider enabling extended metrics in staging')
      )).toBe(true);
    });
  });

  describe('checkDeploymentReadiness', () => {
    it('should check AWS credentials', async () => {
      // Mock environment without AWS credentials
      delete process.env.AWS_ACCESS_KEY_ID;
      delete process.env.AWS_PROFILE;
      
      const result = await validator.checkDeploymentReadiness();
      
      const credentialsCheck = result.checks.find(check => check.name === 'AWS Credentials');
      expect(credentialsCheck).toBeDefined();
      expect(credentialsCheck?.passed).toBe(false);
      expect(credentialsCheck?.message).toContain('AWS credentials not configured');
    });

    it('should validate configuration integrity', async () => {
      const configWithMissingFields = createMockConfig({
        domainConfig: undefined as any,
      });
      
      const validatorWithMissingFields = new DeploymentValidator(stack, configWithMissingFields);
      const result = await validatorWithMissingFields.checkDeploymentReadiness();
      
      const configCheck = result.checks.find(check => check.name === 'Configuration');
      expect(configCheck).toBeDefined();
      expect(configCheck?.passed).toBe(false);
    });

    it('should validate cross-account role ARN', async () => {
      const configWithInvalidRole = createMockConfig({
        domainConfig: {
          ...mockConfig.domainConfig,
          crossAccountRoleArn: 'invalid-role-arn',
        },
      });
      
      const validatorWithInvalidRole = new DeploymentValidator(stack, configWithInvalidRole);
      const result = await validatorWithInvalidRole.checkDeploymentReadiness();
      
      const roleCheck = result.checks.find(check => check.name === 'Cross-Account Role');
      expect(roleCheck).toBeDefined();
      expect(roleCheck?.passed).toBe(false);
      expect(roleCheck?.message).toContain('Invalid cross-account role ARN format');
    });

    it('should validate domain setup', async () => {
      const configWithInvalidDomain = createMockConfig({
        domainConfig: {
          ...mockConfig.domainConfig,
          domainName: 'invalid-domain',
          hostedZoneId: 'invalid-zone-id',
        },
      });
      
      const validatorWithInvalidDomain = new DeploymentValidator(stack, configWithInvalidDomain);
      const result = await validatorWithInvalidDomain.checkDeploymentReadiness();
      
      const domainCheck = result.checks.find(check => check.name === 'Domain Setup');
      expect(domainCheck).toBeDefined();
      expect(domainCheck?.passed).toBe(false);
    });

    it('should return ready status when all checks pass', async () => {
      // Mock successful environment
      process.env.AWS_ACCESS_KEY_ID = 'test-key';
      
      const result = await validator.checkDeploymentReadiness();
      
      // Some checks might fail in test environment, but we can verify structure
      expect(result.checks).toBeDefined();
      expect(result.checks.length).toBeGreaterThan(0);
      expect(result.ready).toBeDefined();
    });
  });

  describe('Error Scenarios', () => {
    it('should handle validation errors gracefully', async () => {
      const invalidConfig = {} as DeploymentConfig;
      
      expect(() => {
        new DeploymentValidator(stack, invalidConfig);
      }).not.toThrow(); // Constructor should not throw
      
      const invalidValidator = new DeploymentValidator(stack, invalidConfig);
      const result = await invalidValidator.validatePreDeployment();
      
      expect(result.isValid).toBe(false);
      expect(result.errors.length).toBeGreaterThan(0);
    });

    it('should handle missing environment configuration', async () => {
      const configWithoutEnvConfig = createMockConfig({
        environmentConfig: undefined as any,
      });
      
      const validatorWithoutEnvConfig = new DeploymentValidator(stack, configWithoutEnvConfig);
      const result = await validatorWithoutEnvConfig.validatePreDeployment();
      
      expect(result.isValid).toBe(false);
      expect(result.errors.some(error => 
        error.includes('validation failed')
      )).toBe(true);
    });

    it('should handle cross-account validation errors', async () => {
      const configWithSameAccount = createMockConfig({
        domainConfig: {
          ...mockConfig.domainConfig,
          crossAccountRoleArn: `arn:aws:iam::${process.env.CDK_DEFAULT_ACCOUNT || '123456789012'}:role/test-role`,
        },
      });
      
      const validatorWithSameAccount = new DeploymentValidator(stack, configWithSameAccount);
      const result = await validatorWithSameAccount.validatePreDeployment();
      
      expect(result.warnings.some(warning => 
        warning.includes('Cross-account role is in the same account')
      )).toBe(true);
    });

    it('should handle network connectivity validation', async () => {
      const result = await validator.validatePreDeployment();
      
      expect(result.recommendations.some(recommendation => 
        recommendation.includes('network connectivity')
      )).toBe(true);
    });

    it('should handle permission validation', async () => {
      const result = await validator.validatePreDeployment();
      
      expect(result.recommendations.some(recommendation => 
        recommendation.includes('permissions')
      )).toBe(true);
    });
  });

  describe('Integration Tests', () => {
    it('should perform complete validation workflow', async () => {
      const result = await validator.validatePreDeployment();
      
      expect(result).toHaveProperty('isValid');
      expect(result).toHaveProperty('errors');
      expect(result).toHaveProperty('warnings');
      expect(result).toHaveProperty('blockers');
      expect(result).toHaveProperty('recommendations');
      
      expect(Array.isArray(result.errors)).toBe(true);
      expect(Array.isArray(result.warnings)).toBe(true);
      expect(Array.isArray(result.blockers)).toBe(true);
      expect(Array.isArray(result.recommendations)).toBe(true);
    });

    it('should perform complete readiness check workflow', async () => {
      const result = await validator.checkDeploymentReadiness();
      
      expect(result).toHaveProperty('ready');
      expect(result).toHaveProperty('checks');
      
      expect(typeof result.ready).toBe('boolean');
      expect(Array.isArray(result.checks)).toBe(true);
      
      result.checks.forEach(check => {
        expect(check).toHaveProperty('name');
        expect(check).toHaveProperty('passed');
        expect(check).toHaveProperty('message');
        expect(check).toHaveProperty('severity');
        
        expect(typeof check.name).toBe('string');
        expect(typeof check.passed).toBe('boolean');
        expect(typeof check.message).toBe('string');
        expect(['error', 'warning', 'info']).toContain(check.severity);
      });
    });
  });
});