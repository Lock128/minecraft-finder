import { Construct } from 'constructs';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as origins from 'aws-cdk-lib/aws-cloudfront-origins';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as acm from 'aws-cdk-lib/aws-certificatemanager';
import { Duration } from 'aws-cdk-lib';
import { CachingConfig } from '../types/config';

/**
 * Properties for the CloudFront distribution construct
 */
export interface CloudFrontDistributionConstructProps {
  /** S3 bucket to serve content from */
  s3Bucket: s3.Bucket;
  /** Caching configuration */
  cachingConfig: CachingConfig;
  /** Custom domain names (optional) */
  domainNames?: string[];
  /** ACM certificate ARN for custom domain (optional) */
  certificateArn?: string;
  /** Environment name for resource naming */
  environment: string;
  /** Additional tags to apply to resources */
  tags?: Record<string, string>;
}

/**
 * CloudFront distribution construct for Flutter web application hosting
 * 
 * This construct creates a CloudFront distribution with:
 * - Origin Access Control (OAC) for secure S3 access
 * - Optimized caching behaviors for Flutter web assets
 * - Security headers and HTTPS redirect policies
 * - Error pages configured for SPA routing (404 -> index.html)
 * - Custom domain support with SSL certificate
 */
export class CloudFrontDistributionConstruct extends Construct {
  /** The CloudFront distribution instance */
  public readonly distribution: cloudfront.Distribution;
  
  /** The Origin Access Control for S3 access */
  public readonly originAccessControl: cloudfront.S3OriginAccessControl;
  
  /** The distribution domain name */
  public readonly distributionDomainName: string;
  
  /** The distribution ID */
  public readonly distributionId: string;

  constructor(scope: Construct, id: string, props: CloudFrontDistributionConstructProps) {
    super(scope, id);

    const { s3Bucket, cachingConfig, domainNames, certificateArn, environment, tags = {} } = props;

    // Create Origin Access Control (OAC) - modern replacement for OAI
    this.originAccessControl = new cloudfront.S3OriginAccessControl(this, 'OriginAccessControl', {
      description: `OAC for ${s3Bucket.bucketName}`,
    });

    // Create S3 origin with OAC (manual configuration to avoid automatic bucket policy)
    const s3Origin = new origins.S3Origin(s3Bucket, {
      originAccessControlId: this.originAccessControl.originAccessControlId,
    });

    // Create cache behaviors optimized for Flutter web assets
    const cacheBehaviors = this.createCacheBehaviors(cachingConfig, s3Origin);

    // Create error responses for SPA routing
    const errorResponses = this.createErrorResponses();

    // Create security headers response policy
    const responseHeadersPolicy = this.createResponseHeadersPolicy();

    // Create the CloudFront distribution
    this.distribution = new cloudfront.Distribution(this, 'Distribution', {
      // Origin configuration
      defaultBehavior: {
        origin: s3Origin,
        viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
        cachePolicy: this.createDefaultCachePolicy(cachingConfig),
        responseHeadersPolicy,
        compress: true,
        allowedMethods: cloudfront.AllowedMethods.ALLOW_GET_HEAD,
        cachedMethods: cloudfront.CachedMethods.CACHE_GET_HEAD,
      },
      
      // Additional cache behaviors for different asset types
      additionalBehaviors: cacheBehaviors,
      
      // Custom domain configuration
      domainNames,
      certificate: certificateArn ? acm.Certificate.fromCertificateArn(
        this, 
        'Certificate', 
        certificateArn
      ) : undefined,
      
      // Error page configuration for SPA routing
      errorResponses,
      
      // Default root object
      defaultRootObject: 'index.html',
      
      // Enable IPv6
      enableIpv6: true,
      
      // Price class for cost optimization
      priceClass: this.getPriceClass(environment),
      
      // Enable logging in production
      enableLogging: environment === 'prod',
      logBucket: environment === 'prod' ? this.createLogBucket() : undefined,
      logFilePrefix: environment === 'prod' ? 'cloudfront-logs/' : undefined,
      
      // HTTP version
      httpVersion: cloudfront.HttpVersion.HTTP2_AND_3,
      
      // Comment for identification
      comment: `CloudFront distribution for Flutter web app - ${environment}`,
    });

    // Store distribution properties
    this.distributionDomainName = this.distribution.distributionDomainName;
    this.distributionId = this.distribution.distributionId;

    // Note: S3 bucket access is granted via Origin Access Control (OAC)
    // The bucket policy will be handled separately to avoid circular dependencies

    // Apply tags
    this.applyTags(tags);
  }

  /**
   * Creates cache behaviors optimized for different Flutter web asset types
   */
  private createCacheBehaviors(cachingConfig: CachingConfig, s3Origin: cloudfront.IOrigin): Record<string, cloudfront.BehaviorOptions> {
    const behaviors: Record<string, cloudfront.BehaviorOptions> = {};

    // Static assets (JS, CSS, images, fonts) - long cache
    behaviors['/assets/*'] = {
      origin: s3Origin,
      viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
      cachePolicy: this.createStaticAssetsCachePolicy(cachingConfig),
      compress: true,
      allowedMethods: cloudfront.AllowedMethods.ALLOW_GET_HEAD,
      cachedMethods: cloudfront.CachedMethods.CACHE_GET_HEAD,
    };

    // Flutter web specific assets
    behaviors['/flutter_service_worker.js'] = {
      origin: s3Origin,
      viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
      cachePolicy: this.createServiceWorkerCachePolicy(),
      compress: true,
      allowedMethods: cloudfront.AllowedMethods.ALLOW_GET_HEAD,
      cachedMethods: cloudfront.CachedMethods.CACHE_GET_HEAD,
    };

    // Manifest and other metadata files
    behaviors['/manifest.json'] = {
      origin: s3Origin,
      viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
      cachePolicy: this.createManifestCachePolicy(cachingConfig),
      compress: true,
      allowedMethods: cloudfront.AllowedMethods.ALLOW_GET_HEAD,
      cachedMethods: cloudfront.CachedMethods.CACHE_GET_HEAD,
    };

    return behaviors;
  }

  /**
   * Creates error responses for SPA routing
   */
  private createErrorResponses(): cloudfront.ErrorResponse[] {
    return [
      {
        // Handle 404 errors by serving index.html (SPA routing)
        httpStatus: 404,
        responseHttpStatus: 200,
        responsePagePath: '/index.html',
      },
      {
        // Handle 403 errors (S3 returns 403 for non-existent files)
        httpStatus: 403,
        responseHttpStatus: 200,
        responsePagePath: '/index.html',
      },
    ];
  }

  /**
   * Creates response headers policy for security
   */
  private createResponseHeadersPolicy(): cloudfront.ResponseHeadersPolicy {
    return new cloudfront.ResponseHeadersPolicy(this, 'SecurityHeadersPolicy', {
      comment: 'Security headers for Flutter web app',
      
      // Security headers
      securityHeadersBehavior: {
        // Content Type Options
        contentTypeOptions: {
          override: true,
        },
        
        // Frame Options
        frameOptions: {
          frameOption: cloudfront.HeadersFrameOption.DENY,
          override: true,
        },
        
        // Referrer Policy
        referrerPolicy: {
          referrerPolicy: cloudfront.HeadersReferrerPolicy.STRICT_ORIGIN_WHEN_CROSS_ORIGIN,
          override: true,
        },
        
        // Strict Transport Security (HSTS)
        strictTransportSecurity: {
          accessControlMaxAge: Duration.seconds(31536000), // 1 year
          includeSubdomains: true,
          preload: true,
          override: true,
        },
      },
      
      // Custom headers for Flutter web optimization
      customHeadersBehavior: {
        customHeaders: [
          {
            header: 'Cache-Control',
            value: 'public, max-age=0, must-revalidate',
            override: false,
          },
          {
            header: 'X-Content-Type-Options',
            value: 'nosniff',
            override: true,
          },
        ],
      },
    });
  }

  /**
   * Creates default cache policy for HTML files
   */
  private createDefaultCachePolicy(cachingConfig: CachingConfig): cloudfront.CachePolicy {
    return new cloudfront.CachePolicy(this, 'DefaultCachePolicy', {
      comment: 'Cache policy for HTML files',
      defaultTtl: Duration.seconds(cachingConfig.htmlTtl),
      maxTtl: Duration.seconds(cachingConfig.maxTtl),
      minTtl: Duration.seconds(0),
      
      // Cache key configuration
      cachePolicyName: `html-cache-policy-${this.node.addr}`,
      enableAcceptEncodingGzip: true,
      enableAcceptEncodingBrotli: true,
      
      // Query string and header configuration
      queryStringBehavior: cloudfront.CacheQueryStringBehavior.none(),
      headerBehavior: cloudfront.CacheHeaderBehavior.allowList(
        'CloudFront-Viewer-Country',
        'CloudFront-Is-Mobile-Viewer',
        'CloudFront-Is-Tablet-Viewer',
        'CloudFront-Is-Desktop-Viewer'
      ),
      cookieBehavior: cloudfront.CacheCookieBehavior.none(),
    });
  }

  /**
   * Creates cache policy for static assets (JS, CSS, images)
   */
  private createStaticAssetsCachePolicy(cachingConfig: CachingConfig): cloudfront.CachePolicy {
    return new cloudfront.CachePolicy(this, 'StaticAssetsCachePolicy', {
      comment: 'Cache policy for static assets',
      defaultTtl: Duration.seconds(cachingConfig.staticAssetsTtl),
      maxTtl: Duration.seconds(cachingConfig.maxTtl),
      minTtl: Duration.seconds(cachingConfig.staticAssetsTtl),
      
      cachePolicyName: `static-assets-cache-policy-${this.node.addr}`,
      enableAcceptEncodingGzip: true,
      enableAcceptEncodingBrotli: true,
      
      // Static assets don't need query strings or headers for caching
      queryStringBehavior: cloudfront.CacheQueryStringBehavior.none(),
      headerBehavior: cloudfront.CacheHeaderBehavior.none(),
      cookieBehavior: cloudfront.CacheCookieBehavior.none(),
    });
  }

  /**
   * Creates cache policy for service worker (should not be cached)
   */
  private createServiceWorkerCachePolicy(): cloudfront.CachePolicy {
    return new cloudfront.CachePolicy(this, 'ServiceWorkerCachePolicy', {
      comment: 'Cache policy for service worker (no cache)',
      defaultTtl: Duration.seconds(0),
      maxTtl: Duration.seconds(0),
      minTtl: Duration.seconds(0),
      
      cachePolicyName: `service-worker-cache-policy-${this.node.addr}`,
      enableAcceptEncodingGzip: true,
      enableAcceptEncodingBrotli: true,
      
      queryStringBehavior: cloudfront.CacheQueryStringBehavior.none(),
      headerBehavior: cloudfront.CacheHeaderBehavior.none(),
      cookieBehavior: cloudfront.CacheCookieBehavior.none(),
    });
  }

  /**
   * Creates cache policy for manifest and metadata files
   */
  private createManifestCachePolicy(cachingConfig: CachingConfig): cloudfront.CachePolicy {
    return new cloudfront.CachePolicy(this, 'ManifestCachePolicy', {
      comment: 'Cache policy for manifest and metadata files',
      defaultTtl: Duration.seconds(cachingConfig.htmlTtl),
      maxTtl: Duration.seconds(cachingConfig.maxTtl),
      minTtl: Duration.seconds(0),
      
      cachePolicyName: `manifest-cache-policy-${this.node.addr}`,
      enableAcceptEncodingGzip: true,
      enableAcceptEncodingBrotli: true,
      
      queryStringBehavior: cloudfront.CacheQueryStringBehavior.none(),
      headerBehavior: cloudfront.CacheHeaderBehavior.none(),
      cookieBehavior: cloudfront.CacheCookieBehavior.none(),
    });
  }

  /**
   * Gets the appropriate price class based on environment
   */
  private getPriceClass(environment: string): cloudfront.PriceClass {
    switch (environment) {
      case 'prod':
        return cloudfront.PriceClass.PRICE_CLASS_ALL;
      case 'staging':
        return cloudfront.PriceClass.PRICE_CLASS_200;
      default:
        return cloudfront.PriceClass.PRICE_CLASS_100;
    }
  }

  /**
   * Creates a log bucket for CloudFront access logs (production only)
   */
  private createLogBucket(): s3.Bucket {
    return new s3.Bucket(this, 'LogBucket', {
      bucketName: `cloudfront-logs-${Date.now()}`,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      encryption: s3.BucketEncryption.S3_MANAGED,
      lifecycleRules: [
        {
          id: 'DeleteOldLogs',
          enabled: true,
          expiration: Duration.days(90),
        },
      ],
    });
  }

  /**
   * Grants S3 bucket access to CloudFront via Origin Access Control
   */
  private grantS3Access(s3Bucket: s3.Bucket): void {
    // Create bucket policy statement for OAC access
    const bucketPolicyStatement = new iam.PolicyStatement({
      sid: 'AllowCloudFrontServicePrincipal',
      effect: iam.Effect.ALLOW,
      principals: [new iam.ServicePrincipal('cloudfront.amazonaws.com')],
      actions: ['s3:GetObject'],
      resources: [`${s3Bucket.bucketArn}/*`],
      conditions: {
        StringEquals: {
          'AWS:SourceArn': `arn:aws:cloudfront::${this.node.tryGetContext('account') || process.env.CDK_DEFAULT_ACCOUNT}:distribution/${this.distribution.distributionId}`,
        },
      },
    });

    // Add the policy statement to the bucket
    s3Bucket.addToResourcePolicy(bucketPolicyStatement);
  }

  /**
   * Applies tags to the distribution
   */
  private applyTags(tags: Record<string, string>): void {
    Object.entries(tags).forEach(([key, value]) => {
      this.distribution.node.addMetadata(key, value);
    });

    // Add component-specific tags
    this.distribution.node.addMetadata('Component', 'CloudFrontDistribution');
    this.distribution.node.addMetadata('Purpose', 'FlutterWebHosting');
  }

  /**
   * Gets the CloudFront distribution URL
   */
  public get distributionUrl(): string {
    return `https://${this.distributionDomainName}`;
  }

  /**
   * Gets the custom domain URL (if configured)
   */
  public getCustomDomainUrl(domainName?: string): string | undefined {
    if (domainName) {
      return `https://${domainName}`;
    }
    return undefined;
  }

  /**
   * Creates a cache invalidation for the distribution
   * This method can be used in deployment scripts
   */
  public createInvalidation(paths: string[] = ['/*']): string {
    // This would typically be called from deployment scripts
    // Return the AWS CLI command for reference
    return `aws cloudfront create-invalidation --distribution-id ${this.distributionId} --paths ${paths.join(' ')}`;
  }
}