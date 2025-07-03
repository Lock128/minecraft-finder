import { Construct } from 'constructs';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as iam from 'aws-cdk-lib/aws-iam';
import { RemovalPolicy, Duration } from 'aws-cdk-lib';
import { S3BucketConfig } from '../types/config';

/**
 * Properties for the S3 bucket construct
 */
export interface S3BucketConstructProps {
  /** S3 bucket configuration */
  config: S3BucketConfig;
  /** Environment name for resource naming */
  environment: string;
  /** Additional tags to apply to resources */
  tags?: Record<string, string>;
}

/**
 * S3 bucket construct for static website hosting
 * 
 * This construct creates an S3 bucket configured for static website hosting
 * with proper security policies, versioning, and lifecycle management.
 * The bucket is configured to block public access and only allow access
 * through CloudFront using Origin Access Control (OAC).
 */
export class S3BucketConstruct extends Construct {
  /** The S3 bucket instance */
  public readonly bucket: s3.Bucket;
  
  /** The bucket name */
  public readonly bucketName: string;

  constructor(scope: Construct, id: string, props: S3BucketConstructProps) {
    super(scope, id);

    const { config, environment, tags = {} } = props;

    // Generate unique bucket name
    this.bucketName = `${config.bucketNamePrefix}-${Date.now()}`;

    // Create lifecycle rules
    const lifecycleRules = this.createLifecycleRules(config.lifecycleRules);

    // Create the S3 bucket
    this.bucket = new s3.Bucket(this, 'WebsiteBucket', {
      bucketName: this.bucketName,
      
      // Static website hosting configuration
      websiteIndexDocument: 'index.html',
      websiteErrorDocument: 'index.html', // SPA routing - redirect 404s to index.html
      
      // Security configuration - block all public access
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      publicReadAccess: false,
      
      // Versioning for rollback capability
      versioned: config.versioning,
      
      // Lifecycle rules for cost optimization
      lifecycleRules,
      
      // CORS configuration for web assets
      cors: this.createCorsRules(),
      
      // Encryption configuration
      encryption: s3.BucketEncryption.S3_MANAGED,
      
      // Removal policy - retain in production, destroy in dev
      removalPolicy: environment === 'prod' ? RemovalPolicy.RETAIN : RemovalPolicy.DESTROY,
      
      // Auto delete objects when stack is destroyed (only for non-prod)
      // Note: Disabled to avoid circular dependencies with CloudFront
      autoDeleteObjects: false,
    });

    // Apply tags
    Object.entries(tags).forEach(([key, value]) => {
      this.bucket.node.addMetadata(key, value);
    });

    // Add additional bucket-specific tags
    this.bucket.node.addMetadata('Component', 'StaticWebsiteHosting');
    this.bucket.node.addMetadata('Purpose', 'FlutterWebAssets');
  }

  /**
   * Creates lifecycle rules for the S3 bucket based on configuration
   */
  private createLifecycleRules(rules: S3BucketConfig['lifecycleRules']): s3.LifecycleRule[] {
    return rules.map(rule => ({
      id: rule.id,
      enabled: rule.enabled,
      
      // Transition to Infrequent Access storage class
      transitions: rule.transitionToIADays ? [{
        storageClass: s3.StorageClass.INFREQUENT_ACCESS,
        transitionAfter: Duration.days(rule.transitionToIADays),
      }] : undefined,
      
      // Expiration for current versions
      expiration: rule.expirationDays ? Duration.days(rule.expirationDays) : undefined,
      
      // Clean up incomplete multipart uploads
      abortIncompleteMultipartUploadAfter: rule.abortIncompleteMultipartUploadDays 
        ? Duration.days(rule.abortIncompleteMultipartUploadDays) 
        : undefined,
      
      // Apply to all objects
      prefix: '',
    }));
  }

  /**
   * Creates CORS rules for web assets
   */
  private createCorsRules(): s3.CorsRule[] {
    return [
      {
        // Allow all origins for development flexibility
        // In production, this should be restricted to specific domains
        allowedOrigins: ['*'],
        
        // Allow common HTTP methods for web assets
        allowedMethods: [
          s3.HttpMethods.GET,
          s3.HttpMethods.HEAD,
        ],
        
        // Allow common headers
        allowedHeaders: [
          'Authorization',
          'Content-Length',
          'Content-Type',
          'Date',
          'ETag',
          'X-Amz-Date',
          'X-Amz-Security-Token',
          'X-Amz-User-Agent',
        ],
        
        // Expose headers that might be needed by the web app
        exposedHeaders: [
          'ETag',
          'Content-Length',
          'Content-Type',
        ],
        
        // Cache preflight requests for 1 hour
        maxAge: 3600,
      },
    ];
  }

  /**
   * Grants read access to the bucket for CloudFront Origin Access Control
   * This method should be called after the CloudFront distribution is created
   */
  public grantReadToCloudFront(cloudFrontOriginAccessIdentity: iam.IPrincipal): void {
    this.bucket.grantRead(cloudFrontOriginAccessIdentity);
  }

  /**
   * Creates a bucket policy statement for CloudFront Origin Access Control
   * This is the modern replacement for Origin Access Identity (OAI)
   */
  public createCloudFrontAccessPolicy(cloudFrontServicePrincipal: iam.ServicePrincipal): iam.PolicyStatement {
    return new iam.PolicyStatement({
      sid: 'AllowCloudFrontServicePrincipal',
      effect: iam.Effect.ALLOW,
      principals: [cloudFrontServicePrincipal],
      actions: ['s3:GetObject'],
      resources: [`${this.bucket.bucketArn}/*`],
      conditions: {
        StringEquals: {
          'AWS:SourceAccount': this.node.tryGetContext('account') || process.env.CDK_DEFAULT_ACCOUNT,
        },
      },
    });
  }

  /**
   * Gets the bucket website URL (for reference, not used with CloudFront)
   */
  public get websiteUrl(): string {
    return this.bucket.bucketWebsiteUrl;
  }

  /**
   * Gets the bucket domain name for CloudFront origin configuration
   */
  public get bucketDomainName(): string {
    return this.bucket.bucketDomainName;
  }

  /**
   * Gets the bucket regional domain name for CloudFront origin configuration
   */
  public get bucketRegionalDomainName(): string {
    return this.bucket.bucketRegionalDomainName;
  }
}