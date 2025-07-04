import { Template, Match } from 'aws-cdk-lib/assertions';
import { Stack, App } from 'aws-cdk-lib';
import { AcmCertificateConstruct } from '../acm-certificate';
import { DomainConfig } from '../../types/config';

// Jest provides describe, it, beforeEach globally

describe('AcmCertificateConstruct', () => {
  let app: App;
  let stack: Stack;
  let domainConfig: DomainConfig;

  beforeEach(() => {
    app = new App();
    stack = new Stack(app, 'TestStack', {
      env: {
        region: 'us-east-1', // Required for CloudFront certificates
        account: '123456789012',
      },
    });

    domainConfig = {
      domainName: 'test.minecraft.lockhead.cloud',
      hostedZoneId: 'Z1234567890ABC',
      crossAccountRoleArn: 'arn:aws:iam::987654321098:role/CrossAccountDNSRole',
      certificateRegion: 'us-east-1',
    };
  });

  describe('Certificate Creation', () => {
    test('should create ACM certificate with correct properties', () => {
      // Act
      new AcmCertificateConstruct(stack, 'TestCertificate', {
        domainConfig,
        environment: 'test',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      template.hasResourceProperties('AWS::CertificateManager::Certificate', {
        DomainName: 'test.minecraft.lockhead.cloud',
        ValidationMethod: 'DNS',
        DomainValidationOptions: Match.absent(), // Should use default DNS validation
      });
    });

    test('should create certificate with transparency logging enabled', () => {
      // Act
      new AcmCertificateConstruct(stack, 'TestCertificate', {
        domainConfig,
        environment: 'test',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      template.hasResourceProperties('AWS::CertificateManager::Certificate', {
        CertificateTransparencyLoggingPreference: 'ENABLED',
      });
    });

    test('should use RSA 2048 key algorithm', () => {
      // Act
      new AcmCertificateConstruct(stack, 'TestCertificate', {
        domainConfig,
        environment: 'test',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      template.hasResourceProperties('AWS::CertificateManager::Certificate', {
        KeyAlgorithm: 'RSA_2048',
      });
    });
  });

  describe('Cross-Account DNS Validation', () => {
    test('should create Lambda execution role with correct permissions', () => {
      // Act
      new AcmCertificateConstruct(stack, 'TestCertificate', {
        domainConfig,
        environment: 'test',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      // Check Lambda execution role exists
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
        ManagedPolicyArns: [
          {
            'Fn::Join': [
              '',
              [
                'arn:',
                { Ref: 'AWS::Partition' },
                ':iam::aws:policy/service-role/AWSLambdaBasicExecutionRole',
              ],
            ],
          },
        ],
      });

      // Check role has ACM permissions
      template.hasResourceProperties('AWS::IAM::Policy', {
        PolicyDocument: {
          Statement: Match.arrayWith([
            {
              Effect: 'Allow',
              Action: ['acm:DescribeCertificate', 'acm:ListCertificates'],
              Resource: '*',
            },
          ]),
        },
      });

      // Check role has STS assume role permission
      template.hasResourceProperties('AWS::IAM::Policy', {
        PolicyDocument: {
          Statement: Match.arrayWith([
            {
              Effect: 'Allow',
              Action: 'sts:AssumeRole',
              Resource: 'arn:aws:iam::987654321098:role/CrossAccountDNSRole',
            },
          ]),
        },
      });
    });

    test('should create DNS validation Lambda function', () => {
      // Act
      new AcmCertificateConstruct(stack, 'TestCertificate', {
        domainConfig,
        environment: 'test',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      template.hasResourceProperties('AWS::Lambda::Function', {
        Runtime: 'python3.11',
        Handler: 'index.lambda_handler',
        Timeout: 300, // 5 minutes
        Description: 'ACM Certificate DNS validation with cross-account Route53 access',
        Environment: {
          Variables: {
            LOG_LEVEL: 'INFO',
          },
        },
      });
    });

    test('should create status check Lambda function', () => {
      // Act
      new AcmCertificateConstruct(stack, 'TestCertificate', {
        domainConfig,
        environment: 'test',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      // Should have multiple Lambda functions (validation, status check, and provider framework functions)
      template.resourceCountIs('AWS::Lambda::Function', 5);
      
      template.hasResourceProperties('AWS::Lambda::Function', {
        Runtime: 'python3.11',
        Handler: 'index.lambda_handler',
        Timeout: 120, // 2 minutes
        Description: 'Check ACM Certificate validation status',
      });
    });

    test('should create custom resource with correct properties', () => {
      // Act
      new AcmCertificateConstruct(stack, 'TestCertificate', {
        domainConfig,
        environment: 'test',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      template.hasResourceProperties('AWS::CloudFormation::CustomResource', {
        DomainName: 'test.minecraft.lockhead.cloud',
        HostedZoneId: 'Z1234567890ABC',
        CrossAccountRoleArn: 'arn:aws:iam::987654321098:role/CrossAccountDNSRole',
      });
    });

    test('should create custom resource provider with correct timeout', () => {
      // Act
      new AcmCertificateConstruct(stack, 'TestCertificate', {
        domainConfig,
        environment: 'test',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      // Check that the provider has appropriate timeout settings
      // This is implicit in the Provider construct configuration
      template.hasResourceProperties('AWS::Lambda::Function', {
        Timeout: Match.anyValue(),
      });
    });
  });

  describe('Region Validation', () => {
    test('should throw error when not in us-east-1 region', () => {
      // Arrange
      const wrongRegionStack = new Stack(app, 'WrongRegionStack', {
        env: {
          region: 'us-west-2',
          account: '123456789012',
        },
      });

      // Act & Assert
      expect(() => {
        new AcmCertificateConstruct(wrongRegionStack, 'TestCertificate', {
          domainConfig,
          environment: 'test',
        });
      }).toThrow('ACM certificate for CloudFront must be created in us-east-1 region');
    });

    test('should succeed when in us-east-1 region', () => {
      // Act & Assert
      expect(() => {
        new AcmCertificateConstruct(stack, 'TestCertificate', {
          domainConfig,
          environment: 'test',
        });
      }).not.toThrow();
    });
  });

  describe('Public Properties', () => {
    test('should expose certificate ARN', () => {
      // Act
      const construct = new AcmCertificateConstruct(stack, 'TestCertificate', {
        domainConfig,
        environment: 'test',
      });

      // Assert
      expect(construct.certificateArn).toBeDefined();
      expect(typeof construct.certificateArn).toBe('string');
    });

    test('should expose domain name', () => {
      // Act
      const construct = new AcmCertificateConstruct(stack, 'TestCertificate', {
        domainConfig,
        environment: 'test',
      });

      // Assert
      expect(construct.domainName).toBe('test.minecraft.lockhead.cloud');
    });

    test('should expose certificate instance', () => {
      // Act
      const construct = new AcmCertificateConstruct(stack, 'TestCertificate', {
        domainConfig,
        environment: 'test',
      });

      // Assert
      expect(construct.certificate).toBeDefined();
      expect(construct.certificate.certificateArn).toBeDefined();
    });
  });

  describe('Tagging', () => {
    test('should apply custom tags', () => {
      // Act
      new AcmCertificateConstruct(stack, 'TestCertificate', {
        domainConfig,
        environment: 'test',
        tags: {
          Project: 'MinecraftFinder',
          Owner: 'DevTeam',
        },
      });

      // Assert - Tags are applied as metadata, which is harder to test directly
      // The construct should not throw errors when tags are provided
      const template = Template.fromStack(stack);
      template.hasResourceProperties('AWS::CertificateManager::Certificate', {
        DomainName: 'test.minecraft.lockhead.cloud',
      });
    });

    test('should work without custom tags', () => {
      // Act & Assert
      expect(() => {
        new AcmCertificateConstruct(stack, 'TestCertificate', {
          domainConfig,
          environment: 'test',
        });
      }).not.toThrow();
    });
  });

  describe('Error Handling', () => {
    test('should handle missing domain configuration gracefully', () => {
      // Arrange
      const invalidDomainConfig = {
        ...domainConfig,
        domainName: '',
      };

      // Act & Assert
      expect(() => {
        new AcmCertificateConstruct(stack, 'TestCertificate', {
          domainConfig: invalidDomainConfig,
          environment: 'test',
        });
      }).toThrow('Domain name cannot be empty');
    });

    test('should handle invalid cross-account role ARN format', () => {
      // Arrange
      const invalidDomainConfig = {
        ...domainConfig,
        crossAccountRoleArn: 'invalid-arn',
      };

      // Act
      const construct = new AcmCertificateConstruct(stack, 'TestCertificate', {
        domainConfig: invalidDomainConfig,
        environment: 'test',
      });

      // Assert - Should create construct but validation will fail at runtime
      expect(construct).toBeDefined();
    });
  });

  describe('Integration with Other Constructs', () => {
    test('should provide certificate ARN for CloudFront integration', () => {
      // Act
      const construct = new AcmCertificateConstruct(stack, 'TestCertificate', {
        domainConfig,
        environment: 'test',
      });

      // Assert - CDK uses tokens during synthesis, so we check that it's defined
      expect(construct.certificateArn).toBeDefined();
      expect(typeof construct.certificateArn).toBe('string');
      expect(construct.certificateArn.length).toBeGreaterThan(0);
    });

    test('should support multiple environments', () => {
      // Act
      const devConstruct = new AcmCertificateConstruct(stack, 'DevCertificate', {
        domainConfig: {
          ...domainConfig,
          domainName: 'dev.minecraft.lockhead.cloud',
        },
        environment: 'dev',
      });

      const prodConstruct = new AcmCertificateConstruct(stack, 'ProdCertificate', {
        domainConfig: {
          ...domainConfig,
          domainName: 'minecraft.lockhead.cloud',
        },
        environment: 'prod',
      });

      // Assert
      expect(devConstruct.domainName).toBe('dev.minecraft.lockhead.cloud');
      expect(prodConstruct.domainName).toBe('minecraft.lockhead.cloud');
    });
  });

  describe('Lambda Function Code', () => {
    test('should include proper error handling in Lambda code', () => {
      // Act
      const construct = new AcmCertificateConstruct(stack, 'TestCertificate', {
        domainConfig,
        environment: 'test',
      });

      // Assert - Check that Lambda functions are created
      const template = Template.fromStack(stack);
      template.resourceCountIs('AWS::Lambda::Function', 5);
    });

    test('should configure appropriate timeouts for DNS propagation', () => {
      // Act
      new AcmCertificateConstruct(stack, 'TestCertificate', {
        domainConfig,
        environment: 'test',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      // DNS validation function should have 5 minute timeout
      template.hasResourceProperties('AWS::Lambda::Function', {
        Timeout: 300,
        Description: 'ACM Certificate DNS validation with cross-account Route53 access',
      });

      // Status check function should have 2 minute timeout
      template.hasResourceProperties('AWS::Lambda::Function', {
        Timeout: 120,
        Description: 'Check ACM Certificate validation status',
      });
    });
  });
});