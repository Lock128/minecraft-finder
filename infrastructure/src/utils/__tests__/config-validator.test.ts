import { 
  validateDeploymentConfig, 
  validateEnvironmentLimits, 
  generateValidationReport 
} from '../config-validator';
import { DeploymentConfig } from '../../types/config';

describe('ConfigValidator', () => {
  const validConfig: DeploymentConfig = {
    environment: 'dev',
    environmentConfig: {
      name: 'dev',
      description: 'Development environment',
      isProduction: false,
      allowedRegions: ['us-east-1', 'us-west-2'],
      featureFlags: {
        enableAdvancedMonitoring: false,
        enableCostOptimization: true,
        enableSecurityHardening: false,
        enablePerformanceOptimization: false
      },
      limits: {
        maxCacheTtl: 86400,
        maxRumSamplingRate: 0.5,
        maxS3LifecycleDays: 90
      }
    },
    domainConfig: {
      domainName: 'dev-minecraft.lockhead.cloud',
      hostedZoneId: 'Z123456789',
      crossAccountRoleArn: 'arn:aws:iam::123456789012:role/CrossAccountRole',
      certificateRegion: 'us-east-1'
    },
    monitoringConfig: {
      rumAppName: 'minecraft-finder-dev',
      samplingRate: 0.1,
      enabledMetrics: ['PerformanceNavigationTiming', 'LargestContentfulPaint'],
      enableExtendedMetrics: false
    },
    cachingConfig: {
      defaultTtl: 3600,
      maxTtl: 86400,
      staticAssetsTtl: 86400,
      htmlTtl: 300
    },
    s3Config: {
      bucketNamePrefix: 'minecraft-finder-web-dev',
      versioning: true,
      publicReadAccess: false,
      lifecycleRules: [{
        id: 'DeleteOldVersions',
        enabled: true,
        transitionToIADays: 30,
        expirationDays: 90,
        abortIncompleteMultipartUploadDays: 7
      }]
    },
    resourceNaming: {
      resourcePrefix: 'minecraft-finder',
      resourceSuffix: 'dev',
      includeEnvironment: true,
      includeRandomSuffix: true
    },
    costAllocation: {
      costCenter: 'Engineering-Development',
      projectCode: 'MINECRAFT-FINDER-DEV',
      department: 'Engineering',
      budgetThreshold: 50,
      enableDetailedBilling: true
    },
    tags: {
      Project: 'MinecraftOreFinder',
      Environment: 'dev',
      ManagedBy: 'CDK',
      CostCenter: 'Engineering-Development',
      ProjectCode: 'MINECRAFT-FINDER-DEV',
      Department: 'Engineering'
    }
  };

  describe('validateDeploymentConfig', () => {
    it('should validate a correct configuration', () => {
      const result = validateDeploymentConfig(validConfig);
      
      expect(result.isValid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('should detect missing required properties', () => {
      const invalidConfig = { ...validConfig };
      delete (invalidConfig as any).domainConfig;
      
      const result = validateDeploymentConfig(invalidConfig);
      
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Missing required property: domainConfig');
    });

    it('should detect invalid environment', () => {
      const invalidConfig = { ...validConfig, environment: 'invalid' as any };
      
      const result = validateDeploymentConfig(invalidConfig);
      
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Invalid environment: invalid. Must be one of: dev, staging, prod');
    });

    it('should detect placeholder values', () => {
      const configWithPlaceholders = {
        ...validConfig,
        domainConfig: {
          ...validConfig.domainConfig,
          hostedZoneId: 'REPLACE_WITH_HOSTED_ZONE_ID'
        }
      };
      
      const result = validateDeploymentConfig(configWithPlaceholders);
      
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Hosted zone ID contains placeholder value');
    });

    it('should detect invalid ARN format', () => {
      const configWithInvalidArn = {
        ...validConfig,
        domainConfig: {
          ...validConfig.domainConfig,
          crossAccountRoleArn: 'invalid-arn-format'
        }
      };
      
      const result = validateDeploymentConfig(configWithInvalidArn);
      
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Invalid cross-account role ARN format');
    });

    it('should detect public S3 access', () => {
      const configWithPublicS3 = {
        ...validConfig,
        s3Config: {
          ...validConfig.s3Config,
          publicReadAccess: true
        }
      };
      
      const result = validateDeploymentConfig(configWithPublicS3);
      
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('S3 bucket should not have public read access when using CloudFront');
    });

    it('should detect wrong certificate region', () => {
      const configWithWrongRegion = {
        ...validConfig,
        domainConfig: {
          ...validConfig.domainConfig,
          certificateRegion: 'us-west-2'
        }
      };
      
      const result = validateDeploymentConfig(configWithWrongRegion);
      
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Certificate must be in us-east-1 region for CloudFront');
    });
  });

  describe('Production-specific validations', () => {
    const prodConfig: DeploymentConfig = {
      ...validConfig,
      environment: 'prod',
      environmentConfig: {
        ...validConfig.environmentConfig,
        isProduction: true
      }
    };

    it('should require versioning in production', () => {
      const configWithoutVersioning = {
        ...prodConfig,
        s3Config: {
          ...prodConfig.s3Config,
          versioning: false
        }
      };
      
      const result = validateDeploymentConfig(configWithoutVersioning);
      
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('S3 versioning must be enabled in production');
    });

    it('should require production tags', () => {
      const configWithoutTags = {
        ...prodConfig,
        tags: {
          Project: 'MinecraftOreFinder'
          // Missing required production tags
        }
      };
      
      const result = validateDeploymentConfig(configWithoutTags);
      
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Missing required production tag: CostCenter');
      expect(result.errors).toContain('Missing required production tag: ProjectCode');
      expect(result.errors).toContain('Missing required production tag: Department');
      expect(result.errors).toContain('Missing required production tag: Owner');
    });

    it('should warn about high RUM sampling in production', () => {
      const configWithHighSampling = {
        ...prodConfig,
        monitoringConfig: {
          ...prodConfig.monitoringConfig,
          samplingRate: 0.8
        }
      };
      
      const result = validateDeploymentConfig(configWithHighSampling);
      
      expect(result.warnings).toContain('High RUM sampling rate in production may increase costs significantly');
    });
  });

  describe('Development-specific validations', () => {
    it('should warn about high cache TTL in development', () => {
      const configWithHighTtl = {
        ...validConfig,
        cachingConfig: {
          ...validConfig.cachingConfig,
          maxTtl: 604800 // 7 days
        }
      };
      
      const result = validateDeploymentConfig(configWithHighTtl);
      
      expect(result.warnings).toContain('High cache TTL in development may make testing difficult');
    });

    it('should warn about extended metrics in development', () => {
      const configWithExtendedMetrics = {
        ...validConfig,
        monitoringConfig: {
          ...validConfig.monitoringConfig,
          enableExtendedMetrics: true
        }
      };
      
      const result = validateDeploymentConfig(configWithExtendedMetrics);
      
      expect(result.warnings).toContain('Extended metrics in development may increase costs unnecessarily');
    });
  });

  describe('Cost optimization validations', () => {
    it('should warn about missing lifecycle rules', () => {
      const configWithoutLifecycle = {
        ...validConfig,
        s3Config: {
          ...validConfig.s3Config,
          lifecycleRules: []
        }
      };
      
      const result = validateDeploymentConfig(configWithoutLifecycle);
      
      expect(result.warnings).toContain('No S3 lifecycle rules configured - consider adding rules for cost optimization');
    });

    it('should warn about low static assets TTL', () => {
      const configWithLowTtl = {
        ...validConfig,
        cachingConfig: {
          ...validConfig.cachingConfig,
          staticAssetsTtl: 3600 // 1 hour
        }
      };
      
      const result = validateDeploymentConfig(configWithLowTtl);
      
      expect(result.warnings).toContain('Low static assets TTL may increase CloudFront costs');
    });
  });

  describe('validateEnvironmentLimits', () => {
    it('should validate within limits', () => {
      const result = validateEnvironmentLimits(validConfig);
      
      expect(result.isValid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('should detect TTL exceeding limits', () => {
      const configExceedingLimits = {
        ...validConfig,
        cachingConfig: {
          ...validConfig.cachingConfig,
          maxTtl: 999999 // Exceeds limit of 86400
        }
      };
      
      const result = validateEnvironmentLimits(configExceedingLimits);
      
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Max TTL 999999 exceeds environment limit 86400');
    });

    it('should detect RUM sampling rate exceeding limits', () => {
      const configExceedingLimits = {
        ...validConfig,
        monitoringConfig: {
          ...validConfig.monitoringConfig,
          samplingRate: 0.8 // Exceeds limit of 0.5
        }
      };
      
      const result = validateEnvironmentLimits(configExceedingLimits);
      
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('RUM sampling rate 0.8 exceeds environment limit 0.5');
    });

    it('should detect S3 lifecycle exceeding limits', () => {
      const configExceedingLimits = {
        ...validConfig,
        s3Config: {
          ...validConfig.s3Config,
          lifecycleRules: [{
            id: 'test',
            enabled: true,
            expirationDays: 365 // Exceeds limit of 90
          }]
        }
      };
      
      const result = validateEnvironmentLimits(configExceedingLimits);
      
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('S3 lifecycle rule 1 expiration 365 exceeds environment limit 90');
    });

    it('should handle missing limits configuration', () => {
      const configWithoutLimits = {
        ...validConfig,
        environmentConfig: {
          ...validConfig.environmentConfig,
          limits: undefined as any
        }
      };
      
      const result = validateEnvironmentLimits(configWithoutLimits);
      
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Environment limits not configured');
    });
  });

  describe('generateValidationReport', () => {
    it('should generate report for valid configuration', () => {
      const report = generateValidationReport(validConfig);
      
      expect(report).toContain('Configuration Validation Report for dev environment');
      expect(report).toContain('Overall Status: VALID');
      expect(report).toContain('✅ Configuration is valid and ready for deployment');
    });

    it('should generate report with errors', () => {
      const invalidConfig = { ...validConfig };
      delete (invalidConfig as any).domainConfig;
      
      const report = generateValidationReport(invalidConfig);
      
      expect(report).toContain('Overall Status: INVALID');
      expect(report).toContain('ERRORS:');
      expect(report).toContain('Missing required property: domainConfig');
      expect(report).toContain('❌ Configuration has errors that must be fixed before deployment');
    });

    it('should generate report with warnings', () => {
      const configWithWarnings = {
        ...validConfig,
        cachingConfig: {
          ...validConfig.cachingConfig,
          staticAssetsTtl: 3600 // Will generate warning
        }
      };
      
      const report = generateValidationReport(configWithWarnings);
      
      expect(report).toContain('WARNINGS:');
      expect(report).toContain('Low static assets TTL may increase CloudFront costs');
    });
  });
});