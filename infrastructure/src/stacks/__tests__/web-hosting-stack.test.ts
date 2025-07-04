import * as cdk from 'aws-cdk-lib';
import { Template, Match } from 'aws-cdk-lib/assertions';
import { WebHostingStack } from '../web-hosting-stack';
import { DeploymentConfig } from '../../types/config';

// Jest provides describe, it, beforeEach globally

/**
 * Test configuration for the web hosting stack
 */
const testConfig: DeploymentConfig = {
  environment: 'dev',
  environmentConfig: {
    name: 'dev',
    description: 'Development environment for testing',
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
      maxRumSamplingRate: 1,
      maxS3LifecycleDays: 90
    }
  },
  domainConfig: {
    domainName: 'test.minecraft.lockhead.cloud',
    hostedZoneId: 'Z1234567890ABC',
    crossAccountRoleArn: 'arn:aws:iam::123456789012:role/TestCrossAccountRole',
    certificateRegion: 'us-east-1',
  },
  monitoringConfig: {
    rumAppName: 'minecraft-finder-test',
    samplingRate: 0.1,
    enabledMetrics: ['performance', 'errors'],
    enableExtendedMetrics: false,
  },
  cachingConfig: {
    defaultTtl: 3600,
    maxTtl: 86400,
    staticAssetsTtl: 86400,
    htmlTtl: 300,
  },
  s3Config: {
    bucketNamePrefix: 'minecraft-finder-web-test',
    versioning: true,
    publicReadAccess: false,
    lifecycleRules: [
      {
        id: 'TestRule',
        enabled: true,
        transitionToIADays: 30,
        expirationDays: 90,
        abortIncompleteMultipartUploadDays: 7,
      },
    ],
  },
  resourceNaming: {
    resourcePrefix: 'minecraft-finder',
    resourceSuffix: 'test',
    includeEnvironment: true,
    includeRandomSuffix: false
  },
  costAllocation: {
    costCenter: 'Engineering-Test',
    projectCode: 'MINECRAFT-TEST',
    department: 'Engineering',
    enableDetailedBilling: true,
    budgetThreshold: 50
  },
  tags: {
    Project: 'MinecraftOreFinder',
    Environment: 'test',
    ManagedBy: 'CDK',
  },
};

describe('WebHostingStack', () => {
  let app: cdk.App;
  let stack: WebHostingStack;
  let template: Template;

  beforeEach(() => {
    app = new cdk.App();
    stack = new WebHostingStack(app, 'TestWebHostingStack', {
      config: testConfig,
      env: {
        account: '123456789012',
        region: 'us-east-1',
      },
    });
    template = Template.fromStack(stack);
  });

  describe('Stack Creation', () => {
    test('should create stack without errors', () => {
      expect(stack).toBeDefined();
      expect(stack.stackName).toBe('TestWebHostingStack');
    });

    test('should have correct environment configuration', () => {
      expect(stack.region).toBe('us-east-1');
      expect(stack.account).toBe('123456789012');
    });

    test('should apply stack-level tags', () => {
      const stackTags = cdk.Tags.of(stack);
      expect(stackTags).toBeDefined();
    });
  });

  describe('S3 Bucket', () => {
    test('should create S3 bucket with correct configuration', () => {
      template.hasResourceProperties('AWS::S3::Bucket', {
        WebsiteConfiguration: {
          IndexDocument: 'index.html',
          ErrorDocument: 'index.html',
        },
        PublicAccessBlockConfiguration: {
          BlockPublicAcls: true,
          BlockPublicPolicy: true,
          IgnorePublicAcls: true,
          RestrictPublicBuckets: true,
        },
        VersioningConfiguration: {
          Status: 'Enabled',
        },
      });
    });

    test('should create S3 bucket with lifecycle rules', () => {
      template.hasResourceProperties('AWS::S3::Bucket', {
        LifecycleConfiguration: {
          Rules: Match.arrayWith([
            Match.objectLike({
              Status: 'Enabled',
              Transitions: Match.arrayWith([
                Match.objectLike({
                  StorageClass: 'STANDARD_IA',
                  TransitionInDays: 30,
                }),
              ]),
            }),
          ]),
        },
      });
    });

    test('should have S3 bucket outputs', () => {
      template.hasOutput('S3BucketName', {
        Description: 'Name of the S3 bucket for static website hosting',
      });

      template.hasOutput('S3BucketArn', {
        Description: 'ARN of the S3 bucket',
      });
    });
  });

  describe('CloudFront Distribution', () => {
    test('should create CloudFront distribution', () => {
      template.hasResourceProperties('AWS::CloudFront::Distribution', {
        DistributionConfig: {
          Enabled: true,
          HttpVersion: 'http2and3',
          IPV6Enabled: true,
          DefaultRootObject: 'index.html',
        },
      });
    });

    test('should configure HTTPS redirect', () => {
      template.hasResourceProperties('AWS::CloudFront::Distribution', {
        DistributionConfig: {
          DefaultCacheBehavior: {
            ViewerProtocolPolicy: 'redirect-to-https',
          },
        },
      });
    });

    test('should configure error responses for SPA routing', () => {
      template.hasResourceProperties('AWS::CloudFront::Distribution', {
        DistributionConfig: {
          CustomErrorResponses: Match.arrayWith([
            {
              ErrorCode: 404,
              ResponseCode: 200,
              ResponsePagePath: '/index.html',
              ErrorCachingMinTTL: 300,
            },
            {
              ErrorCode: 403,
              ResponseCode: 200,
              ResponsePagePath: '/index.html',
              ErrorCachingMinTTL: 300,
            },
          ]),
        },
      });
    });

    test('should have CloudFront outputs', () => {
      template.hasOutput('CloudFrontDistributionId', {
        Description: 'CloudFront distribution ID for cache invalidation',
      });

      template.hasOutput('CloudFrontDistributionDomainName', {
        Description: 'CloudFront distribution domain name',
      });

      template.hasOutput('CloudFrontDistributionUrl', {
        Description: 'CloudFront distribution URL',
      });
    });
  });

  describe('ACM Certificate', () => {
    test('should create ACM certificate', () => {
      template.hasResourceProperties('AWS::CertificateManager::Certificate', {
        DomainName: testConfig.domainConfig.domainName,
        ValidationMethod: 'DNS',
      });
    });

    test('should have certificate output', () => {
      template.hasOutput('CertificateArn', {
        Description: 'ARN of the ACM certificate',
      });
    });
  });

  describe('CloudWatch RUM', () => {
    test('should create RUM application monitor', () => {
      template.hasResourceProperties('AWS::RUM::AppMonitor', {
        Name: `${testConfig.monitoringConfig.rumAppName}-${testConfig.environment}`,
        Domain: testConfig.domainConfig.domainName,
        AppMonitorConfiguration: {
          AllowCookies: true,
          EnableXRay: true,
          SessionSampleRate: testConfig.monitoringConfig.samplingRate,
        },
      });
    });

    test('should create RUM guest role', () => {
      template.hasResourceProperties('AWS::IAM::Role', {
        AssumeRolePolicyDocument: {
          Statement: Match.arrayWith([
            {
              Effect: 'Allow',
              Principal: {
                Service: 'rum.amazonaws.com',
              },
              Action: 'sts:AssumeRole',
            },
          ]),
        },
      });
    });

    test('should have RUM outputs', () => {
      template.hasOutput('RumApplicationName', {
        Description: 'CloudWatch RUM application name',
      });

      template.hasOutput('RumApplicationId', {
        Description: 'CloudWatch RUM application ID',
      });
    });
  });

  describe('DNS Management', () => {
    test('should create DNS management Lambda function', () => {
      template.hasResourceProperties('AWS::Lambda::Function', {
        Runtime: 'python3.11',
        Handler: 'index.lambda_handler',
        Description: 'DNS management with cross-account Route53 access',
      });
    });

    test('should create Lambda execution role with cross-account permissions', () => {
      // Check that there's a role for DNS management Lambda
      const roles = template.findResources('AWS::IAM::Role');
      const dnsManagementRole = Object.values(roles).find((role: any) => 
        role.Properties?.AssumeRolePolicyDocument?.Statement?.some((stmt: any) => 
          stmt.Principal?.Service === 'lambda.amazonaws.com'
        )
      );
      expect(dnsManagementRole).toBeDefined();
      
      // Check that there's a policy that allows assuming the cross-account role
      const policies = template.findResources('AWS::IAM::Policy');
      const crossAccountPolicy = Object.values(policies).find((policy: any) =>
        policy.Properties?.PolicyDocument?.Statement?.some((stmt: any) =>
          stmt.Action === 'sts:AssumeRole' && 
          stmt.Resource === testConfig.domainConfig.crossAccountRoleArn
        )
      );
      expect(crossAccountPolicy).toBeDefined();
    });
  });

  describe('Resource Dependencies', () => {
    test('should have proper resource dependencies', () => {
      // CloudFront should depend on S3 bucket and certificate
      expect(stack.cloudFrontDistribution.node.dependencies).toContain(stack.s3Bucket);
      expect(stack.cloudFrontDistribution.node.dependencies).toContain(stack.certificate);

      // DNS management should depend on CloudFront
      expect(stack.dnsManagement.node.dependencies).toContain(stack.cloudFrontDistribution);

      // RUM should depend on certificate
      expect(stack.rumMonitoring.node.dependencies).toContain(stack.certificate);
    });
  });

  describe('Stack Outputs', () => {
    test('should have all required outputs', () => {
      const expectedOutputs = [
        'S3BucketName',
        'S3BucketArn',
        'CloudFrontDistributionId',
        'CloudFrontDistributionDomainName',
        'CloudFrontDistributionUrl',
        'CustomDomainName',
        'CustomDomainUrl',
        'CertificateArn',
        'RumApplicationName',
        'RumApplicationId',
        'Environment',
        'Region',
        'DeploymentTimestamp',
        'StackVersion',
      ];

      expectedOutputs.forEach(outputName => {
        template.hasOutput(outputName, {});
      });
    });

    test('should have correct custom domain outputs', () => {
      template.hasOutput('CustomDomainName', {
        Value: testConfig.domainConfig.domainName,
        Description: 'Custom domain name for the application',
      });

      template.hasOutput('CustomDomainUrl', {
        Value: `https://${testConfig.domainConfig.domainName}`,
        Description: 'Custom domain URL for the application',
      });
    });

    test('should have environment and region outputs', () => {
      template.hasOutput('Environment', {
        Value: testConfig.environment,
        Description: 'Deployment environment',
      });

      template.hasOutput('Region', {
        Value: 'us-east-1',
        Description: 'AWS region where the stack is deployed',
      });
    });
  });

  describe('Stack Methods', () => {
    test('should return correct bucket name', () => {
      const bucketName = stack.getBucketName();
      expect(bucketName).toBeDefined();
      expect(typeof bucketName).toBe('string');
    });

    test('should return correct distribution ID', () => {
      const distributionId = stack.getDistributionId();
      expect(distributionId).toBeDefined();
      expect(typeof distributionId).toBe('string');
    });

    test('should return correct custom domain URL', () => {
      const customDomainUrl = stack.getCustomDomainUrl();
      expect(customDomainUrl).toBe(`https://${testConfig.domainConfig.domainName}`);
    });

    test('should return correct distribution URL', () => {
      const distributionUrl = stack.getDistributionUrl();
      expect(distributionUrl).toBeDefined();
      expect(typeof distributionUrl).toBe('string');
      expect(distributionUrl).toMatch(/^https:\/\//);
    });

    test('should return RUM client configuration', () => {
      const rumConfig = stack.getRumClientConfig();
      expect(rumConfig).toBeDefined();
      expect(rumConfig.applicationId).toBeDefined();
      expect(rumConfig.applicationRegion).toBe('us-east-1');
      expect(rumConfig.sessionSampleRate).toBe(testConfig.monitoringConfig.samplingRate);
    });

    test('should return RUM initialization script', () => {
      const rumScript = stack.getRumInitializationScript();
      expect(rumScript).toBeDefined();
      expect(rumScript).toContain('AwsRumClient');
      expect(rumScript).toContain(testConfig.monitoringConfig.samplingRate.toString());
    });

    test('should return deployment information', () => {
      const deploymentInfo = stack.getDeploymentInfo();
      expect(deploymentInfo).toBeDefined();
      expect(deploymentInfo.environment).toBe(testConfig.environment);
      expect(deploymentInfo.region).toBe('us-east-1');
      expect(deploymentInfo.stackName).toBe('TestWebHostingStack');
      expect(deploymentInfo.customDomainUrl).toBe(`https://${testConfig.domainConfig.domainName}`);
    });
  });

  describe('Error Handling', () => {
    test('should throw error for invalid region', () => {
      expect(() => {
        new WebHostingStack(app, 'InvalidRegionStack', {
          config: {
            ...testConfig,
            domainConfig: {
              ...testConfig.domainConfig,
              certificateRegion: 'us-east-1', // Required for CloudFront
            },
          },
          env: {
            account: '123456789012',
            region: 'us-west-2', // Different from certificate region
          },
        });
      }).toThrow('Stack must be deployed to us-east-1 region for CloudFront certificate');
    });

    test('should throw error for invalid domain name', () => {
      expect(() => {
        new WebHostingStack(app, 'InvalidDomainStack', {
          config: {
            ...testConfig,
            domainConfig: {
              ...testConfig.domainConfig,
              domainName: 'invalid-domain', // No TLD
            },
          },
          env: {
            account: '123456789012',
            region: 'us-east-1',
          },
        });
      }).toThrow('Invalid domain name format');
    });
  });

  describe('Resource Count', () => {
    test('should create expected number of resources', () => {
      const resources = template.toJSON().Resources;
      const resourceCount = Object.keys(resources).length;
      
      // Expect a reasonable number of resources (this will vary based on constructs)
      // S3 bucket, CloudFront distribution, ACM certificate, RUM app, Lambda functions, IAM roles, etc.
      expect(resourceCount).toBeGreaterThan(10);
      expect(resourceCount).toBeLessThan(70); // Reasonable upper bound (increased due to comprehensive security and monitoring)
    });

    test('should have correct resource types', () => {
      const expectedResourceTypes = [
        'AWS::S3::Bucket',
        'AWS::CloudFront::Distribution',
        'AWS::CertificateManager::Certificate',
        'AWS::RUM::AppMonitor',
        'AWS::Lambda::Function',
        'AWS::IAM::Role',
        'AWS::CloudFormation::CustomResource',
      ];

      expectedResourceTypes.forEach(resourceType => {
        // Check that at least one resource of each type exists
        const resources = template.findResources(resourceType);
        expect(Object.keys(resources).length).toBeGreaterThan(0);
      });
    });
  });
});

describe('WebHostingStack Integration', () => {
  test('should integrate with different environments', () => {
    const app = new cdk.App();
    
    const environments = ['dev', 'staging', 'prod'] as const;
    
    environments.forEach(env => {
      const envConfig: DeploymentConfig = {
        ...testConfig,
        environment: env,
        environmentConfig: {
          ...testConfig.environmentConfig,
          isProduction: env === 'prod',
        },
        domainConfig: {
          ...testConfig.domainConfig,
          domainName: `${env}.minecraft.lockhead.cloud`,
        },
        monitoringConfig: {
          ...testConfig.monitoringConfig,
          rumAppName: `minecraft-finder-${env}`,
          samplingRate: env === 'prod' ? 0.1 : 0.5,
        },
        // Add required production tags for prod environment
        tags: {
          ...testConfig.tags,
          ...(env === 'prod' ? {
            CostCenter: 'Engineering-Prod',
            ProjectCode: 'MINECRAFT-PROD',
            Department: 'Engineering',
            Owner: 'DevOps-Team',
          } : {}),
        },
      };

      const stack = new WebHostingStack(app, `TestStack-${env}`, {
        config: envConfig,
        env: {
          account: '123456789012',
          region: 'us-east-1',
        },
      });

      expect(stack).toBeDefined();
      expect(stack.getCustomDomainUrl()).toBe(`https://${env}.minecraft.lockhead.cloud`);
    });
  });

  test('should handle production-specific configurations', () => {
    const app = new cdk.App();
    
    const prodConfig: DeploymentConfig = {
      ...testConfig,
      environment: 'prod',
      environmentConfig: {
        ...testConfig.environmentConfig,
        isProduction: true,
      },
      monitoringConfig: {
        ...testConfig.monitoringConfig,
        samplingRate: 0.6, // High sampling rate to trigger warning
      },
      // Add required production tags
      tags: {
        ...testConfig.tags,
        CostCenter: 'Engineering-Prod',
        ProjectCode: 'MINECRAFT-PROD',
        Department: 'Engineering',
        Owner: 'DevOps-Team',
      },
    };

    // Mock console.warn to capture the warning
    const consoleSpy = jest.spyOn(console, 'warn').mockImplementation();

    const stack = new WebHostingStack(app, 'ProdStack', {
      config: prodConfig,
      env: {
        account: '123456789012',
        region: 'us-east-1',
      },
    });

    expect(stack).toBeDefined();
    expect(consoleSpy).toHaveBeenCalledWith('⚠️  High RUM sampling rate in production may increase costs');

    consoleSpy.mockRestore();
  });
});