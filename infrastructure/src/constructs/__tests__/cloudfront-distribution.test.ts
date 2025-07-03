import { App, Stack } from 'aws-cdk-lib';
import { Template, Match } from 'aws-cdk-lib/assertions';
import * as s3 from 'aws-cdk-lib/aws-s3';
import { CloudFrontDistributionConstruct } from '../cloudfront-distribution';
import { CachingConfig } from '../../types/config';

describe('CloudFrontDistributionConstruct', () => {
  let app: App;
  let stack: Stack;
  let s3Bucket: s3.Bucket;
  let cachingConfig: CachingConfig;

  beforeEach(() => {
    app = new App();
    stack = new Stack(app, 'TestStack');
    
    // Create a test S3 bucket
    s3Bucket = new s3.Bucket(stack, 'TestBucket', {
      bucketName: 'test-bucket-12345',
    });

    // Create test caching configuration
    cachingConfig = {
      defaultTtl: 86400,
      maxTtl: 31536000,
      staticAssetsTtl: 31536000,
      htmlTtl: 3600,
    };
  });

  describe('Basic CloudFront Distribution Creation', () => {
    test('should create CloudFront distribution with basic configuration', () => {
      // Act
      const construct = new CloudFrontDistributionConstruct(stack, 'TestCloudFront', {
        s3Bucket,
        cachingConfig,
        environment: 'dev',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      // Check that CloudFront distribution is created
      template.hasResourceProperties('AWS::CloudFront::Distribution', {
        DistributionConfig: {
          Enabled: true,
          DefaultRootObject: 'index.html',
          HttpVersion: 'http2and3',
          IPV6Enabled: true,
          PriceClass: 'PriceClass_100', // Dev environment uses cheapest price class
        },
      });

      // Verify construct properties
      expect(construct.distribution).toBeDefined();
      expect(construct.originAccessControl).toBeDefined();
      expect(construct.distributionDomainName).toBeDefined();
      expect(construct.distributionId).toBeDefined();
    });

    test('should create Origin Access Control (OAC)', () => {
      // Act
      new CloudFrontDistributionConstruct(stack, 'TestCloudFront', {
        s3Bucket,
        cachingConfig,
        environment: 'dev',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      template.hasResourceProperties('AWS::CloudFront::OriginAccessControl', {
        OriginAccessControlConfig: {
          OriginAccessControlOriginType: 's3',
          SigningBehavior: 'always',
          SigningProtocol: 'sigv4',
        },
      });
    });

    test('should configure HTTPS redirect policy', () => {
      // Act
      new CloudFrontDistributionConstruct(stack, 'TestCloudFront', {
        s3Bucket,
        cachingConfig,
        environment: 'dev',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      template.hasResourceProperties('AWS::CloudFront::Distribution', {
        DistributionConfig: {
          DefaultCacheBehavior: {
            ViewerProtocolPolicy: 'redirect-to-https',
          },
        },
      });
    });
  });

  describe('Custom Domain Configuration', () => {
    test('should configure custom domain when provided', () => {
      // Arrange
      const domainNames = ['test.example.com'];
      const certificateArn = 'arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012';

      // Act
      new CloudFrontDistributionConstruct(stack, 'TestCloudFront', {
        s3Bucket,
        cachingConfig,
        domainNames,
        certificateArn,
        environment: 'prod',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      template.hasResourceProperties('AWS::CloudFront::Distribution', {
        DistributionConfig: {
          Aliases: domainNames,
          ViewerCertificate: {
            AcmCertificateArn: certificateArn,
            SslSupportMethod: 'sni-only',
            MinimumProtocolVersion: 'TLSv1.2_2021',
          },
        },
      });
    });

    test('should not configure custom domain when not provided', () => {
      // Act
      new CloudFrontDistributionConstruct(stack, 'TestCloudFront', {
        s3Bucket,
        cachingConfig,
        environment: 'dev',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      template.hasResourceProperties('AWS::CloudFront::Distribution', {
        DistributionConfig: {
          Aliases: Match.absent(),
        },
      });
    });
  });

  describe('Error Page Configuration for SPA', () => {
    test('should configure error pages for SPA routing', () => {
      // Act
      new CloudFrontDistributionConstruct(stack, 'TestCloudFront', {
        s3Bucket,
        cachingConfig,
        environment: 'dev',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      template.hasResourceProperties('AWS::CloudFront::Distribution', {
        DistributionConfig: {
          CustomErrorResponses: [
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
          ],
        },
      });
    });
  });

  describe('Cache Behaviors for Flutter Assets', () => {
    test('should create optimized cache behaviors for different asset types', () => {
      // Act
      new CloudFrontDistributionConstruct(stack, 'TestCloudFront', {
        s3Bucket,
        cachingConfig,
        environment: 'dev',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      // Check that additional cache behaviors are created
      template.hasResourceProperties('AWS::CloudFront::Distribution', {
        DistributionConfig: {
          CacheBehaviors: Match.arrayWith([
            // Static assets behavior
            Match.objectLike({
              PathPattern: '/assets/*',
              ViewerProtocolPolicy: 'redirect-to-https',
              Compress: true,
            }),
            // Service worker behavior
            Match.objectLike({
              PathPattern: '/flutter_service_worker.js',
              ViewerProtocolPolicy: 'redirect-to-https',
              Compress: true,
            }),
            // Manifest behavior
            Match.objectLike({
              PathPattern: '/manifest.json',
              ViewerProtocolPolicy: 'redirect-to-https',
              Compress: true,
            }),
          ]),
        },
      });
    });

    test('should create cache policies with appropriate TTL values', () => {
      // Act
      new CloudFrontDistributionConstruct(stack, 'TestCloudFront', {
        s3Bucket,
        cachingConfig,
        environment: 'dev',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      // Check that cache policies are created
      template.resourceCountIs('AWS::CloudFront::CachePolicy', 4); // Default, static assets, service worker, manifest
      
      // Verify static assets cache policy has long TTL
      template.hasResourceProperties('AWS::CloudFront::CachePolicy', {
        CachePolicyConfig: {
          Comment: 'Cache policy for static assets',
          DefaultTTL: cachingConfig.staticAssetsTtl,
          MaxTTL: cachingConfig.maxTtl,
          MinTTL: cachingConfig.staticAssetsTtl,
        },
      });

      // Verify service worker cache policy has no cache
      template.hasResourceProperties('AWS::CloudFront::CachePolicy', {
        CachePolicyConfig: {
          Comment: 'Cache policy for service worker (no cache)',
          DefaultTTL: 0,
          MaxTTL: 0,
          MinTTL: 0,
        },
      });
    });
  });

  describe('Security Headers Configuration', () => {
    test('should create response headers policy with security headers', () => {
      // Act
      new CloudFrontDistributionConstruct(stack, 'TestCloudFront', {
        s3Bucket,
        cachingConfig,
        environment: 'dev',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      template.hasResourceProperties('AWS::CloudFront::ResponseHeadersPolicy', {
        ResponseHeadersPolicyConfig: {
          Comment: 'Security headers for Flutter web app',
          SecurityHeadersConfig: {
            ContentTypeOptions: {
              Override: true,
            },
            FrameOptions: {
              FrameOption: 'DENY',
              Override: true,
            },
            ReferrerPolicy: {
              ReferrerPolicy: 'strict-origin-when-cross-origin',
              Override: true,
            },
            StrictTransportSecurity: {
              AccessControlMaxAgeSec: 31536000,
              IncludeSubdomains: true,
              Preload: true,
              Override: true,
            },
          },
        },
      });
    });
  });

  describe('Environment-Specific Configuration', () => {
    test('should use appropriate price class for production', () => {
      // Act
      new CloudFrontDistributionConstruct(stack, 'TestCloudFront', {
        s3Bucket,
        cachingConfig,
        environment: 'prod',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      template.hasResourceProperties('AWS::CloudFront::Distribution', {
        DistributionConfig: {
          PriceClass: 'PriceClass_All',
          Logging: Match.objectLike({
            Bucket: Match.anyValue(),
            Prefix: 'cloudfront-logs/',
          }),
        },
      });
    });

    test('should use cost-effective price class for development', () => {
      // Act
      new CloudFrontDistributionConstruct(stack, 'TestCloudFront', {
        s3Bucket,
        cachingConfig,
        environment: 'dev',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      template.hasResourceProperties('AWS::CloudFront::Distribution', {
        DistributionConfig: {
          PriceClass: 'PriceClass_100',
          Logging: Match.absent(),
        },
      });
    });

    test('should use intermediate price class for staging', () => {
      // Act
      new CloudFrontDistributionConstruct(stack, 'TestCloudFront', {
        s3Bucket,
        cachingConfig,
        environment: 'staging',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      template.hasResourceProperties('AWS::CloudFront::Distribution', {
        DistributionConfig: {
          PriceClass: 'PriceClass_200',
        },
      });
    });
  });

  describe('S3 Bucket Policy Integration', () => {
    test('should add bucket policy for CloudFront OAC access', () => {
      // Act
      new CloudFrontDistributionConstruct(stack, 'TestCloudFront', {
        s3Bucket,
        cachingConfig,
        environment: 'dev',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      // Check that bucket policy is created
      template.hasResourceProperties('AWS::S3::BucketPolicy', {
        PolicyDocument: {
          Statement: Match.arrayWith([
            Match.objectLike({
              Sid: 'AllowCloudFrontServicePrincipal',
              Effect: 'Allow',
              Principal: {
                Service: 'cloudfront.amazonaws.com',
              },
              Action: 's3:GetObject',
            }),
          ]),
        },
      });
    });
  });

  describe('Construct Methods', () => {
    test('should provide distribution URL', () => {
      // Act
      const construct = new CloudFrontDistributionConstruct(stack, 'TestCloudFront', {
        s3Bucket,
        cachingConfig,
        environment: 'dev',
      });

      // Assert
      expect(construct.distributionUrl).toContain('https://');
    });

    test('should provide custom domain URL when configured', () => {
      // Arrange
      const domainName = 'test.example.com';

      // Act
      const construct = new CloudFrontDistributionConstruct(stack, 'TestCloudFront', {
        s3Bucket,
        cachingConfig,
        domainNames: [domainName],
        environment: 'dev',
      });

      // Assert
      expect(construct.getCustomDomainUrl(domainName)).toBe(`https://${domainName}`);
      expect(construct.getCustomDomainUrl()).toBeUndefined();
    });

    test('should provide cache invalidation command', () => {
      // Act
      const construct = new CloudFrontDistributionConstruct(stack, 'TestCloudFront', {
        s3Bucket,
        cachingConfig,
        environment: 'dev',
      });

      // Assert
      const invalidationCommand = construct.createInvalidation();
      expect(invalidationCommand).toContain('aws cloudfront create-invalidation');
      expect(invalidationCommand).toContain('--distribution-id');
      expect(invalidationCommand).toContain('--paths /*');

      const customInvalidationCommand = construct.createInvalidation(['/index.html', '/assets/*']);
      expect(customInvalidationCommand).toContain('--paths /index.html /assets/*');
    });
  });

  describe('Tagging', () => {
    test('should apply custom tags to distribution', () => {
      // Arrange
      const customTags = {
        Project: 'TestProject',
        Environment: 'test',
      };

      // Act
      const construct = new CloudFrontDistributionConstruct(stack, 'TestCloudFront', {
        s3Bucket,
        cachingConfig,
        environment: 'dev',
        tags: customTags,
      });

      // Assert
      // Tags are applied as metadata, verify they exist
      expect(construct.distribution.node.metadata).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ type: 'Project', data: 'TestProject' }),
          expect.objectContaining({ type: 'Environment', data: 'test' }),
          expect.objectContaining({ type: 'Component', data: 'CloudFrontDistribution' }),
          expect.objectContaining({ type: 'Purpose', data: 'FlutterWebHosting' }),
        ])
      );
    });
  });
});