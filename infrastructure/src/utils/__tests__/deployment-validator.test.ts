import { DeploymentValidator } from '../deployment-validator';
import { DeploymentConfig } from '../../types/config';
import { describe, it, beforeEach } from '@jest/globals';

// Mock configuration for testing
const createMockConfig = (overrides: Partial<DeploymentConfig> = {}): DeploymentConfig => {
  return {
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
      domainName: 'test.mycompany.com',
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
  };
};

describe('DeploymentValidator', () => {
  let mockConfig: DeploymentConfig;

  beforeEach(() => {
    mockConfig = createMockConfig();
  });

  describe('validatePreDeployment', () => {
    it('should pass validation with valid configuration', async () => {
      const validator = new DeploymentValidator(mockConfig);
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
      
      const validatorWithPlaceholders = new DeploymentValidator(configWithPlaceholders);
      const result = await validatorWithPlaceholders.validatePreDeployment();
      
      expect(result.isValid).toBe(false);
      expect(result.blockers).toContain('Hosted zone ID contains placeholder value - update configuration');
      expect(result.blockers).toContain('Cross-account role ARN contains placeholder value - update configuration');
    });

    it('should fail validation with invalid region', async () => {
      const configWithInvalidRegion = createMockConfig({
        domainConfig: {
          ...mockConfig.domainConfig,
          certificateRegion: 'eu-west-1',
        },
        environmentConfig: {
          ...mockConfig.environmentConfig,
          allowedRegions: ['us-east-1', 'us-west-2'],
        },
      });
      
      const validatorWithInvalidRegion = new DeploymentValidator(configWithInvalidRegion);
      const result = await validatorWithInvalidRegion.validatePreDeployment();
      
      expect(result.isValid).toBe(false);
      expect(result.blockers.some(blocker => 
        blocker.includes('Region eu-west-1 is not allowed')
      )).toBe(true);
    });
  });

  describe('checkDeploymentReadiness', () => {
    it('should check AWS credentials', async () => {
      const credentialsValidator = new DeploymentValidator(mockConfig);
      const result = await credentialsValidator.checkDeploymentReadiness();
      
      expect(result.checks).toBeDefined();
      expect(Array.isArray(result.checks)).toBe(true);
      expect(result.ready).toBeDefined();
      expect(typeof result.ready).toBe('boolean');
    });

    it('should validate configuration integrity', async () => {
      const configWithMissingFields = createMockConfig({
        domainConfig: undefined as any,
      });
      
      const validatorWithMissingFields = new DeploymentValidator(configWithMissingFields);
      const result = await validatorWithMissingFields.checkDeploymentReadiness();
      
      const configCheck = result.checks.find(check => check.name === 'Configuration');
      expect(configCheck).toBeDefined();
      expect(configCheck?.passed).toBe(false);
    });
  });

  describe('Error Handling', () => {
    it('should handle validation errors gracefully', async () => {
      const invalidConfig = {} as DeploymentConfig;
      
      expect(() => {
        new DeploymentValidator(invalidConfig);
      }).not.toThrow(); // Constructor should not throw
      
      const errorValidator = new DeploymentValidator(invalidConfig);
      const result = await errorValidator.validatePreDeployment();
      
      expect(result.isValid).toBe(false);
      expect(result.errors.length).toBeGreaterThan(0);
    });
  });

  describe('Integration Tests', () => {
    it('should perform complete validation workflow', async () => {
      const integrationValidator = new DeploymentValidator(mockConfig);
      const result = await integrationValidator.validatePreDeployment();
      
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
      const readinessValidator = new DeploymentValidator(mockConfig);
      const result = await readinessValidator.checkDeploymentReadiness();
      
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