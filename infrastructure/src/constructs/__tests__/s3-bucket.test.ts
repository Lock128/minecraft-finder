import { App, Stack } from 'aws-cdk-lib';
import { Template, Match } from 'aws-cdk-lib/assertions';
import * as iam from 'aws-cdk-lib/aws-iam';
import { S3BucketConstruct } from '../s3-bucket';
import { S3BucketConfig } from '../../types/config';

describe('S3BucketConstruct', () => {
  let app: App;
  let stack: Stack;
  let mockConfig: S3BucketConfig;

  beforeEach(() => {
    app = new App();
    stack = new Stack(app, 'TestStack');
    
    mockConfig = {
      bucketNamePrefix: 'test-bucket',
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
    };
  });

  describe('Bucket Creation', () => {
    test('creates S3 bucket with correct basic configuration', () => {
      // Arrange & Act
      const construct = new S3BucketConstruct(stack, 'TestS3Bucket', {
        config: mockConfig,
        environment: 'dev',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      // Verify bucket is created
      template.hasResourceProperties('AWS::S3::Bucket', {
        WebsiteConfiguration: {
          IndexDocument: 'index.html',
          ErrorDocument: 'index.html',
        },
        VersioningConfiguration: {
          Status: 'Enabled',
        },
        PublicAccessBlockConfiguration: {
          BlockPublicAcls: true,
          BlockPublicPolicy: true,
          IgnorePublicAcls: true,
          RestrictPublicBuckets: true,
        },
      });

      // Verify bucket name is generated correctly
      expect(construct.bucketName).toMatch(/^test-bucket-\d+$/);
    });

    test('creates bucket with versioning disabled when configured', () => {
      // Arrange
      const configWithoutVersioning = {
        ...mockConfig,
        versioning: false,
      };

      // Act
      new S3BucketConstruct(stack, 'TestS3Bucket', {
        config: configWithoutVersioning,
        environment: 'dev',
      });

      // Assert
      const template = Template.fromStack(stack);
      template.hasResourceProperties('AWS::S3::Bucket', {
        VersioningConfiguration: Match.absent(),
      });
    });

    test('applies correct removal policy for production environment', () => {
      // Arrange & Act
      new S3BucketConstruct(stack, 'TestS3Bucket', {
        config: mockConfig,
        environment: 'prod',
      });

      // Assert
      const template = Template.fromStack(stack);
      template.hasResource('AWS::S3::Bucket', {
        DeletionPolicy: 'Retain',
        UpdateReplacePolicy: 'Retain',
      });
    });

    test('applies correct removal policy for development environment', () => {
      // Arrange & Act
      new S3BucketConstruct(stack, 'TestS3Bucket', {
        config: mockConfig,
        environment: 'dev',
      });

      // Assert
      const template = Template.fromStack(stack);
      template.hasResource('AWS::S3::Bucket', {
        DeletionPolicy: 'Delete',
      });
    });
  });

  describe('Security Configuration', () => {
    test('blocks all public access by default', () => {
      // Arrange & Act
      new S3BucketConstruct(stack, 'TestS3Bucket', {
        config: mockConfig,
        environment: 'dev',
      });

      // Assert
      const template = Template.fromStack(stack);
      template.hasResourceProperties('AWS::S3::Bucket', {
        PublicAccessBlockConfiguration: {
          BlockPublicAcls: true,
          BlockPublicPolicy: true,
          IgnorePublicAcls: true,
          RestrictPublicBuckets: true,
        },
      });
    });

    test('enables S3 managed encryption', () => {
      // Arrange & Act
      new S3BucketConstruct(stack, 'TestS3Bucket', {
        config: mockConfig,
        environment: 'dev',
      });

      // Assert
      const template = Template.fromStack(stack);
      template.hasResourceProperties('AWS::S3::Bucket', {
        BucketEncryption: {
          ServerSideEncryptionConfiguration: [
            {
              ServerSideEncryptionByDefault: {
                SSEAlgorithm: 'AES256',
              },
            },
          ],
        },
      });
    });
  });

  describe('CORS Configuration', () => {
    test('configures CORS rules for web assets', () => {
      // Arrange & Act
      new S3BucketConstruct(stack, 'TestS3Bucket', {
        config: mockConfig,
        environment: 'dev',
      });

      // Assert
      const template = Template.fromStack(stack);
      template.hasResourceProperties('AWS::S3::Bucket', {
        CorsConfiguration: {
          CorsRules: [
            {
              AllowedOrigins: ['*'],
              AllowedMethods: ['GET', 'HEAD'],
              AllowedHeaders: Match.arrayWith([
                'Authorization',
                'Content-Length',
                'Content-Type',
                'Date',
                'ETag',
                'X-Amz-Date',
                'X-Amz-Security-Token',
                'X-Amz-User-Agent',
              ]),
              ExposedHeaders: ['ETag', 'Content-Length', 'Content-Type'],
              MaxAge: 3600,
            },
          ],
        },
      });
    });
  });

  describe('Lifecycle Rules', () => {
    test('creates lifecycle rules based on configuration', () => {
      // Arrange & Act
      new S3BucketConstruct(stack, 'TestS3Bucket', {
        config: mockConfig,
        environment: 'dev',
      });

      // Assert
      const template = Template.fromStack(stack);
      template.hasResourceProperties('AWS::S3::Bucket', {
        LifecycleConfiguration: {
          Rules: [
            {
              Id: 'TestRule',
              Status: 'Enabled',
              Transitions: [
                {
                  StorageClass: 'STANDARD_IA',
                  TransitionInDays: 30,
                },
              ],
              ExpirationInDays: 90,
              AbortIncompleteMultipartUpload: {
                DaysAfterInitiation: 7,
              },
            },
          ],
        },
      });
    });

    test('handles lifecycle rules without transitions', () => {
      // Arrange
      const configWithoutTransition = {
        ...mockConfig,
        lifecycleRules: [
          {
            id: 'SimpleRule',
            enabled: true,
            expirationDays: 30,
          },
        ],
      };

      // Act
      new S3BucketConstruct(stack, 'TestS3Bucket', {
        config: configWithoutTransition,
        environment: 'dev',
      });

      // Assert
      const template = Template.fromStack(stack);
      template.hasResourceProperties('AWS::S3::Bucket', {
        LifecycleConfiguration: {
          Rules: [
            {
              Id: 'SimpleRule',
              Status: 'Enabled',
              ExpirationInDays: 30,
              Transitions: Match.absent(),
            },
          ],
        },
      });
    });

    test('handles empty lifecycle rules', () => {
      // Arrange
      const configWithoutRules = {
        ...mockConfig,
        lifecycleRules: [],
      };

      // Act
      new S3BucketConstruct(stack, 'TestS3Bucket', {
        config: configWithoutRules,
        environment: 'dev',
      });

      // Assert
      const template = Template.fromStack(stack);
      template.hasResourceProperties('AWS::S3::Bucket', {
        LifecycleConfiguration: Match.absent(),
      });
    });
  });

  describe('CloudFront Integration', () => {
    test('creates CloudFront access policy with correct permissions', () => {
      // Arrange
      const construct = new S3BucketConstruct(stack, 'TestS3Bucket', {
        config: mockConfig,
        environment: 'dev',
      });
      const cloudFrontServicePrincipal = new iam.ServicePrincipal('cloudfront.amazonaws.com');

      // Act
      const policy = construct.createCloudFrontAccessPolicy(cloudFrontServicePrincipal);

      // Assert
      expect(policy.effect).toBe(iam.Effect.ALLOW);
      expect(policy.principals).toContain(cloudFrontServicePrincipal);
      expect(policy.actions).toContain('s3:GetObject');
      expect(policy.resources).toContain(`${construct.bucket.bucketArn}/*`);
    });

    test('provides correct domain names for CloudFront origin', () => {
      // Arrange & Act
      const construct = new S3BucketConstruct(stack, 'TestS3Bucket', {
        config: mockConfig,
        environment: 'dev',
      });

      // Assert
      expect(construct.bucketDomainName).toBeDefined();
      expect(construct.bucketRegionalDomainName).toBeDefined();
      expect(construct.websiteUrl).toBeDefined();
    });
  });

  describe('Tagging', () => {
    test('applies custom tags to bucket', () => {
      // Arrange
      const customTags = {
        Project: 'TestProject',
        Environment: 'test',
        Owner: 'TestTeam',
      };

      // Act
      const construct = new S3BucketConstruct(stack, 'TestS3Bucket', {
        config: mockConfig,
        environment: 'dev',
        tags: customTags,
      });

      // Assert
      // Verify tags are applied to the construct node
      Object.entries(customTags).forEach(([key, value]) => {
        expect(construct.bucket.node.metadata).toContainEqual(
          expect.objectContaining({ type: key, data: value })
        );
      });
    });

    test('applies default component tags', () => {
      // Arrange & Act
      const construct = new S3BucketConstruct(stack, 'TestS3Bucket', {
        config: mockConfig,
        environment: 'dev',
      });

      // Assert
      expect(construct.bucket.node.metadata).toContainEqual(
        expect.objectContaining({ type: 'Component', data: 'StaticWebsiteHosting' })
      );
      expect(construct.bucket.node.metadata).toContainEqual(
        expect.objectContaining({ type: 'Purpose', data: 'FlutterWebAssets' })
      );
    });
  });

  describe('Error Handling', () => {
    test('handles missing optional lifecycle rule properties', () => {
      // Arrange
      const configWithMinimalRule = {
        ...mockConfig,
        lifecycleRules: [
          {
            id: 'MinimalRule',
            enabled: true,
          },
        ],
      };

      // Act & Assert - should not throw
      expect(() => {
        new S3BucketConstruct(stack, 'TestS3Bucket', {
          config: configWithMinimalRule,
          environment: 'dev',
        });
      }).not.toThrow();
    });

    test('handles disabled lifecycle rules', () => {
      // Arrange
      const configWithDisabledRule = {
        ...mockConfig,
        lifecycleRules: [
          {
            id: 'DisabledRule',
            enabled: false,
            expirationDays: 30,
          },
        ],
      };

      // Act
      new S3BucketConstruct(stack, 'TestS3Bucket', {
        config: configWithDisabledRule,
        environment: 'dev',
      });

      // Assert
      const template = Template.fromStack(stack);
      template.hasResourceProperties('AWS::S3::Bucket', {
        LifecycleConfiguration: {
          Rules: [
            {
              Id: 'DisabledRule',
              Status: 'Disabled',
              ExpirationInDays: 30,
            },
          ],
        },
      });
    });
  });
});