import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

/**
 * Security configuration and utilities for AWS infrastructure
 * Implements security best practices and hardening measures
 */
export class SecurityConfig {
  
  /**
   * Creates a least-privilege IAM role for GitHub Actions deployment
   */
  static createGitHubActionsRole(scope: Construct, environment: string): iam.Role {
    const role = new iam.Role(scope, 'GitHubActionsRole', {
      roleName: `github-actions-web-hosting-${environment}`,
      description: `Least-privilege role for GitHub Actions web hosting deployment - ${environment}`,
      
      // Trust policy - only allow GitHub Actions OIDC provider
      assumedBy: new iam.WebIdentityPrincipal(
        'arn:aws:iam::*:oidc-provider/token.actions.githubusercontent.com',
        {
          StringEquals: {
            'token.actions.githubusercontent.com:aud': 'sts.amazonaws.com',
          },
          StringLike: {
            'token.actions.githubusercontent.com:sub': 'repo:*:ref:refs/heads/main',
          },
        }
      ),
      
      // Maximum session duration
      maxSessionDuration: Duration.hours(2),
      
      // Inline policies with minimal required permissions
      inlinePolicies: {
        CDKDeploymentPolicy: SecurityConfig.createCDKDeploymentPolicy(),
        S3AssetUploadPolicy: SecurityConfig.createS3AssetUploadPolicy(),
        CloudFrontInvalidationPolicy: SecurityConfig.createCloudFrontInvalidationPolicy(),
      },
    });

    // Add condition to restrict to specific repositories (if configured)
    const allowedRepos = scope.node.tryGetContext('allowedGitHubRepos');
    if (allowedRepos && Array.isArray(allowedRepos)) {
      role.assumeRolePolicy?.addStatements(
        new iam.PolicyStatement({
          effect: iam.Effect.DENY,
          principals: [new iam.AnyPrincipal()],
          actions: ['sts:AssumeRoleWithWebIdentity'],
          conditions: {
            StringNotLike: {
              'token.actions.githubusercontent.com:sub': allowedRepos.map(repo => `repo:${repo}:*`),
            },
          },
        })
      );
    }

    return role;
  }

  /**
   * Creates minimal CDK deployment policy
   */
  private static createCDKDeploymentPolicy(): iam.PolicyDocument {
    return new iam.PolicyDocument({
      statements: [
        // CloudFormation permissions
        new iam.PolicyStatement({
          sid: 'CloudFormationAccess',
          effect: iam.Effect.ALLOW,
          actions: [
            'cloudformation:CreateStack',
            'cloudformation:UpdateStack',
            'cloudformation:DeleteStack',
            'cloudformation:DescribeStacks',
            'cloudformation:DescribeStackEvents',
            'cloudformation:DescribeStackResources',
            'cloudformation:GetTemplate',
            'cloudformation:ValidateTemplate',
            'cloudformation:CreateChangeSet',
            'cloudformation:DescribeChangeSet',
            'cloudformation:ExecuteChangeSet',
            'cloudformation:DeleteChangeSet',
            'cloudformation:ListChangeSets',
          ],
          resources: [
            'arn:aws:cloudformation:*:*:stack/WebHostingStack-*/*',
            'arn:aws:cloudformation:*:*:stack/CDKToolkit/*',
          ],
        }),
        
        // S3 permissions for CDK assets
        new iam.PolicyStatement({
          sid: 'CDKAssetsS3Access',
          effect: iam.Effect.ALLOW,
          actions: [
            's3:GetObject',
            's3:PutObject',
            's3:DeleteObject',
            's3:ListBucket',
          ],
          resources: [
            'arn:aws:s3:::cdk-*-assets-*',
            'arn:aws:s3:::cdk-*-assets-*/*',
          ],
        }),
        
        // IAM permissions for CDK (limited)
        new iam.PolicyStatement({
          sid: 'CDKIAMAccess',
          effect: iam.Effect.ALLOW,
          actions: [
            'iam:CreateRole',
            'iam:DeleteRole',
            'iam:GetRole',
            'iam:PassRole',
            'iam:AttachRolePolicy',
            'iam:DetachRolePolicy',
            'iam:PutRolePolicy',
            'iam:DeleteRolePolicy',
            'iam:GetRolePolicy',
            'iam:TagRole',
            'iam:UntagRole',
          ],
          resources: [
            'arn:aws:iam::*:role/WebHostingStack-*',
            'arn:aws:iam::*:role/cdk-*',
          ],
        }),
        
        // CloudFront permissions
        new iam.PolicyStatement({
          sid: 'CloudFrontAccess',
          effect: iam.Effect.ALLOW,
          actions: [
            'cloudfront:CreateDistribution',
            'cloudfront:UpdateDistribution',
            'cloudfront:DeleteDistribution',
            'cloudfront:GetDistribution',
            'cloudfront:GetDistributionConfig',
            'cloudfront:ListDistributions',
            'cloudfront:CreateOriginAccessControl',
            'cloudfront:DeleteOriginAccessControl',
            'cloudfront:GetOriginAccessControl',
            'cloudfront:UpdateOriginAccessControl',
            'cloudfront:CreateCachePolicy',
            'cloudfront:DeleteCachePolicy',
            'cloudfront:GetCachePolicy',
            'cloudfront:UpdateCachePolicy',
            'cloudfront:CreateResponseHeadersPolicy',
            'cloudfront:DeleteResponseHeadersPolicy',
            'cloudfront:GetResponseHeadersPolicy',
            'cloudfront:UpdateResponseHeadersPolicy',
            'cloudfront:TagResource',
            'cloudfront:UntagResource',
          ],
          resources: ['*'], // CloudFront doesn't support resource-level permissions
        }),
        
        // S3 permissions for website bucket
        new iam.PolicyStatement({
          sid: 'WebsiteS3Access',
          effect: iam.Effect.ALLOW,
          actions: [
            's3:CreateBucket',
            's3:DeleteBucket',
            's3:GetBucketLocation',
            's3:GetBucketPolicy',
            's3:PutBucketPolicy',
            's3:DeleteBucketPolicy',
            's3:GetBucketAcl',
            's3:PutBucketAcl',
            's3:GetBucketCors',
            's3:PutBucketCors',
            's3:GetBucketWebsite',
            's3:PutBucketWebsite',
            's3:GetBucketVersioning',
            's3:PutBucketVersioning',
            's3:GetBucketLifecycleConfiguration',
            's3:PutBucketLifecycleConfiguration',
            's3:GetBucketEncryption',
            's3:PutBucketEncryption',
            's3:GetBucketPublicAccessBlock',
            's3:PutBucketPublicAccessBlock',
            's3:GetBucketTagging',
            's3:PutBucketTagging',
          ],
          resources: ['arn:aws:s3:::*-web-hosting-*'],
        }),
        
        // ACM permissions
        new iam.PolicyStatement({
          sid: 'ACMAccess',
          effect: iam.Effect.ALLOW,
          actions: [
            'acm:RequestCertificate',
            'acm:DeleteCertificate',
            'acm:DescribeCertificate',
            'acm:ListCertificates',
            'acm:AddTagsToCertificate',
            'acm:RemoveTagsFromCertificate',
          ],
          resources: ['*'], // ACM doesn't support resource-level permissions for some actions
        }),
        
        // CloudWatch RUM permissions
        new iam.PolicyStatement({
          sid: 'CloudWatchRUMAccess',
          effect: iam.Effect.ALLOW,
          actions: [
            'rum:CreateAppMonitor',
            'rum:DeleteAppMonitor',
            'rum:GetAppMonitor',
            'rum:UpdateAppMonitor',
            'rum:ListAppMonitors',
            'rum:TagResource',
            'rum:UntagResource',
          ],
          resources: ['*'], // RUM doesn't support resource-level permissions
        }),
        
        // STS permissions for cross-account access
        new iam.PolicyStatement({
          sid: 'STSAccess',
          effect: iam.Effect.ALLOW,
          actions: [
            'sts:AssumeRole',
          ],
          resources: [
            'arn:aws:iam::*:role/*-dns-management-*',
          ],
        }),
      ],
    });
  }

  /**
   * Creates minimal S3 asset upload policy
   */
  private static createS3AssetUploadPolicy(): iam.PolicyDocument {
    return new iam.PolicyDocument({
      statements: [
        new iam.PolicyStatement({
          sid: 'S3AssetUpload',
          effect: iam.Effect.ALLOW,
          actions: [
            's3:GetObject',
            's3:PutObject',
            's3:DeleteObject',
            's3:ListBucket',
          ],
          resources: [
            'arn:aws:s3:::*-web-hosting-*',
            'arn:aws:s3:::*-web-hosting-*/*',
          ],
        }),
      ],
    });
  }

  /**
   * Creates minimal CloudFront invalidation policy
   */
  private static createCloudFrontInvalidationPolicy(): iam.PolicyDocument {
    return new iam.PolicyDocument({
      statements: [
        new iam.PolicyStatement({
          sid: 'CloudFrontInvalidation',
          effect: iam.Effect.ALLOW,
          actions: [
            'cloudfront:CreateInvalidation',
            'cloudfront:GetInvalidation',
            'cloudfront:ListInvalidations',
          ],
          resources: ['*'], // CloudFront doesn't support resource-level permissions
        }),
      ],
    });
  }

  /**
   * Creates a secure cross-account role for DNS management
   */
  static createCrossAccountDNSRole(scope: Construct, trustedAccountId: string): iam.Role {
    return new iam.Role(scope, 'CrossAccountDNSRole', {
      roleName: 'web-hosting-dns-management',
      description: 'Cross-account role for DNS management with minimal permissions',
      
      // Trust policy - only allow specific account
      assumedBy: new iam.AccountPrincipal(trustedAccountId),
      
      // External ID for additional security
      externalIds: [scope.node.tryGetContext('dnsRoleExternalId') || 'web-hosting-dns-2024'],
      
      // Maximum session duration
      maxSessionDuration: Duration.hours(1),
      
      // Minimal Route53 permissions
      inlinePolicies: {
        Route53Access: new iam.PolicyDocument({
          statements: [
            new iam.PolicyStatement({
              sid: 'Route53RecordManagement',
              effect: iam.Effect.ALLOW,
              actions: [
                'route53:GetHostedZone',
                'route53:ListResourceRecordSets',
                'route53:ChangeResourceRecordSets',
              ],
              resources: [
                'arn:aws:route53:::hostedzone/*', // Will be restricted by condition
              ],
              conditions: {
                StringEquals: {
                  'route53:HostedZoneId': scope.node.tryGetContext('hostedZoneId'),
                },
              },
            }),
            new iam.PolicyStatement({
              sid: 'Route53ChangeInfo',
              effect: iam.Effect.ALLOW,
              actions: [
                'route53:GetChange',
              ],
              resources: ['arn:aws:route53:::change/*'],
            }),
          ],
        }),
      },
    });
  }

  /**
   * Creates security monitoring and alerting policies
   */
  static createSecurityMonitoringPolicies(): iam.PolicyDocument {
    return new iam.PolicyDocument({
      statements: [
        // CloudWatch Logs for security monitoring
        new iam.PolicyStatement({
          sid: 'SecurityLogsAccess',
          effect: iam.Effect.ALLOW,
          actions: [
            'logs:CreateLogGroup',
            'logs:CreateLogStream',
            'logs:PutLogEvents',
            'logs:DescribeLogGroups',
            'logs:DescribeLogStreams',
          ],
          resources: [
            'arn:aws:logs:*:*:log-group:/aws/security/*',
            'arn:aws:logs:*:*:log-group:/aws/cloudfront/*',
          ],
        }),
        
        // CloudWatch metrics for security monitoring
        new iam.PolicyStatement({
          sid: 'SecurityMetricsAccess',
          effect: iam.Effect.ALLOW,
          actions: [
            'cloudwatch:PutMetricData',
            'cloudwatch:GetMetricStatistics',
            'cloudwatch:ListMetrics',
          ],
          resources: ['*'],
          conditions: {
            StringEquals: {
              'cloudwatch:namespace': ['AWS/CloudFront', 'AWS/S3', 'Custom/Security'],
            },
          },
        }),
      ],
    });
  }

  /**
   * Validates security configuration
   */
  static validateSecurityConfig(config: any): void {
    const requiredFields = [
      'environment',
      'domainName',
      'hostedZoneId',
    ];

    for (const field of requiredFields) {
      if (!config[field]) {
        throw new Error(`Security validation failed: Missing required field '${field}'`);
      }
    }

    // Validate domain name format
    if (!/^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\.[a-zA-Z]{2,}$/.test(config.domainName)) {
      throw new Error('Security validation failed: Invalid domain name format');
    }

    // Validate environment
    if (!['dev', 'staging', 'prod'].includes(config.environment)) {
      throw new Error('Security validation failed: Invalid environment. Must be dev, staging, or prod');
    }

    // Production-specific validations
    if (config.environment === 'prod') {
      if (!config.kmsKeyId && !config.createKmsKey) {
        console.warn('Warning: Production environment should use KMS encryption');
      }
      
      if (!config.allowedIpRanges || !Array.isArray(config.allowedIpRanges)) {
        console.warn('Warning: Production environment should restrict IP access');
      }
    }
  }

  /**
   * Gets security headers for different content types
   */
  static getSecurityHeaders(contentType: string): Record<string, string> {
    const baseHeaders = {
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block',
      'Referrer-Policy': 'strict-origin-when-cross-origin',
      'Strict-Transport-Security': 'max-age=63072000; includeSubDomains; preload',
    };

    // Content-type specific headers
    if (contentType.includes('text/html')) {
      return {
        ...baseHeaders,
        'Content-Security-Policy': SecurityConfig.getContentSecurityPolicy(),
        'Permissions-Policy': 'camera=(), microphone=(), geolocation=(), payment=()',
      };
    }

    if (contentType.includes('application/javascript')) {
      return {
        ...baseHeaders,
        'Cache-Control': 'public, max-age=31536000, immutable',
      };
    }

    if (contentType.includes('text/css')) {
      return {
        ...baseHeaders,
        'Cache-Control': 'public, max-age=31536000, immutable',
      };
    }

    return baseHeaders;
  }

  /**
   * Gets Content Security Policy for Flutter web apps
   */
  private static getContentSecurityPolicy(): string {
    return [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline' 'unsafe-eval' blob:",
      "style-src 'self' 'unsafe-inline' fonts.googleapis.com",
      "font-src 'self' fonts.gstatic.com data:",
      "img-src 'self' data: blob:",
      "connect-src 'self' https:",
      "media-src 'self'",
      "object-src 'none'",
      "base-uri 'self'",
      "form-action 'self'",
      "frame-ancestors 'none'",
      "frame-src 'none'",
      "worker-src 'self' blob:",
      "manifest-src 'self'",
      "upgrade-insecure-requests",
      "block-all-mixed-content",
    ].join('; ');
  }
}

// Import Duration for use in the class
import { Duration } from 'aws-cdk-lib';