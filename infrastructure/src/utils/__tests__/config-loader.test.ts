import * as fs from 'fs';
import * as path from 'path';
import { 
  loadConfig, 
  getEnvironment, 
  generateResourceName, 
  getCostAllocationTags,
  validateRegion,
  getConfigSummary
} from '../config-loader';
import { DeploymentConfig, Environment } from '../../types/config';

// Mock fs module
jest.mock('fs');
const mockFs = fs as jest.Mocked<typeof fs>;

describe('ConfigLoader', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    delete process.env.ENVIRONMENT;
    delete process.env.NODE_ENV;
  });

  describe('loadConfig', () => {
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
        enabledMetrics: ['PerformanceNavigationTiming'],
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
        includeRandomSuffix: true,
        customPatterns: {
          s3Bucket: 'minecraft-finder-web-dev-{random}'
        }
      },
      costAllocation: {
        costCenter: 'Engineering-Development',
        projectCode: 'MINECRAFT-FINDER-DEV',
        department: 'Engineering',
        budgetThreshold: 50,
        enableDetailedBilling: true,
        customCostTags: {
          BillingGroup: 'Development',
          Owner: 'DevTeam'
        }
      },
      tags: {
        Project: 'MinecraftOreFinder',
        Environment: 'dev',
        ManagedBy: 'CDK'
      }
    };

    it('should load valid configuration successfully', () => {
      mockFs.existsSync.mockReturnValue(true);
      mockFs.readFileSync.mockReturnValue(JSON.stringify(validConfig));

      const result = loadConfig('dev');

      expect(result).toEqual(expect.objectContaining({
        environment: 'dev',
        environmentConfig: expect.any(Object),
        domainConfig: expect.any(Object)
      }));
    });

    it('should throw error when config file does not exist', () => {
      mockFs.existsSync.mockReturnValue(false);

      expect(() => loadConfig('dev')).toThrow('Configuration file not found for environment: dev');
    });

    it('should throw error when config file is invalid JSON', () => {
      mockFs.existsSync.mockReturnValue(true);
      mockFs.readFileSync.mockReturnValue('invalid json');

      expect(() => loadConfig('dev')).toThrow('Failed to load configuration for environment dev');
    });

    it('should validate required fields', () => {
      const invalidConfig = { ...validConfig };
      delete (invalidConfig as any).domainConfig;

      mockFs.existsSync.mockReturnValue(true);
      mockFs.readFileSync.mockReturnValue(JSON.stringify(invalidConfig));

      expect(() => loadConfig('dev')).toThrow('Configuration validation failed');
    });

    it('should enforce environment limits', () => {
      const configWithHighLimits = {
        ...validConfig,
        cachingConfig: {
          ...validConfig.cachingConfig,
          maxTtl: 999999999 // Exceeds limit
        },
        monitoringConfig: {
          ...validConfig.monitoringConfig,
          samplingRate: 0.8 // Exceeds limit
        }
      };

      mockFs.existsSync.mockReturnValue(true);
      mockFs.readFileSync.mockReturnValue(JSON.stringify(configWithHighLimits));

      const consoleSpy = jest.spyOn(console, 'warn').mockImplementation();
      const result = loadConfig('dev');

      expect(consoleSpy).toHaveBeenCalledWith(expect.stringContaining('Max TTL'));
      expect(consoleSpy).toHaveBeenCalledWith(expect.stringContaining('RUM sampling rate'));
      expect(result.cachingConfig.maxTtl).toBe(86400); // Adjusted to limit
      expect(result.monitoringConfig.samplingRate).toBe(0.5); // Adjusted to limit

      consoleSpy.mockRestore();
    });
  });

  describe('getEnvironment', () => {
    it('should return environment from ENVIRONMENT variable', () => {
      process.env.ENVIRONMENT = 'staging';
      expect(getEnvironment()).toBe('staging');
    });

    it('should return environment from NODE_ENV variable', () => {
      process.env.NODE_ENV = 'prod';
      expect(getEnvironment()).toBe('prod');
    });

    it('should default to dev when no environment is set', () => {
      expect(getEnvironment()).toBe('dev');
    });

    it('should default to dev for invalid environment', () => {
      process.env.ENVIRONMENT = 'invalid';
      const consoleSpy = jest.spyOn(console, 'warn').mockImplementation();
      
      expect(getEnvironment()).toBe('dev');
      expect(consoleSpy).toHaveBeenCalledWith(expect.stringContaining('Invalid environment'));
      
      consoleSpy.mockRestore();
    });
  });

  describe('generateResourceName', () => {
    const mockConfig: DeploymentConfig = {
      environment: 'dev',
      resourceNaming: {
        resourcePrefix: 'minecraft-finder',
        resourceSuffix: 'dev',
        includeEnvironment: true,
        includeRandomSuffix: false,
        customPatterns: {
          s3Bucket: 'custom-bucket-name'
        }
      }
    } as DeploymentConfig;

    it('should use custom pattern when available', () => {
      const result = generateResourceName(mockConfig, 's3Bucket');
      expect(result).toBe('custom-bucket-name');
    });

    it('should generate standard name when no custom pattern', () => {
      const result = generateResourceName(mockConfig, 'cloudFrontDistribution');
      expect(result).toBe('minecraft-finder-dev-dev');
    });

    it('should include random suffix when configured', () => {
      const configWithRandom = {
        ...mockConfig,
        resourceNaming: {
          ...mockConfig.resourceNaming,
          includeRandomSuffix: true,
          customPatterns: {
            s3Bucket: 'bucket-{random}'
          }
        }
      };

      const result = generateResourceName(configWithRandom, 's3Bucket');
      expect(result).toMatch(/^bucket-[a-f0-9]{8}$/);
    });

    it('should use base name when provided', () => {
      const result = generateResourceName(mockConfig, 'certificate', 'custom-base');
      expect(result).toBe('custom-base-dev-dev');
    });
  });

  describe('getCostAllocationTags', () => {
    const mockConfig: DeploymentConfig = {
      environment: 'dev',
      costAllocation: {
        costCenter: 'Engineering-Dev',
        projectCode: 'MINECRAFT-DEV',
        department: 'Engineering',
        enableDetailedBilling: true,
        customCostTags: {
          BillingGroup: 'Development',
          Owner: 'DevTeam'
        }
      },
      tags: {
        Project: 'MinecraftOreFinder',
        Environment: 'dev'
      }
    } as DeploymentConfig;

    it('should return combined cost allocation tags', () => {
      const result = getCostAllocationTags(mockConfig);

      expect(result).toEqual(expect.objectContaining({
        CostCenter: 'Engineering-Dev',
        ProjectCode: 'MINECRAFT-DEV',
        Department: 'Engineering',
        Environment: 'dev',
        BillingGroup: 'Development',
        Owner: 'DevTeam',
        Project: 'MinecraftOreFinder'
      }));
    });

    it('should merge additional tags', () => {
      const additionalTags = { CustomTag: 'CustomValue' };
      const result = getCostAllocationTags(mockConfig, additionalTags);

      expect(result).toEqual(expect.objectContaining({
        CustomTag: 'CustomValue'
      }));
    });
  });

  describe('validateRegion', () => {
    const mockConfig: DeploymentConfig = {
      environmentConfig: {
        allowedRegions: ['us-east-1', 'us-west-2']
      }
    } as DeploymentConfig;

    it('should pass validation for allowed region', () => {
      expect(() => validateRegion(mockConfig, 'us-east-1')).not.toThrow();
    });

    it('should throw error for disallowed region', () => {
      expect(() => validateRegion(mockConfig, 'eu-west-1')).toThrow(
        'Region eu-west-1 is not allowed for environment'
      );
    });
  });

  describe('getConfigSummary', () => {
    const mockConfig: DeploymentConfig = {
      environment: 'dev',
      environmentConfig: {
        isProduction: false,
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
        domainName: 'dev-minecraft.lockhead.cloud'
      },
      costAllocation: {
        costCenter: 'Engineering-Dev',
        projectCode: 'MINECRAFT-DEV',
        budgetThreshold: 50
      }
    } as DeploymentConfig;

    it('should return configuration summary', () => {
      const result = getConfigSummary(mockConfig);

      expect(result).toEqual({
        environment: 'dev',
        isProduction: false,
        domain: 'dev-minecraft.lockhead.cloud',
        costCenter: 'Engineering-Dev',
        projectCode: 'MINECRAFT-DEV',
        budgetThreshold: 50,
        featureFlags: expect.any(Object),
        limits: expect.any(Object)
      });
    });
  });

  describe('Configuration Validation', () => {
    it('should validate environment configuration structure', () => {
      const invalidConfig = {
        environment: 'dev',
        environmentConfig: {
          // Missing required fields
        },
        domainConfig: {
          domainName: 'test.com',
          hostedZoneId: 'Z123',
          crossAccountRoleArn: 'arn:aws:iam::123:role/test',
          certificateRegion: 'us-east-1'
        },
        monitoringConfig: {
          rumAppName: 'test',
          samplingRate: 0.1,
          enabledMetrics: [],
          enableExtendedMetrics: false
        },
        cachingConfig: {
          defaultTtl: 3600,
          maxTtl: 86400,
          staticAssetsTtl: 86400,
          htmlTtl: 300
        },
        s3Config: {
          bucketNamePrefix: 'test',
          versioning: true,
          publicReadAccess: false,
          lifecycleRules: []
        },
        resourceNaming: {
          resourcePrefix: 'test',
          resourceSuffix: 'dev',
          includeEnvironment: true,
          includeRandomSuffix: false
        },
        costAllocation: {
          costCenter: 'test',
          projectCode: 'test',
          department: 'test',
          enableDetailedBilling: true
        },
        tags: {
          Project: 'test'
        }
      };

      mockFs.existsSync.mockReturnValue(true);
      mockFs.readFileSync.mockReturnValue(JSON.stringify(invalidConfig));

      expect(() => loadConfig('dev')).toThrow('Configuration validation failed');
    });

    it('should validate placeholder values are replaced', () => {
      const configWithPlaceholders = {
        environment: 'dev',
        environmentConfig: {
          name: 'dev',
          description: 'test',
          isProduction: false,
          allowedRegions: ['us-east-1'],
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
          domainName: 'test.com',
          hostedZoneId: 'REPLACE_WITH_HOSTED_ZONE_ID', // Placeholder
          crossAccountRoleArn: 'arn:aws:iam::123:role/test',
          certificateRegion: 'us-east-1'
        },
        monitoringConfig: {
          rumAppName: 'test',
          samplingRate: 0.1,
          enabledMetrics: [],
          enableExtendedMetrics: false
        },
        cachingConfig: {
          defaultTtl: 3600,
          maxTtl: 86400,
          staticAssetsTtl: 86400,
          htmlTtl: 300
        },
        s3Config: {
          bucketNamePrefix: 'test',
          versioning: true,
          publicReadAccess: false,
          lifecycleRules: []
        },
        resourceNaming: {
          resourcePrefix: 'test',
          resourceSuffix: 'dev',
          includeEnvironment: true,
          includeRandomSuffix: false
        },
        costAllocation: {
          costCenter: 'test',
          projectCode: 'test',
          department: 'test',
          enableDetailedBilling: true
        },
        tags: {
          Project: 'test'
        }
      };

      mockFs.existsSync.mockReturnValue(true);
      mockFs.readFileSync.mockReturnValue(JSON.stringify(configWithPlaceholders));

      expect(() => loadConfig('dev')).toThrow('Missing or placeholder hosted zone ID');
    });
  });
});