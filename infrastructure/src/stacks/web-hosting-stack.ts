import { Construct } from 'constructs';
import * as cdk from 'aws-cdk-lib';
import { Stack, StackProps, CfnOutput } from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as iam from 'aws-cdk-lib/aws-iam';
import { DeploymentConfig } from '../types/config';
import { S3BucketConstruct } from '../constructs/s3-bucket';
import { CloudFrontDistributionConstruct } from '../constructs/cloudfront-distribution';
import { AcmCertificateConstruct } from '../constructs/acm-certificate';
import { CloudWatchRumConstruct } from '../constructs/cloudwatch-rum';
import { DnsManagementConstruct } from '../constructs/dns-management';
import { MonitoringDashboardConstruct } from '../constructs/monitoring-dashboard';
import { ErrorHandler, ErrorSeverity, ErrorCategory } from '../utils/error-handler';
import { DeploymentValidator } from '../utils/deployment-validator';

/**
 * Properties for the WebHostingStack
 */
export interface WebHostingStackProps extends StackProps {
  /** Deployment configuration */
  config: DeploymentConfig;
}

/**
 * Main CDK stack for Flutter web application hosting on AWS
 * 
 * This stack integrates all the necessary constructs to create a complete
 * web hosting solution including:
 * - S3 bucket for static website hosting
 * - CloudFront distribution with custom domain and SSL
 * - ACM certificate with cross-account DNS validation
 * - CloudWatch RUM for real user monitoring
 * - Cross-account DNS management for custom domain
 * 
 * The stack ensures proper resource dependencies and ordering, and provides
 * comprehensive outputs for integration with CI/CD pipelines.
 */
export class WebHostingStack extends Stack {
  /** S3 bucket construct for static website hosting */
  public readonly s3Bucket: S3BucketConstruct;
  
  /** CloudFront distribution construct */
  public readonly cloudFrontDistribution: CloudFrontDistributionConstruct;
  
  /** ACM certificate construct */
  public readonly certificate: AcmCertificateConstruct;
  
  /** CloudWatch RUM construct */
  public readonly rumMonitoring: CloudWatchRumConstruct;
  
  /** DNS management construct */
  public readonly dnsManagement: DnsManagementConstruct;
  
  /** Monitoring and alerting construct */
  public readonly monitoring: MonitoringDashboardConstruct;
  
  /** Deployment configuration */
  private readonly config: DeploymentConfig;

  /** Error handler for stack operations */
  private readonly errorHandler: ErrorHandler;

  /** Deployment validator */
  private readonly validator: DeploymentValidator;

  constructor(scope: Construct, id: string, props: WebHostingStackProps) {
    super(scope, id, props);

    try {
      this.config = props.config;

      // Initialize error handler and validator
      this.errorHandler = new ErrorHandler(this, 'WebHostingStack', {
        environment: this.config.environment,
        stackName: id
      });

      this.validator = new DeploymentValidator(this, this.config);

      // Validate stack configuration with comprehensive error handling
      this.validateStackConfiguration();

      // Apply stack-level tags
      this.applyStackTags();

      // Create resources in proper dependency order with error handling
      this.createResources();

      // Create stack outputs
      this.createStackOutputs();

      if (process.env.NODE_ENV !== 'test') {
      console.log(`✅ Web hosting stack created successfully: ${this.stackName}`);
    }

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      if (process.env.NODE_ENV !== 'test') {
        console.error(`❌ Failed to create web hosting stack: ${errorMessage}`);
      }
      
      if (error instanceof Error && error.stack) {
        if (process.env.NODE_ENV !== 'test') {
          console.error('Stack trace:', error.stack);
        }
      }
      
      throw error; // Re-throw to fail the deployment
    }
  }

  /**
   * Validates the stack configuration before creating resources with comprehensive error handling
   */
  private validateStackConfiguration(): void {
    try {
      const { config } = this;
      
      // Validate required configuration
      this.errorHandler.validateRequired(config, 'config');
      this.errorHandler.validateRequired(config.environment, 'environment');
      this.errorHandler.validateRequired(config.domainConfig, 'domainConfig');
      this.errorHandler.validateRequired(config.monitoringConfig, 'monitoringConfig');
      this.errorHandler.validateRequired(config.cachingConfig, 'cachingConfig');
      this.errorHandler.validateRequired(config.s3Config, 's3Config');

      // Validate environment-specific requirements
      if (config.environment === 'prod') {
        if (config.monitoringConfig.samplingRate > 0.5) {
          console.warn('⚠️  High RUM sampling rate in production may increase costs');
        }

        // Production-specific validations
        this.errorHandler.validate(
          config.s3Config.versioning,
          'PROD_S3_VERSIONING_REQUIRED',
          'S3 versioning must be enabled in production',
          ErrorCategory.CONFIGURATION,
          { environment: config.environment },
          'Enable S3 versioning for production deployments'
        );

        // Check for required production tags
        const requiredProdTags = ['CostCenter', 'ProjectCode', 'Department', 'Owner'];
        requiredProdTags.forEach(tag => {
          this.errorHandler.validate(
            !!(config.tags[tag] && typeof config.tags[tag] === 'string' && (config.tags[tag] as string).trim() !== ''),
            'MISSING_PROD_TAG',
            `Missing required production tag: ${tag}`,
            ErrorCategory.VALIDATION,
            { tag, environment: config.environment },
            `Add the required tag '${tag}' to the configuration`
          );
        });
      }

      // Validate region for certificate creation
      const currentRegion = this.region;
      const requiredRegion = config.domainConfig.certificateRegion;
      
      this.errorHandler.validate(
        currentRegion === requiredRegion,
        'INVALID_CERTIFICATE_REGION',
        `Stack must be deployed to ${requiredRegion} region for CloudFront certificate. Current region: ${currentRegion}`,
        ErrorCategory.CONFIGURATION,
        { currentRegion, requiredRegion },
        `Deploy the stack to ${requiredRegion} region or update the certificate region configuration`
      );

      // Validate domain configuration
      this.errorHandler.validateDomainName(config.domainConfig.domainName, {
        configSection: 'domainConfig'
      });

      // Validate ARN format
      this.errorHandler.validateArn(
        config.domainConfig.crossAccountRoleArn,
        'Cross-account role',
        { configSection: 'domainConfig' }
      );

      // Validate region format and allowed regions
      this.errorHandler.validateRegion(
        currentRegion,
        config.environmentConfig.allowedRegions,
        { currentRegion, environment: config.environment }
      );

      // Validate environment limits
      this.validateEnvironmentLimits();

      if (process.env.NODE_ENV !== 'test') {
        console.log('✅ Stack configuration validation passed');
      }

    } catch (error) {
      this.errorHandler.handleError(
        'STACK_CONFIGURATION_VALIDATION_FAILED',
        `Stack configuration validation failed: ${(error as Error).message}`,
        ErrorSeverity.CRITICAL,
        ErrorCategory.VALIDATION,
        { stackName: this.stackName, config: this.config },
        'Fix the configuration errors and redeploy'
      );
    }
  }

  /**
   * Validates environment-specific limits
   */
  private validateEnvironmentLimits(): void {
    const { config } = this;
    const limits = config.environmentConfig.limits;

    // Validate cache TTL limits
    this.errorHandler.validate(
      config.cachingConfig.maxTtl <= limits.maxCacheTtl,
      'CACHE_TTL_LIMIT_EXCEEDED',
      `Max TTL ${config.cachingConfig.maxTtl} exceeds environment limit ${limits.maxCacheTtl}`,
      ErrorCategory.VALIDATION,
      { maxTtl: config.cachingConfig.maxTtl, limit: limits.maxCacheTtl },
      `Reduce max TTL to ${limits.maxCacheTtl} or below`
    );

    // Validate RUM sampling rate limits
    this.errorHandler.validate(
      config.monitoringConfig.samplingRate <= limits.maxRumSamplingRate,
      'RUM_SAMPLING_RATE_LIMIT_EXCEEDED',
      `RUM sampling rate ${config.monitoringConfig.samplingRate} exceeds environment limit ${limits.maxRumSamplingRate}`,
      ErrorCategory.VALIDATION,
      { samplingRate: config.monitoringConfig.samplingRate, limit: limits.maxRumSamplingRate },
      `Reduce RUM sampling rate to ${limits.maxRumSamplingRate} or below`
    );

    // Validate S3 lifecycle limits
    config.s3Config.lifecycleRules.forEach((rule, index) => {
      if (rule.expirationDays && rule.expirationDays > limits.maxS3LifecycleDays) {
        this.errorHandler.validate(
          false,
          'S3_LIFECYCLE_LIMIT_EXCEEDED',
          `S3 lifecycle rule ${index + 1} expiration ${rule.expirationDays} exceeds environment limit ${limits.maxS3LifecycleDays}`,
          ErrorCategory.VALIDATION,
          { ruleIndex: index + 1, expirationDays: rule.expirationDays, limit: limits.maxS3LifecycleDays },
          `Reduce S3 lifecycle expiration to ${limits.maxS3LifecycleDays} days or below`
        );
      }
    });
  }

  /**
   * Applies stack-level tags to all resources
   */
  private applyStackTags(): void {
    const { config } = this;
    
    // Apply configuration tags (includes cost allocation tags)
    Object.entries(config.tags).forEach(([key, value]) => {
      cdk.Tags.of(this).add(key, value);
    });

    // Add stack-specific tags
    cdk.Tags.of(this).add('StackName', this.stackName);
    cdk.Tags.of(this).add('StackId', this.stackId);
    cdk.Tags.of(this).add('Component', 'WebHostingInfrastructure');
    cdk.Tags.of(this).add('Purpose', 'FlutterWebHosting');
    cdk.Tags.of(this).add('CreatedBy', 'CDK');
    cdk.Tags.of(this).add('LastModified', new Date().toISOString());
    
    // Add environment-specific tags
    cdk.Tags.of(this).add('IsProduction', config.environmentConfig.isProduction.toString());
    cdk.Tags.of(this).add('EnvironmentTier', config.environmentConfig.isProduction ? 'Production' : 'NonProduction');
    
    // Add cost allocation tags
    cdk.Tags.of(this).add('CostCenter', config.costAllocation.costCenter);
    cdk.Tags.of(this).add('ProjectCode', config.costAllocation.projectCode);
    cdk.Tags.of(this).add('Department', config.costAllocation.department);
    
    if (config.costAllocation.budgetThreshold) {
      cdk.Tags.of(this).add('BudgetThreshold', config.costAllocation.budgetThreshold.toString());
    }
    
    // Add feature flags as tags for visibility
    Object.entries(config.environmentConfig.featureFlags).forEach(([flag, enabled]) => {
      cdk.Tags.of(this).add(`Feature-${flag}`, enabled.toString());
    });
  }

  /**
   * Creates all stack resources in proper dependency order with comprehensive error handling
   */
  private createResources(): void {
    try {
      if (process.env.NODE_ENV !== 'test') {
        console.log('🏗️  Creating stack resources...');
      }

      // 1. Create S3 bucket first (no dependencies)
      if (process.env.NODE_ENV !== 'test') {
        console.log('📦 Creating S3 bucket...');
      }
      Object.defineProperty(this, 's3Bucket', {
        value: this.createS3Bucket(),
        writable: false,
        enumerable: true,
        configurable: false
      });

      // 2. Create ACM certificate (independent of other resources)
      if (process.env.NODE_ENV !== 'test') {
        console.log('🔒 Creating ACM certificate...');
      }
      Object.defineProperty(this, 'certificate', {
        value: this.createAcmCertificate(),
        writable: false,
        enumerable: true,
        configurable: false
      });

      // 3. Create CloudFront distribution (depends on S3 bucket and certificate)
      if (process.env.NODE_ENV !== 'test') {
        console.log('🌐 Creating CloudFront distribution...');
      }
      Object.defineProperty(this, 'cloudFrontDistribution', {
        value: this.createCloudFrontDistribution(),
        writable: false,
        enumerable: true,
        configurable: false
      });

      // 4. Create CloudWatch RUM (depends on domain configuration)
      if (process.env.NODE_ENV !== 'test') {
        console.log('📊 Creating CloudWatch RUM monitoring...');
      }
      Object.defineProperty(this, 'rumMonitoring', {
        value: this.createCloudWatchRum(),
        writable: false,
        enumerable: true,
        configurable: false
      });

      // 5. Create DNS management (depends on CloudFront distribution)
      if (process.env.NODE_ENV !== 'test') {
        console.log('🌍 Creating DNS management...');
      }
      Object.defineProperty(this, 'dnsManagement', {
        value: this.createDnsManagement(),
        writable: false,
        enumerable: true,
        configurable: false
      });

      // 6. Create monitoring and alerting (depends on all other resources)
      if (process.env.NODE_ENV !== 'test') {
        console.log('📊 Creating monitoring and alerting...');
      }
      Object.defineProperty(this, 'monitoring', {
        value: this.createMonitoring(),
        writable: false,
        enumerable: true,
        configurable: false
      });

      // Set up resource dependencies explicitly
      this.setupResourceDependencies();

      if (process.env.NODE_ENV !== 'test') {
        console.log('✅ All stack resources created successfully');
      }

    } catch (error) {
      this.errorHandler.handleError(
        'STACK_RESOURCE_CREATION_FAILED',
        `Failed to create stack resources: ${(error as Error).message}`,
        ErrorSeverity.CRITICAL,
        ErrorCategory.RESOURCE_CREATION,
        { stackName: this.stackName },
        'Check AWS permissions and service limits'
      );
    }
  }

  /**
   * Creates the S3 bucket construct
   */
  private createS3Bucket(): S3BucketConstruct {
    return new S3BucketConstruct(this, 'S3Bucket', {
      config: this.config.s3Config,
      environment: this.config.environment,
      tags: this.config.tags,
    });
  }

  /**
   * Creates the ACM certificate construct
   */
  private createAcmCertificate(): AcmCertificateConstruct {
    return new AcmCertificateConstruct(this, 'Certificate', {
      domainConfig: this.config.domainConfig,
      environment: this.config.environment,
      tags: this.config.tags,
    });
  }

  /**
   * Creates the CloudFront distribution construct
   */
  private createCloudFrontDistribution(): CloudFrontDistributionConstruct {
    return new CloudFrontDistributionConstruct(this, 'CloudFrontDistribution', {
      s3Bucket: this.s3Bucket.bucket,
      cachingConfig: this.config.cachingConfig,
      domainNames: [this.config.domainConfig.domainName],
      certificateArn: this.certificate.certificateArn,
      environment: this.config.environment,
      tags: this.config.tags,
    });
  }

  /**
   * Creates the CloudWatch RUM construct
   */
  private createCloudWatchRum(): CloudWatchRumConstruct {
    return new CloudWatchRumConstruct(this, 'RumMonitoring', {
      config: this.config.monitoringConfig,
      environment: this.config.environment,
      domainName: this.config.domainConfig.domainName,
      tags: this.config.tags,
    });
  }

  /**
   * Creates the DNS management construct
   */
  private createDnsManagement(): DnsManagementConstruct {
    return new DnsManagementConstruct(this, 'DnsManagement', {
      domainConfig: this.config.domainConfig,
      cloudFrontDomainName: this.cloudFrontDistribution.distributionDomainName,
      environment: this.config.environment,
      tags: this.config.tags,
    });
  }

  /**
   * Creates the monitoring and alerting construct
   */
  private createMonitoring(): MonitoringDashboardConstruct {
    return new MonitoringDashboardConstruct(this, 'Monitoring', {
      config: this.config,
      s3Bucket: this.s3Bucket.bucket,
      distributionId: this.cloudFrontDistribution.distributionId,
      distributionDomainName: this.cloudFrontDistribution.distributionDomainName,
      rumApplicationName: this.rumMonitoring.rumAppName,
      customDomainName: this.config.domainConfig.domainName,
      environment: this.config.environment,
      tags: this.config.tags,
    });
  }

  /**
   * Sets up explicit resource dependencies
   */
  private setupResourceDependencies(): void {
    // CloudFront distribution depends on S3 bucket and certificate
    this.cloudFrontDistribution.node.addDependency(this.s3Bucket);
    this.cloudFrontDistribution.node.addDependency(this.certificate);

    // DNS management depends on CloudFront distribution
    this.dnsManagement.node.addDependency(this.cloudFrontDistribution);

    // RUM monitoring can be created independently but should be after domain setup
    this.rumMonitoring.node.addDependency(this.certificate);

    // Monitoring depends on all other resources
    this.monitoring.node.addDependency(this.s3Bucket);
    this.monitoring.node.addDependency(this.cloudFrontDistribution);
    this.monitoring.node.addDependency(this.rumMonitoring);
    this.monitoring.node.addDependency(this.dnsManagement);

    // Note: CloudFront access policy is handled by Origin Access Control (OAC)
    // Additional bucket policies can be added post-deployment if needed
  }



  /**
   * Creates stack outputs for integration with CI/CD and other systems
   */
  private createStackOutputs(): void {
    // S3 bucket outputs
    new CfnOutput(this, 'S3BucketName', {
      value: this.s3Bucket.bucketName,
      description: 'Name of the S3 bucket for static website hosting',
      exportName: `${this.stackName}-S3BucketName`,
    });

    new CfnOutput(this, 'S3BucketArn', {
      value: this.s3Bucket.bucket.bucketArn,
      description: 'ARN of the S3 bucket',
      exportName: `${this.stackName}-S3BucketArn`,
    });

    // CloudFront distribution outputs
    new CfnOutput(this, 'CloudFrontDistributionId', {
      value: this.cloudFrontDistribution.distributionId,
      description: 'CloudFront distribution ID for cache invalidation',
      exportName: `${this.stackName}-CloudFrontDistributionId`,
    });

    new CfnOutput(this, 'CloudFrontDistributionDomainName', {
      value: this.cloudFrontDistribution.distributionDomainName,
      description: 'CloudFront distribution domain name',
      exportName: `${this.stackName}-CloudFrontDomainName`,
    });

    new CfnOutput(this, 'CloudFrontDistributionUrl', {
      value: this.cloudFrontDistribution.distributionUrl,
      description: 'CloudFront distribution URL',
      exportName: `${this.stackName}-CloudFrontUrl`,
    });

    // Custom domain outputs
    new CfnOutput(this, 'CustomDomainName', {
      value: this.config.domainConfig.domainName,
      description: 'Custom domain name for the application',
      exportName: `${this.stackName}-CustomDomainName`,
    });

    new CfnOutput(this, 'CustomDomainUrl', {
      value: `https://${this.config.domainConfig.domainName}`,
      description: 'Custom domain URL for the application',
      exportName: `${this.stackName}-CustomDomainUrl`,
    });

    // Certificate outputs
    new CfnOutput(this, 'CertificateArn', {
      value: this.certificate.certificateArn,
      description: 'ARN of the ACM certificate',
      exportName: `${this.stackName}-CertificateArn`,
    });

    // RUM monitoring outputs
    new CfnOutput(this, 'RumApplicationName', {
      value: this.rumMonitoring.rumAppName,
      description: 'CloudWatch RUM application name',
      exportName: `${this.stackName}-RumAppName`,
    });

    new CfnOutput(this, 'RumApplicationId', {
      value: this.rumMonitoring.rumAppId,
      description: 'CloudWatch RUM application ID',
      exportName: `${this.stackName}-RumAppId`,
    });

    // Environment and configuration outputs
    new CfnOutput(this, 'Environment', {
      value: this.config.environment,
      description: 'Deployment environment',
      exportName: `${this.stackName}-Environment`,
    });

    new CfnOutput(this, 'Region', {
      value: this.region,
      description: 'AWS region where the stack is deployed',
      exportName: `${this.stackName}-Region`,
    });

    // Monitoring outputs
    new CfnOutput(this, 'ApplicationDashboardUrl', {
      value: this.monitoring.getDashboardUrls().application,
      description: 'URL to the application monitoring dashboard',
      exportName: `${this.stackName}-ApplicationDashboard`,
    });

    new CfnOutput(this, 'PerformanceDashboardUrl', {
      value: this.monitoring.getDashboardUrls().performance,
      description: 'URL to the performance monitoring dashboard',
      exportName: `${this.stackName}-PerformanceDashboard`,
    });

    new CfnOutput(this, 'CostDashboardUrl', {
      value: this.monitoring.getDashboardUrls().cost,
      description: 'URL to the cost monitoring dashboard',
      exportName: `${this.stackName}-CostDashboard`,
    });

    new CfnOutput(this, 'CriticalAlertsTopicArn', {
      value: this.monitoring.getNotificationTopics().criticalAlerts,
      description: 'SNS topic ARN for critical alerts',
      exportName: `${this.stackName}-CriticalAlertsTopic`,
    });

    new CfnOutput(this, 'UptimeCanaryName', {
      value: this.monitoring.getMonitoringConfig().canary.name,
      description: 'Name of the uptime monitoring canary',
      exportName: `${this.stackName}-UptimeCanary`,
    });

    // Deployment information outputs
    new CfnOutput(this, 'DeploymentTimestamp', {
      value: new Date().toISOString(),
      description: 'Timestamp when the stack was deployed',
    });

    new CfnOutput(this, 'StackVersion', {
      value: '1.0.0',
      description: 'Version of the web hosting stack',
    });
  }

  /**
   * Gets the S3 bucket name for external access
   */
  public getBucketName(): string {
    return this.s3Bucket.bucketName;
  }

  /**
   * Gets the CloudFront distribution ID for cache invalidation
   */
  public getDistributionId(): string {
    return this.cloudFrontDistribution.distributionId;
  }

  /**
   * Gets the custom domain URL
   */
  public getCustomDomainUrl(): string {
    return `https://${this.config.domainConfig.domainName}`;
  }

  /**
   * Gets the CloudFront distribution URL
   */
  public getDistributionUrl(): string {
    return this.cloudFrontDistribution.distributionUrl;
  }

  /**
   * Gets the RUM client configuration for Flutter web integration
   */
  public getRumClientConfig() {
    return this.rumMonitoring.getRumClientConfig();
  }

  /**
   * Gets the RUM initialization script for embedding in the web app
   */
  public getRumInitializationScript(): string {
    return this.rumMonitoring.getRumInitializationScript();
  }

  /**
   * Gets monitoring configuration
   */
  public getMonitoringConfig() {
    return this.monitoring.getMonitoringConfig();
  }

  /**
   * Gets dashboard URLs
   */
  public getDashboardUrls() {
    return this.monitoring.getDashboardUrls();
  }

  /**
   * Gets notification topic ARNs
   */
  public getNotificationTopics() {
    return this.monitoring.getNotificationTopics();
  }

  /**
   * Gets deployment information for CI/CD integration
   */
  public getDeploymentInfo() {
    return {
      environment: this.config.environment,
      region: this.region,
      stackName: this.stackName,
      bucketName: this.getBucketName(),
      distributionId: this.getDistributionId(),
      customDomainUrl: this.getCustomDomainUrl(),
      distributionUrl: this.getDistributionUrl(),
      rumConfig: this.getRumClientConfig(),
      monitoring: this.getMonitoringConfig(),
      dashboards: this.getDashboardUrls(),
      notifications: this.getNotificationTopics(),
    };
  }
}