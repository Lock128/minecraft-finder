/**
 * Environment types for deployment configuration
 */
export type Environment = 'dev' | 'staging' | 'prod';

/**
 * Domain configuration for custom domain setup
 */
export interface DomainConfig {
  /** The custom domain name (e.g., app.minecraft.lockhead.cloud) */
  domainName: string;
  /** Route53 hosted zone ID in the DNS management account */
  hostedZoneId: string;
  /** ARN of the cross-account role for DNS operations */
  crossAccountRoleArn: string;
  /** AWS region for certificate creation (must be us-east-1 for CloudFront) */
  certificateRegion: string;
}

/**
 * CloudWatch RUM monitoring configuration
 */
export interface MonitoringConfig {
  /** Name of the RUM application */
  rumAppName: string;
  /** Sampling rate for RUM data collection (0.0 to 1.0) */
  samplingRate: number;
  /** List of enabled metrics for collection */
  enabledMetrics: string[];
  /** Whether to enable extended metrics */
  enableExtendedMetrics: boolean;
}

/**
 * CloudFront caching configuration
 */
export interface CachingConfig {
  /** Default TTL in seconds */
  defaultTtl: number;
  /** Maximum TTL in seconds */
  maxTtl: number;
  /** TTL for static assets (JS, CSS, images) */
  staticAssetsTtl: number;
  /** TTL for HTML files */
  htmlTtl: number;
}

/**
 * S3 bucket configuration
 */
export interface S3BucketConfig {
  /** Bucket name prefix (will be made unique) */
  bucketNamePrefix: string;
  /** Whether to enable versioning */
  versioning: boolean;
  /** Whether to enable public read access (should be false for CloudFront-only access) */
  publicReadAccess: boolean;
  /** Lifecycle rules for cost optimization */
  lifecycleRules: S3LifecycleRule[];
}

/**
 * S3 lifecycle rule configuration
 */
export interface S3LifecycleRule {
  /** Rule ID */
  id: string;
  /** Whether the rule is enabled */
  enabled: boolean;
  /** Days after which to transition to IA storage */
  transitionToIADays?: number;
  /** Days after which to delete objects */
  expirationDays?: number;
  /** Days after which to delete incomplete multipart uploads */
  abortIncompleteMultipartUploadDays?: number;
}

/**
 * Complete deployment configuration
 */
export interface DeploymentConfig {
  /** Deployment environment */
  environment: Environment;
  /** Domain configuration */
  domainConfig: DomainConfig;
  /** Monitoring configuration */
  monitoringConfig: MonitoringConfig;
  /** Caching configuration */
  cachingConfig: CachingConfig;
  /** S3 bucket configuration */
  s3Config: S3BucketConfig;
  /** Resource tags */
  tags: Record<string, string>;
}

/**
 * Stack properties for the web hosting stack
 */
export interface WebHostingStackProps {
  /** Deployment configuration */
  config: DeploymentConfig;
  /** AWS account ID */
  account?: string;
  /** AWS region */
  region?: string;
}