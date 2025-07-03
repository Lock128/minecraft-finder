import { Construct } from 'constructs';
import * as cdk from 'aws-cdk-lib';
import { Stack, StackProps, CfnOutput } from 'aws-cdk-lib';
import { DeploymentConfig } from '../types/config';
import { S3BucketConstruct } from '../constructs/s3-bucket';
import { CloudFrontDistributionConstruct } from '../constructs/cloudfront-distribution';
import { AcmCertificateConstruct } from '../constructs/acm-certificate';
import { CloudWatchRumConstruct } from '../constructs/cloudwatch-rum';
import { DnsManagementConstruct } from '../constructs/dns-management';

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
  
  /** Deployment configuration */
  private readonly config: DeploymentConfig;

  constructor(scope: Construct, id: string, props: WebHostingStackProps) {
    super(scope, id, props);

    this.config = props.config;

    // Validate stack configuration
    this.validateStackConfiguration();

    // Apply stack-level tags
    this.applyStackTags();

    // Create resources in proper dependency order
    this.createResources();

    // Create stack outputs
    this.createStackOutputs();
  }

  /**
   * Validates the stack configuration before creating resources
   */
  private validateStackConfiguration(): void {
    const { config } = this;
    
    // Validate environment-specific requirements
    if (config.environment === 'prod') {
      if (config.monitoringConfig.samplingRate > 0.5) {
        console.warn('High RUM sampling rate in production may increase costs');
      }
    }

    // Validate region for certificate creation
    if (this.region && this.region !== config.domainConfig.certificateRegion) {
      throw new Error(
        `Stack must be deployed to ${config.domainConfig.certificateRegion} region for CloudFront certificate. ` +
        `Current region: ${this.region}`
      );
    }

    // Validate domain configuration
    if (!config.domainConfig.domainName.includes('.')) {
      throw new Error('Invalid domain name format');
    }
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
   * Creates all stack resources in proper dependency order
   */
  private createResources(): void {
    // 1. Create S3 bucket first (no dependencies)
    Object.defineProperty(this, 's3Bucket', {
      value: this.createS3Bucket(),
      writable: false,
      enumerable: true,
      configurable: false
    });

    // 2. Create ACM certificate (independent of other resources)
    Object.defineProperty(this, 'certificate', {
      value: this.createAcmCertificate(),
      writable: false,
      enumerable: true,
      configurable: false
    });

    // 3. Create CloudFront distribution (depends on S3 bucket and certificate)
    Object.defineProperty(this, 'cloudFrontDistribution', {
      value: this.createCloudFrontDistribution(),
      writable: false,
      enumerable: true,
      configurable: false
    });

    // 4. Create CloudWatch RUM (depends on domain configuration)
    Object.defineProperty(this, 'rumMonitoring', {
      value: this.createCloudWatchRum(),
      writable: false,
      enumerable: true,
      configurable: false
    });

    // 5. Create DNS management (depends on CloudFront distribution)
    Object.defineProperty(this, 'dnsManagement', {
      value: this.createDnsManagement(),
      writable: false,
      enumerable: true,
      configurable: false
    });

    // Set up resource dependencies explicitly
    this.setupResourceDependencies();

    // Note: S3 CloudFront access is handled via Origin Access Control (OAC)
    // The bucket policy would be set up separately to avoid circular dependencies
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
    };
  }
}