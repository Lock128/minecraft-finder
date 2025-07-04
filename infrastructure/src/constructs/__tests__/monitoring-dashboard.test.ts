import { App, Stack } from 'aws-cdk-lib';
import { Template, Match } from 'aws-cdk-lib/assertions';
import * as s3 from 'aws-cdk-lib/aws-s3';
import { MonitoringDashboardConstruct } from '../monitoring-dashboard';
import { DeploymentConfig, Environment } from '../../types/config';

describe('MonitoringDashboardConstruct', () => {
  let app: App;
  let stack: Stack;
  let mockS3Bucket: s3.IBucket;
  let mockConfig: DeploymentConfig;

  beforeEach(() => {
    app = new App();
    stack = new Stack(app, 'TestStack', {
      env: { region: 'us-east-1', account: '123456789012' },
    });

    // Create mock S3 bucket
    mockS3Bucket = s3.Bucket.fromBucketName(stack, 'MockBucket', 'test-bucket');

    // Create mock configuration
    mockConfig = {
      environment: 'dev' as Environment,
      environmentConfig: {
        name: 'dev' as Environment,
        description: 'Development environment',
        isProduction: false,
        allowedRegions: ['us-east-1'],
        featureFlags: {
          enableAdvancedMonitoring: true,
          enableCostOptimization: true,
          enableSecurityHardening: true,
          enablePerformanceOptimization: true,
        },
        limits: {
          maxCacheTtl: 86400,
          maxRumSamplingRate: 1.0,
          maxS3LifecycleDays: 365,
        },
      },
      domainConfig: {
        domainName: 'test.minecraft.lockhead.cloud',
        hostedZoneId: 'Z123456789',
        crossAccountRoleArn: 'arn:aws:iam::123456789012:role/CrossAccountRole',
        certificateRegion: 'us-east-1',
      },
      monitoringConfig: {
        rumAppName: 'test-app',
        samplingRate: 0.1,
        enabledMetrics: ['errors', 'performance', 'http'],
        enableExtendedMetrics: true,
      },
      cachingConfig: {
        defaultTtl: 3600,
        maxTtl: 86400,
        staticAssetsTtl: 31536000,
        htmlTtl: 300,
      },
      s3Config: {
        bucketNamePrefix: 'test-bucket',
        versioning: true,
        publicReadAccess: false,
        lifecycleRules: [],
      },
      resourceNaming: {
        resourcePrefix: 'test',
        resourceSuffix: 'dev',
        includeEnvironment: true,
        includeRandomSuffix: false,
      },
      costAllocation: {
        costCenter: 'Engineering',
        projectCode: 'PROJ-001',
        department: 'IT',
        budgetThreshold: 100,
        enableDetailedBilling: true,
        customCostTags: {
          AlertEmail: 'alerts@example.com',
        },
      },
      tags: {
        Environment: 'dev',
        Project: 'WebHosting',
      },
    };
  });

  describe('construct creation', () => {
    it('should create monitoring dashboard construct successfully', () => {
      const construct = new MonitoringDashboardConstruct(stack, 'TestMonitoring', {
        config: mockConfig,
        s3Bucket: mockS3Bucket,
        distributionId: 'E123456789',
        distributionDomainName: 'd123456789.cloudfront.net',
        rumApplicationName: 'test-app-dev',
        customDomainName: 'test.minecraft.lockhead.cloud',
        environment: 'dev',
        tags: { Test: 'true' },
      });

      expect(construct).toBeDefined();
      expect(construct.applicationDashboard).toBeDefined();
      expect(construct.performanceDashboard).toBeDefined();
      expect(construct.costDashboard).toBeDefined();
      expect(construct.criticalAlertsTopic).toBeDefined();
      expect(construct.warningAlertsTopic).toBeDefined();
      expect(construct.costAlertsTopic).toBeDefined();
      expect(construct.uptimeCanary).toBeDefined();
      expect(construct.budget).toBeDefined();
      expect(construct.alarms).toBeDefined();
    });

    it('should create all required alarms', () => {
      const construct = new MonitoringDashboardConstruct(stack, 'TestMonitoring', {
        config: mockConfig,
        s3Bucket: mockS3Bucket,
        distributionId: 'E123456789',
        distributionDomainName: 'd123456789.cloudfront.net',
        rumApplicationName: 'test-app-dev',
        customDomainName: 'test.minecraft.lockhead.cloud',
        environment: 'dev',
      });

      expect(construct.alarms.highErrorRate).toBeDefined();
      expect(construct.alarms.highLatency).toBeDefined();
      expect(construct.alarms.lowCacheHitRatio).toBeDefined();
      expect(construct.alarms.budgetExceeded).toBeDefined();
      expect(construct.alarms.uptimeFailure).toBeDefined();
      expect(construct.alarms.rumErrorRate).toBeDefined();
    });
  });

  describe('CloudWatch resources', () => {
    it('should create CloudWatch dashboards', () => {
      new MonitoringDashboardConstruct(stack, 'TestMonitoring', {
        config: mockConfig,
        s3Bucket: mockS3Bucket,
        distributionId: 'E123456789',
        distributionDomainName: 'd123456789.cloudfront.net',
        rumApplicationName: 'test-app-dev',
        customDomainName: 'test.minecraft.lockhead.cloud',
        environment: 'dev',
      });

      const template = Template.fromStack(stack);

      // Check for dashboard creation
      template.hasResourceProperties('AWS::CloudWatch::Dashboard', {
        DashboardName: 'web-hosting-application-dev',
      });

      template.hasResourceProperties('AWS::CloudWatch::Dashboard', {
        DashboardName: 'web-hosting-performance-dev',
      });

      template.hasResourceProperties('AWS::CloudWatch::Dashboard', {
        DashboardName: 'web-hosting-cost-dev',
      });
    });

    it('should create CloudWatch alarms with correct thresholds', () => {
      new MonitoringDashboardConstruct(stack, 'TestMonitoring', {
        config: mockConfig,
        s3Bucket: mockS3Bucket,
        distributionId: 'E123456789',
        distributionDomainName: 'd123456789.cloudfront.net',
        rumApplicationName: 'test-app-dev',
        customDomainName: 'test.minecraft.lockhead.cloud',
        environment: 'dev',
      });

      const template = Template.fromStack(stack);

      // Check for high error rate alarm
      template.hasResourceProperties('AWS::CloudWatch::Alarm', {
        AlarmName: 'web-hosting-high-error-rate-dev',
        Threshold: 5,
        ComparisonOperator: 'GreaterThanThreshold',
      });

      // Check for high latency alarm
      template.hasResourceProperties('AWS::CloudWatch::Alarm', {
        AlarmName: 'web-hosting-high-latency-dev',
        Threshold: 2000,
        ComparisonOperator: 'GreaterThanThreshold',
      });

      // Check for low cache hit ratio alarm
      template.hasResourceProperties('AWS::CloudWatch::Alarm', {
        AlarmName: 'web-hosting-low-cache-hit-ratio-dev',
        Threshold: 80,
        ComparisonOperator: 'LessThanThreshold',
      });
    });
  });

  describe('SNS topics', () => {
    it('should create SNS topics for different alert types', () => {
      new MonitoringDashboardConstruct(stack, 'TestMonitoring', {
        config: mockConfig,
        s3Bucket: mockS3Bucket,
        distributionId: 'E123456789',
        distributionDomainName: 'd123456789.cloudfront.net',
        rumApplicationName: 'test-app-dev',
        customDomainName: 'test.minecraft.lockhead.cloud',
        environment: 'dev',
      });

      const template = Template.fromStack(stack);

      // Check for SNS topics
      template.hasResourceProperties('AWS::SNS::Topic', {
        TopicName: 'web-hosting-critical-alerts-dev',
        DisplayName: 'Web Hosting Critical Alerts - DEV',
      });

      template.hasResourceProperties('AWS::SNS::Topic', {
        TopicName: 'web-hosting-warning-alerts-dev',
        DisplayName: 'Web Hosting Warning Alerts - DEV',
      });

      template.hasResourceProperties('AWS::SNS::Topic', {
        TopicName: 'web-hosting-cost-alerts-dev',
        DisplayName: 'Web Hosting Cost Alerts - DEV',
      });
    });

    it('should create email subscriptions when alert email is configured', () => {
      new MonitoringDashboardConstruct(stack, 'TestMonitoring', {
        config: mockConfig,
        s3Bucket: mockS3Bucket,
        distributionId: 'E123456789',
        distributionDomainName: 'd123456789.cloudfront.net',
        rumApplicationName: 'test-app-dev',
        customDomainName: 'test.minecraft.lockhead.cloud',
        environment: 'dev',
      });

      const template = Template.fromStack(stack);

      // Check for email subscriptions
      template.hasResourceProperties('AWS::SNS::Subscription', {
        Protocol: 'email',
        Endpoint: 'alerts@example.com',
      });
    });
  });

  describe('Synthetics canary', () => {
    it('should create Synthetics canary for uptime monitoring', () => {
      new MonitoringDashboardConstruct(stack, 'TestMonitoring', {
        config: mockConfig,
        s3Bucket: mockS3Bucket,
        distributionId: 'E123456789',
        distributionDomainName: 'd123456789.cloudfront.net',
        rumApplicationName: 'test-app-dev',
        customDomainName: 'test.minecraft.lockhead.cloud',
        environment: 'dev',
      });

      const template = Template.fromStack(stack);

      // Check for canary creation
      template.hasResourceProperties('AWS::Synthetics::Canary', {
        Name: 'web-hosting-uptime-dev',
        Schedule: {
          Expression: 'rate(5 minutes)',
        },
        RuntimeVersion: 'syn-nodejs-puppeteer-6.2',
      });

      // Check for canary artifacts bucket
      template.hasResourceProperties('AWS::S3::Bucket', {
        BucketName: Match.stringLikeRegexp('web-hosting-canary-artifacts-dev-.*'),
      });
    });

    it('should create IAM role for canary with correct permissions', () => {
      new MonitoringDashboardConstruct(stack, 'TestMonitoring', {
        config: mockConfig,
        s3Bucket: mockS3Bucket,
        distributionId: 'E123456789',
        distributionDomainName: 'd123456789.cloudfront.net',
        rumApplicationName: 'test-app-dev',
        customDomainName: 'test.minecraft.lockhead.cloud',
        environment: 'dev',
      });

      const template = Template.fromStack(stack);

      // Check for canary role
      template.hasResourceProperties('AWS::IAM::Role', {
        AssumeRolePolicyDocument: {
          Statement: [
            {
              Effect: 'Allow',
              Principal: {
                Service: 'lambda.amazonaws.com',
              },
              Action: 'sts:AssumeRole',
            },
          ],
        },
      });
    });
  });

  describe('budget configuration', () => {
    it('should create budget with correct threshold', () => {
      new MonitoringDashboardConstruct(stack, 'TestMonitoring', {
        config: mockConfig,
        s3Bucket: mockS3Bucket,
        distributionId: 'E123456789',
        distributionDomainName: 'd123456789.cloudfront.net',
        rumApplicationName: 'test-app-dev',
        customDomainName: 'test.minecraft.lockhead.cloud',
        environment: 'dev',
      });

      const template = Template.fromStack(stack);

      // Check for budget creation
      template.hasResourceProperties('AWS::Budgets::Budget', {
        Budget: {
          BudgetName: 'web-hosting-budget-dev',
          BudgetType: 'COST',
          TimeUnit: 'MONTHLY',
          BudgetLimit: {
            Amount: 100,
            Unit: 'USD',
          },
        },
      });
    });

    it('should create budget notifications', () => {
      new MonitoringDashboardConstruct(stack, 'TestMonitoring', {
        config: mockConfig,
        s3Bucket: mockS3Bucket,
        distributionId: 'E123456789',
        distributionDomainName: 'd123456789.cloudfront.net',
        rumApplicationName: 'test-app-dev',
        customDomainName: 'test.minecraft.lockhead.cloud',
        environment: 'dev',
      });

      const template = Template.fromStack(stack);

      // Check for budget notifications
      template.hasResourceProperties('AWS::Budgets::Budget', {
        NotificationsWithSubscribers: [
          {
            Notification: {
              NotificationType: 'ACTUAL',
              ComparisonOperator: 'GREATER_THAN',
              Threshold: 80,
              ThresholdType: 'PERCENTAGE',
            },
            Subscribers: Match.arrayWith([
              {
                SubscriptionType: 'SNS',
                Address: Match.anyValue(),
              },
            ]),
          },
          {
            Notification: {
              NotificationType: 'FORECASTED',
              ComparisonOperator: 'GREATER_THAN',
              Threshold: 100,
              ThresholdType: 'PERCENTAGE',
            },
            Subscribers: Match.arrayWith([
              {
                SubscriptionType: 'SNS',
                Address: Match.anyValue(),
              },
            ]),
          },
        ],
      });
    });
  });

  describe('configuration methods', () => {
    it('should return monitoring configuration', () => {
      const construct = new MonitoringDashboardConstruct(stack, 'TestMonitoring', {
        config: mockConfig,
        s3Bucket: mockS3Bucket,
        distributionId: 'E123456789',
        distributionDomainName: 'd123456789.cloudfront.net',
        rumApplicationName: 'test-app-dev',
        customDomainName: 'test.minecraft.lockhead.cloud',
        environment: 'dev',
      });

      const monitoringConfig = construct.getMonitoringConfig();

      expect(monitoringConfig).toHaveProperty('dashboards');
      expect(monitoringConfig).toHaveProperty('alarms');
      expect(monitoringConfig).toHaveProperty('topics');
      expect(monitoringConfig).toHaveProperty('canary');
      expect(monitoringConfig).toHaveProperty('budget');

      // CDK tokens are used during synthesis, so we check for string type instead of exact values
      expect(typeof monitoringConfig.dashboards.application).toBe('string');
      expect(typeof monitoringConfig.dashboards.performance).toBe('string');
      expect(typeof monitoringConfig.dashboards.cost).toBe('string');
    });

    it('should return dashboard URLs', () => {
      const construct = new MonitoringDashboardConstruct(stack, 'TestMonitoring', {
        config: mockConfig,
        s3Bucket: mockS3Bucket,
        distributionId: 'E123456789',
        distributionDomainName: 'd123456789.cloudfront.net',
        rumApplicationName: 'test-app-dev',
        customDomainName: 'test.minecraft.lockhead.cloud',
        environment: 'dev',
      });

      const dashboardUrls = construct.getDashboardUrls();

      expect(dashboardUrls).toHaveProperty('application');
      expect(dashboardUrls).toHaveProperty('performance');
      expect(dashboardUrls).toHaveProperty('cost');

      expect(dashboardUrls.application).toContain('console.aws.amazon.com/cloudwatch');
      // CDK tokens are used during synthesis, so we check for URL structure instead of exact names
      expect(typeof dashboardUrls.application).toBe('string');
    });

    it('should return notification topics', () => {
      const construct = new MonitoringDashboardConstruct(stack, 'TestMonitoring', {
        config: mockConfig,
        s3Bucket: mockS3Bucket,
        distributionId: 'E123456789',
        distributionDomainName: 'd123456789.cloudfront.net',
        rumApplicationName: 'test-app-dev',
        customDomainName: 'test.minecraft.lockhead.cloud',
        environment: 'dev',
      });

      const topics = construct.getNotificationTopics();

      expect(topics).toHaveProperty('criticalAlerts');
      expect(topics).toHaveProperty('warningAlerts');
      expect(topics).toHaveProperty('costAlerts');

      // CDK tokens are used during synthesis, so we check for string type instead of exact ARN format
      expect(typeof topics.criticalAlerts).toBe('string');
      expect(typeof topics.warningAlerts).toBe('string');
      expect(typeof topics.costAlerts).toBe('string');
    });
  });

  describe('error handling', () => {
    it('should handle missing budget threshold gracefully', () => {
      const configWithoutBudget = {
        ...mockConfig,
        costAllocation: {
          ...mockConfig.costAllocation,
          budgetThreshold: undefined,
        },
      };

      expect(() => {
        new MonitoringDashboardConstruct(stack, 'TestMonitoring', {
          config: configWithoutBudget,
          s3Bucket: mockS3Bucket,
          distributionId: 'E123456789',
          distributionDomainName: 'd123456789.cloudfront.net',
          rumApplicationName: 'test-app-dev',
          customDomainName: 'test.minecraft.lockhead.cloud',
          environment: 'dev',
        });
      }).not.toThrow();
    });

    it('should handle missing alert email gracefully', () => {
      const configWithoutEmail = {
        ...mockConfig,
        costAllocation: {
          ...mockConfig.costAllocation,
          customCostTags: {},
        },
      };

      expect(() => {
        new MonitoringDashboardConstruct(stack, 'TestMonitoring', {
          config: configWithoutEmail,
          s3Bucket: mockS3Bucket,
          distributionId: 'E123456789',
          distributionDomainName: 'd123456789.cloudfront.net',
          rumApplicationName: 'test-app-dev',
          customDomainName: 'test.minecraft.lockhead.cloud',
          environment: 'dev',
        });
      }).not.toThrow();
    });
  });
});