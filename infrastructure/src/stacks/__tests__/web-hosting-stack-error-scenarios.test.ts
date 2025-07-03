import { App, Stack } from 'aws-cdk-lib';
import { WebHostingStack, WebHostingStackProps } from '../web-hosting-stack';
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

describe('WebHostingStack Error Scenarios', () => {
  let app: App;

  beforeEach(() => {
    app = new App();
  });

  describe('Configuration Validation Errors', () => {
    it('should throw error for missing configuration', () => {
      expect(() => {
        new WebHostingStack(app, 'TestStack', {
          config: undefined as any,
          env: { region: 'us-east-1' }
        });
      }).toThrow();
    });

    it('should throw error for invalid domain name', () => {
      const configWithInvalidDomain = createMockConfig({
        domainConfig: {
          domainName: 'invalid..domain',
          hostedZoneId: 'Z1234567890ABC',
          crossAccountRoleArn: 'arn:aws:iam::123456789012:role/test-role',
          certificateRegion: 'us-east-1',
        },
      });

      expect(() => {
        new WebHostingStack(app, 'TestStack', {
          config: configWithInvalidDomain,
          env: { region: 'us-east-1' }
        });
      }).toThrow('INVALID_DOMAIN_FORMAT');
    });

    it('should throw error for invalid ARN format', () => {
      const configWithInvalidArn = createMockConfig({
        domainConfig: {
          domainName: 'test.example.com',
          hostedZoneId: 'Z1234567890ABC',
          crossAccountRoleArn: 'invalid-arn-format',
          certificateRegion: 'us-east-1',
        },
      });

      expect(() => {
        new WebHostingStack(app, 'TestStack', {
          config: configWithInvalidArn,
          env: { region: 'us-east-1' }
        });
      }).toThrow('INVALID_ARN_FORMAT');
    });

    it('should throw error for wrong region', () => {
      const config = createMockConfig();

      expect(() => {
        new WebHostingStack(app, 'TestStack', {
          config,
          env: { region: 'eu-west-1' } // Wrong region
        });
      }).toThrow('INVALID_CERTIFICATE_REGION');
    });

    it('should throw error for disallowed region', () => {
      const configWithRestrictedRegions = createMockConfig({
        environmentConfig: {
          name: 'dev',
          description: 'Test environment',
          isProduction: false,
          allowedRegions: ['us-west-2'], // Only allow us-west-2
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
      });

      expect(() => {
        new WebHostingStack(app, 'TestStack', {
          config: configWithRestrictedRegions,
          env: { region: 'us-east-1' } // Not in allowed regions
        });
      }).toThrow('REGION_NOT_ALLOWED');
    });
  });

  describe('Production Environment Validation Errors', () => {
    it('should throw error for missing S3 versioning in production', () => {
      const prodConfigWithoutVersioning = createMockConfig({
        environment: 'prod',
        environmentConfig: {
          name: 'prod',
          description: 'Production environment',
          isProduction: true,
          allowedRegions: ['us-east-1'],
          featureFlags: {
            enableSecurityHardening: true,
            enableAdvancedMonitoring: true,
            enableCostOptimization: true,
            enablePerformanceOptimization: true,
          },
          limits: {
            maxCacheTtl: 86400,
            maxRumSamplingRate: 0.2,
            maxS3LifecycleDays: 365,
          },
        },
        s3Config: {
          bucketNamePrefix: 'prod-bucket',
          versioning: false, // This should cause an error in production
          publicReadAccess: false,
          lifecycleRules: [],
        },
      });

      expect(() => {
        new WebHostingStack(app, 'TestStack', {
          config: prodConfigWithoutVersioning,
          env: { region: 'us-east-1' }
        });
      }).toThrow('PROD_S3_VERSIONING_REQUIRED');
    });

    it('should throw error for missing required production tags', () => {
      const prodConfigWithoutTags = createMockConfig({
        environment: 'prod',
        environmentConfig: {
          name: 'prod',
          description: 'Production environment',
          isProduction: true,
          allowedRegions: ['us-east-1'],
          featureFlags: {
            enableSecurityHardening: true,
            enableAdvancedMonitoring: true,
            enableCostOptimization: true,
            enablePerformanceOptimization: true,
          },
          limits: {
            maxCacheTtl: 86400,
            maxRumSamplingRate: 0.2,
            maxS3LifecycleDays: 365,
          },
        },
        tags: {
          Environment: 'prod',
          // Missing required production tags: CostCenter, ProjectCode, Department, Owner
        },
      });

      expect(() => {
        new WebHostingStack(app, 'TestStack', {
          config: prodConfigWithoutTags,
          env: { region: 'us-east-1' }
        });
      }).toThrow('MISSING_PROD_TAG');
    });
  });

  describe('Environment Limits Validation Errors', () => {
    it('should throw error for cache TTL exceeding limits', () => {
      const configWithExceededCacheTtl = createMockConfig({
        cachingConfig: {
          defaultTtl: 3600,
          maxTtl: 100000, // Exceeds the limit of 86400
          staticAssetsTtl: 31536000,
          htmlTtl: 0,
        },
      });

      expect(() => {
        new WebHostingStack(app, 'TestStack', {
          config: configWithExceededCacheTtl,
          env: { region: 'us-east-1' }
        });
      }).toThrow('CACHE_TTL_LIMIT_EXCEEDED');
    });

    it('should throw error for RUM sampling rate exceeding limits', () => {
      const configWithExceededSamplingRate = createMockConfig({
        monitoringConfig: {
          rumAppName: 'test-app',
          samplingRate: 1.5, // Exceeds the limit of 1.0
          enabledMetrics: ['PageLoad'],
          enableExtendedMetrics: false,
        },
      });

      expect(() => {
        new WebHostingStack(app, 'TestStack', {
          config: configWithExceededSamplingRate,
          env: { region: 'us-east-1' }
        });
      }).toThrow('RUM_SAMPLING_RATE_LIMIT_EXCEEDED');
    });

    it('should throw error for S3 lifecycle days exceeding limits', () => {
      const configWithExceededLifecycleDays = createMockConfig({
        s3Config: {
          bucketNamePrefix: 'test-bucket',
          versioning: true,
          publicReadAccess: false,
          lifecycleRules: [
            {
              id: 'test-rule',
              enabled: true,
              expirationDays: 400, // Exceeds the limit of 365
              transitionToIADays: 30,
              abortIncompleteMultipartUploadDays: 7,
            },
          ],
        },
      });

      expect(() => {
        new WebHostingStack(app, 'TestStack', {
          config: configWithExceededLifecycleDays,
          env: { region: 'us-east-1' }
        });
      }).toThrow('S3_LIFECYCLE_LIMIT_EXCEEDED');
    });
  });

  describe('Missing Required Fields Errors', () => {
    it('should throw error for missing environment', () => {
      const configWithoutEnvironment = createMockConfig({
        environment: undefined as any,
      });

      expect(() => {
        new WebHostingStack(app, 'TestStack', {
          config: configWithoutEnvironment,
          env: { region: 'us-east-1' }
        });
      }).toThrow('REQUIRED_FIELD_MISSING');
    });

    it('should throw error for missing domain config', () => {
      const configWithoutDomainConfig = createMockConfig({
        domainConfig: undefined as any,
      });

      expect(() => {
        new WebHostingStack(app, 'TestStack', {
          config: configWithoutDomainConfig,
          env: { region: 'us-east-1' }
        });
      }).toThrow('REQUIRED_FIELD_MISSING');
    });

    it('should throw error for missing monitoring config', () => {
      const configWithoutMonitoringConfig = createMockConfig({
        monitoringConfig: undefined as any,
      });

      expect(() => {
        new WebHostingStack(app, 'TestStack', {
          config: configWithoutMonitoringConfig,
          env: { region: 'us-east-1' }
        });
      }).toThrow('REQUIRED_FIELD_MISSING');
    });

    it('should throw error for missing caching config', () => {
      const configWithoutCachingConfig = createMockConfig({
        cachingConfig: undefined as any,
      });

      expect(() => {
        new WebHostingStack(app, 'TestStack', {
          config: configWithoutCachingConfig,
          env: { region: 'us-east-1' }
        });
      }).toThrow('REQUIRED_FIELD_MISSING');
    });

    it('should throw error for missing S3 config', () => {
      const configWithoutS3Config = createMockConfig({
        s3Config: undefined as any,
      });

      expect(() => {
        new WebHostingStack(app, 'TestStack', {
          config: configWithoutS3Config,
          env: { region: 'us-east-1' }
        });
      }).toThrow('REQUIRED_FIELD_MISSING');
    });
  });

  describe('Resource Creation Error Handling', () => {
    it('should handle stack creation with valid configuration', () => {
      const validConfig = createMockConfig();

      expect(() => {
        new WebHostingStack(app, 'TestStack', {
          config: validConfig,
          env: { region: 'us-east-1' }
        });
      }).not.toThrow();
    });

    it('should create stack with minimal valid configuration', () => {
      const minimalConfig = createMockConfig({
        s3Config: {
          bucketNamePrefix: 'minimal',
          versioning: false,
          publicReadAccess: false,
          lifecycleRules: [],
        },
        cachingConfig: {
          defaultTtl: 0,
          maxTtl: 86400,
          staticAssetsTtl: 86400,
          htmlTtl: 0,
        },
        monitoringConfig: {
          rumAppName: 'minimal-app',
          samplingRate: 0.01,
          enabledMetrics: [],
          enableExtendedMetrics: false,
        },
      });

      expect(() => {
        new WebHostingStack(app, 'TestStack', {
          config: minimalConfig,
          env: { region: 'us-east-1' }
        });
      }).not.toThrow();
    });
  });

  describe('Edge Cases and Boundary Conditions', () => {
    it('should handle zero values in configuration', () => {
      const configWithZeroValues = createMockConfig({
        cachingConfig: {
          defaultTtl: 0,
          maxTtl: 0,
          staticAssetsTtl: 0,
          htmlTtl: 0,
        },
        monitoringConfig: {
          rumAppName: 'zero-app',
          samplingRate: 0,
          enabledMetrics: [],
          enableExtendedMetrics: false,
        },
      });

      expect(() => {
        new WebHostingStack(app, 'TestStack', {
          config: configWithZeroValues,
          env: { region: 'us-east-1' }
        });
      }).not.toThrow();
    });

    it('should handle maximum allowed values', () => {
      const configWithMaxValues = createMockConfig({
        cachingConfig: {
          defaultTtl: 86400,
          maxTtl: 86400, // At the limit
          staticAssetsTtl: 86400,
          htmlTtl: 86400,
        },
        monitoringConfig: {
          rumAppName: 'max-app',
          samplingRate: 1.0, // At the limit
          enabledMetrics: ['PageLoad', 'JavaScriptError', 'HttpError'],
          enableExtendedMetrics: true,
        },
      });

      expect(() => {
        new WebHostingStack(app, 'TestStack', {
          config: configWithMaxValues,
          env: { region: 'us-east-1' }
        });
      }).not.toThrow();
    });

    it('should handle empty arrays in configuration', () => {
      const configWithEmptyArrays = createMockConfig({
        s3Config: {
          bucketNamePrefix: 'empty-arrays',
          versioning: true,
          publicReadAccess: false,
          lifecycleRules: [], // Empty array
        },
        monitoringConfig: {
          rumAppName: 'empty-metrics-app',
          samplingRate: 0.1,
          enabledMetrics: [], // Empty array
          enableExtendedMetrics: false,
        },
      });

      expect(() => {
        new WebHostingStack(app, 'TestStack', {
          config: configWithEmptyArrays,
          env: { region: 'us-east-1' }
        });
      }).not.toThrow();
    });

    it('should handle very long domain names', () => {
      const longDomainName = 'very-long-subdomain-name-that-might-cause-issues.example.com';
      const configWithLongDomain = createMockConfig({
        domainConfig: {
          domainName: longDomainName,
          hostedZoneId: 'Z1234567890ABC',
          crossAccountRoleArn: 'arn:aws:iam::123456789012:role/test-role',
          certificateRegion: 'us-east-1',
        },
      });

      expect(() => {
        new WebHostingStack(app, 'TestStack', {
          config: configWithLongDomain,
          env: { region: 'us-east-1' }
        });
      }).not.toThrow();
    });
  });

  describe('Integration Error Scenarios', () => {
    it('should handle complex configuration with multiple potential issues', () => {
      const complexConfig = createMockConfig({
        environment: 'staging',
        environmentConfig: {
          name: 'staging',
          description: 'Staging environment with complex configuration',
          isProduction: false,
          allowedRegions: ['us-east-1', 'us-west-2', 'eu-west-1'],
          featureFlags: {
            enableSecurityHardening: true,
            enableAdvancedMonitoring: true,
            enableCostOptimization: false,
            enablePerformanceOptimization: true,
          },
          limits: {
            maxCacheTtl: 172800, // 2 days
            maxRumSamplingRate: 0.5,
            maxS3LifecycleDays: 730, // 2 years
          },
        },
        cachingConfig: {
          defaultTtl: 7200,
          maxTtl: 172800,
          staticAssetsTtl: 86400,
          htmlTtl: 3600,
        },
        monitoringConfig: {
          rumAppName: 'complex-staging-app',
          samplingRate: 0.3,
          enabledMetrics: ['PageLoad', 'JavaScriptError', 'HttpError', 'LargestContentfulPaint'],
          enableExtendedMetrics: true,
        },
        s3Config: {
          bucketNamePrefix: 'complex-staging-bucket',
          versioning: true,
          publicReadAccess: false,
          lifecycleRules: [
            {
              id: 'transition-rule',
              enabled: true,
              expirationDays: 365,
              transitionToIADays: 30,
              abortIncompleteMultipartUploadDays: 7,
            },
            {
              id: 'cleanup-rule',
              enabled: true,
              expirationDays: 90,
              transitionToIADays: undefined,
              abortIncompleteMultipartUploadDays: 1,
            },
          ],
        },
      });

      expect(() => {
        new WebHostingStack(app, 'TestStack', {
          config: complexConfig,
          env: { region: 'us-east-1' }
        });
      }).not.toThrow();
    });
  });
});