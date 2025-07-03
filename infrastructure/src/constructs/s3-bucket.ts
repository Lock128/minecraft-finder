import { Construct } from 'constructs';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as iam from 'aws-cdk-lib/aws-iam';
import { RemovalPolicy, Duration } from 'aws-cdk-lib';
import { S3BucketConfig } from '../types/config';
import { CommonErrorHandlers, ErrorSeverity, ErrorCategory } from '../utils/error-handler';

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

  /** Error handler for S3 operations */
  private readonly errorHandler = CommonErrorHandlers.createS3ErrorHandler(this, {});

  constructor(scope: Construct, id: string, props: S3BucketConstructProps) {
    super(scope, id);

    try {
      const { config, environment, tags = {} } = props;

      // Validate input parameters
      this.validateConstructProps(props);

      // Generate unique bucket name with error handling
      this.bucketName = this.generateBucketName(config, environment);

      // Create lifecycle rules with validation
      const lifecycleRules = this.createLifecycleRules(config.lifecycleRules);

      // Create the S3 bucket with comprehensive error handling
      this.bucket = this.createS3Bucket(config, environment, lifecycleRules);

      // Apply tags with error handling
      this.applyTags(tags);

      console.log(`✅ S3 bucket created successfully: ${this.bucketName}`);

    } catch (error) {
      this.errorHandler.handleError(
        'S3_BUCKET_CREATION_FAILED',
        `Failed to create S3 bucket construct: ${(error as Error).message}`,
        ErrorSeverity.CRITICAL,
        ErrorCategory.RESOURCE_CREATION,
        { constructId: id, props },
        'Check S3 permissions and bucket naming requirements'
      );
    }
  }

  /**
   * Validates constructor properties
   */
  private validateConstructProps(props: S3BucketConstructProps): void {
    this.errorHandler.validateRequired(props.config, 'config');
    this.errorHandler.validateRequired(props.environment, 'environment');
    
    const { config } = props;
    
    this.errorHandler.validateRequired(config.bucketNamePrefix, 'bucketNamePrefix');
    this.errorHandler.validate(
      config.bucketNamePrefix.length >= 3 && config.bucketNamePrefix.length <= 50,
      'INVALID_BUCKET_PREFIX_LENGTH',
      'Bucket name prefix must be between 3 and 50 characters',
      ErrorCategory.VALIDATION,
      { bucketNamePrefix: config.bucketNamePrefix },
      'Use a bucket name prefix between 3 and 50 characters'
    );

    this.errorHandler.validate(
      /^[a-z0-9][a-z0-9-]*[a-z0-9]$/.test(config.bucketNamePrefix),
      'INVALID_BUCKET_PREFIX_FORMAT',
      'Bucket name prefix must contain only lowercase letters, numbers, and hyphens',
      ErrorCategory.VALIDATION,
      { bucketNamePrefix: config.bucketNamePrefix },
      'Use only lowercase letters, numbers, and hyphens in bucket name prefix'
    );

    this.errorHandler.validate(
      typeof config.versioning === 'boolean',
      'INVALID_VERSIONING_CONFIG',
      'Versioning configuration must be a boolean',
      ErrorCategory.VALIDATION,
      { versioning: config.versioning }
    );

    this.errorHandler.validate(
      Array.isArray(config.lifecycleRules),
      'INVALID_LIFECYCLE_RULES',
      'Lifecycle rules must be an array',
      ErrorCategory.VALIDATION,
      { lifecycleRules: config.lifecycleRules }
    );
  }

  /**
   * Generates a unique bucket name with validation
   */
  private generateBucketName(config: S3BucketConfig, environment: string): string {
    try {
      const timestamp = Date.now();
      const bucketName = `${config.bucketNamePrefix}-${environment}-${timestamp}`;
      
      // Validate bucket name length (S3 limit is 63 characters)
      this.errorHandler.validate(
        bucketName.length <= 63,
        'BUCKET_NAME_TOO_LONG',
        `Generated bucket name is too long: ${bucketName.length} characters (max 63)`,
        ErrorCategory.VALIDATION,
        { bucketName, length: bucketName.length },
        'Use a shorter bucket name prefix'
      );

      return bucketName;
    } catch (error) {
      this.errorHandler.handleError(
        'BUCKET_NAME_GENERATION_FAILED',
        `Failed to generate bucket name: ${(error as Error).message}`,
        ErrorSeverity.HIGH,
        ErrorCategory.CONFIGURATION,
        { config, environment }
      );
    }
  }

  /**
   * Creates the S3 bucket with comprehensive security hardening
   */
  private createS3Bucket(
    config: S3BucketConfig, 
    environment: string, 
    lifecycleRules: s3.LifecycleRule[]
  ): s3.Bucket {
    try {
      const bucket = new s3.Bucket(this, 'WebsiteBucket', {
        bucketName: this.bucketName,
        
        // Static website hosting configuration
        websiteIndexDocument: 'index.html',
        websiteErrorDocument: 'index.html', // SPA routing - redirect 404s to index.html
        
        // Security configuration - block all public access (CRITICAL)
        blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
        publicReadAccess: false,
        
        // Versioning for rollback capability and security
        versioned: config.versioning,
        
        // Lifecycle rules for cost optimization
        lifecycleRules,
        
        // CORS configuration for web assets (restrictive)
        cors: this.createSecureCorsRules(environment),
        
        // Enhanced encryption configuration
        encryption: this.getEncryptionConfiguration(environment),
        encryptionKey: environment === 'prod' ? this.createKMSKey() : undefined,
        
        // Bucket key for cost optimization with KMS
        bucketKeyEnabled: environment === 'prod',
        
        // Removal policy - retain in production, destroy in dev
        removalPolicy: environment === 'prod' ? RemovalPolicy.RETAIN : RemovalPolicy.DESTROY,
        
        // Auto delete objects when stack is destroyed (only for non-prod)
        autoDeleteObjects: false,
        
        // Transfer acceleration disabled for security (can be enabled if needed)
        transferAcceleration: false,
        
        // Event bridge notifications disabled by default
        eventBridgeEnabled: false,
        
        // Intelligent tiering for cost optimization
        intelligentTieringConfigurations: environment === 'prod' ? [{
          id: 'EntireBucket',
          status: s3.IntelligentTieringStatus.ENABLED,
        }] : undefined,
      });

      // Apply additional security configurations
      this.applyBucketSecurityPolicies(bucket, environment);
      
      return bucket;
    } catch (error) {
      this.errorHandler.handleError(
        'S3_BUCKET_RESOURCE_CREATION_FAILED',
        `Failed to create S3 bucket resource: ${(error as Error).message}`,
        ErrorSeverity.CRITICAL,
        ErrorCategory.RESOURCE_CREATION,
        { bucketName: this.bucketName, config, environment },
        'Check AWS permissions and S3 service limits'
      );
    }
  }

  /**
   * Gets encryption configuration based on environment
   */
  private getEncryptionConfiguration(environment: string): s3.BucketEncryption {
    // Use KMS encryption for production, S3 managed for dev/staging
    return environment === 'prod' 
      ? s3.BucketEncryption.KMS 
      : s3.BucketEncryption.S3_MANAGED;
  }

  /**
   * Creates a KMS key for S3 bucket encryption (production only)
   */
  private createKMSKey(): any {
    // Import KMS module dynamically to avoid circular dependencies
    const kms = require('aws-cdk-lib/aws-kms');
    
    return new kms.Key(this, 'BucketEncryptionKey', {
      description: `S3 bucket encryption key for ${this.bucketName}`,
      enableKeyRotation: true,
      keySpec: kms.KeySpec.SYMMETRIC_DEFAULT,
      keyUsage: kms.KeyUsage.ENCRYPT_DECRYPT,
      removalPolicy: RemovalPolicy.RETAIN,
    });
  }

  /**
   * Applies additional security policies to the bucket
   */
  private applyBucketSecurityPolicies(bucket: s3.Bucket, environment: string): void {
    try {
      // Deny insecure connections (enforce HTTPS)
      bucket.addToResourcePolicy(new iam.PolicyStatement({
        sid: 'DenyInsecureConnections',
        effect: iam.Effect.DENY,
        principals: [new iam.AnyPrincipal()],
        actions: ['s3:*'],
        resources: [
          bucket.bucketArn,
          `${bucket.bucketArn}/*`,
        ],
        conditions: {
          Bool: {
            'aws:SecureTransport': 'false',
          },
        },
      }));

      // Deny unencrypted object uploads
      bucket.addToResourcePolicy(new iam.PolicyStatement({
        sid: 'DenyUnencryptedObjectUploads',
        effect: iam.Effect.DENY,
        principals: [new iam.AnyPrincipal()],
        actions: ['s3:PutObject'],
        resources: [`${bucket.bucketArn}/*`],
        conditions: {
          StringNotEquals: {
            's3:x-amz-server-side-encryption': environment === 'prod' ? 'aws:kms' : 'AES256',
          },
        },
      }));

      // Deny public read ACL
      bucket.addToResourcePolicy(new iam.PolicyStatement({
        sid: 'DenyPublicReadACL',
        effect: iam.Effect.DENY,
        principals: [new iam.AnyPrincipal()],
        actions: [
          's3:PutObject',
          's3:PutObjectAcl',
        ],
        resources: [`${bucket.bucketArn}/*`],
        conditions: {
          StringEquals: {
            's3:x-amz-acl': [
              'public-read',
              'public-read-write',
              'authenticated-read',
            ],
          },
        },
      }));

      // Deny public write ACL
      bucket.addToResourcePolicy(new iam.PolicyStatement({
        sid: 'DenyPublicWriteACL',
        effect: iam.Effect.DENY,
        principals: [new iam.AnyPrincipal()],
        actions: [
          's3:PutBucketAcl',
        ],
        resources: [bucket.bucketArn],
        conditions: {
          StringEquals: {
            's3:x-amz-acl': [
              'public-read',
              'public-read-write',
              'authenticated-read',
            ],
          },
        },
      }));

      // Restrict to specific IP ranges in production (if configured)
      const allowedIpRanges = this.node.tryGetContext('allowedIpRanges');
      if (environment === 'prod' && allowedIpRanges && Array.isArray(allowedIpRanges)) {
        bucket.addToResourcePolicy(new iam.PolicyStatement({
          sid: 'RestrictToAllowedIPs',
          effect: iam.Effect.DENY,
          principals: [new iam.AnyPrincipal()],
          actions: ['s3:*'],
          resources: [
            bucket.bucketArn,
            `${bucket.bucketArn}/*`,
          ],
          conditions: {
            NotIpAddress: {
              'aws:SourceIp': allowedIpRanges,
            },
            StringNotEquals: {
              'aws:PrincipalServiceName': 'cloudfront.amazonaws.com',
            },
          },
        }));
      }

    } catch (error) {
      console.warn(`Warning: Failed to apply some security policies: ${(error as Error).message}`);
    }
  }

  /**
   * Applies tags with error handling
   */
  private applyTags(tags: Record<string, string>): void {
    try {
      // Apply user-provided tags
      Object.entries(tags).forEach(([key, value]) => {
        this.bucket.node.addMetadata(key, value);
      });

      // Add additional bucket-specific tags
      this.bucket.node.addMetadata('Component', 'StaticWebsiteHosting');
      this.bucket.node.addMetadata('Purpose', 'FlutterWebAssets');
    } catch (error) {
      // Log warning but don't fail the construct creation
      console.warn(`Warning: Failed to apply tags to S3 bucket: ${(error as Error).message}`);
    }
  }

  /**
   * Creates lifecycle rules for the S3 bucket based on configuration
   */
  private createLifecycleRules(rules: S3BucketConfig['lifecycleRules']): s3.LifecycleRule[] {
    try {
      return rules.map((rule, index) => {
        // Validate individual rule
        this.errorHandler.validate(
          rule.id && rule.id.trim() !== '',
          'INVALID_LIFECYCLE_RULE_ID',
          `Lifecycle rule ${index + 1} must have a valid ID`,
          ErrorCategory.VALIDATION,
          { rule, index },
          'Provide a non-empty ID for each lifecycle rule'
        );

        this.errorHandler.validate(
          typeof rule.enabled === 'boolean',
          'INVALID_LIFECYCLE_RULE_ENABLED',
          `Lifecycle rule ${index + 1} enabled property must be a boolean`,
          ErrorCategory.VALIDATION,
          { rule, index }
        );

        return {
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
        };
      });
    } catch (error) {
      this.errorHandler.handleError(
        'LIFECYCLE_RULES_CREATION_FAILED',
        `Failed to create lifecycle rules: ${(error as Error).message}`,
        ErrorSeverity.HIGH,
        ErrorCategory.CONFIGURATION,
        { rules },
        'Check lifecycle rule configuration format'
      );
    }
  }

  /**
   * Creates secure CORS rules for web assets based on environment
   */
  private createSecureCorsRules(environment: string): s3.CorsRule[] {
    try {
      const allowedOrigins = this.getAllowedCorsOrigins(environment);
      
      return [
        {
          // Restrict origins based on environment
          allowedOrigins,
          
          // Only allow safe HTTP methods for web assets
          allowedMethods: [
            s3.HttpMethods.GET,
            s3.HttpMethods.HEAD,
          ],
          
          // Minimal required headers for security
          allowedHeaders: [
            'Content-Type',
            'Content-Length',
            'Date',
            'ETag',
            'Authorization', // Only if authentication is needed
          ],
          
          // Minimal exposed headers
          exposedHeaders: [
            'ETag',
            'Content-Length',
          ],
          
          // Shorter cache time for preflight requests in production
          maxAge: environment === 'prod' ? 1800 : 3600, // 30 min prod, 1 hour dev
        },
      ];
    } catch (error) {
      console.warn(`Warning: Failed to create CORS rules, using restrictive defaults: ${(error as Error).message}`);
      
      // Fallback to most restrictive CORS policy
      return [{
        allowedOrigins: ['https://localhost:*'],
        allowedMethods: [s3.HttpMethods.GET, s3.HttpMethods.HEAD],
        allowedHeaders: ['Content-Type'],
        exposedHeaders: ['ETag'],
        maxAge: 1800,
      }];
    }
  }

  /**
   * Gets allowed CORS origins based on environment and configuration
   */
  private getAllowedCorsOrigins(environment: string): string[] {
    const origins: string[] = [];
    
    // Always allow localhost for development
    if (environment !== 'prod') {
      origins.push('https://localhost:*', 'http://localhost:*');
    }
    
    // Add custom domain if configured
    const domainName = this.node.tryGetContext('domainName');
    if (domainName) {
      origins.push(`https://${domainName}`);
    }
    
    // Add CloudFront domain (will be added later when known)
    // This is handled at the application level
    
    // If no origins configured, use restrictive default
    if (origins.length === 0) {
      origins.push('https://localhost:*');
    }
    
    return origins;
  }

  /**
   * Grants read access to the bucket for CloudFront Origin Access Control
   * This method should be called after the CloudFront distribution is created
   */
  public grantReadToCloudFront(cloudFrontOriginAccessIdentity: iam.IPrincipal): void {
    try {
      this.bucket.grantRead(cloudFrontOriginAccessIdentity);
    } catch (error) {
      this.errorHandler.handleError(
        'CLOUDFRONT_ACCESS_GRANT_FAILED',
        `Failed to grant CloudFront access to S3 bucket: ${(error as Error).message}`,
        ErrorSeverity.HIGH,
        ErrorCategory.PERMISSIONS,
        { bucketName: this.bucketName },
        'Check IAM permissions and CloudFront configuration'
      );
    }
  }

  /**
   * Creates a bucket policy statement for CloudFront Origin Access Control
   * This is the modern replacement for Origin Access Identity (OAI)
   */
  public createCloudFrontAccessPolicy(cloudFrontServicePrincipal: iam.ServicePrincipal): iam.PolicyStatement {
    try {
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
    } catch (error) {
      this.errorHandler.handleError(
        'BUCKET_POLICY_CREATION_FAILED',
        `Failed to create CloudFront access policy: ${(error as Error).message}`,
        ErrorSeverity.HIGH,
        ErrorCategory.PERMISSIONS,
        { bucketName: this.bucketName },
        'Check IAM policy syntax and permissions'
      );
    }
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