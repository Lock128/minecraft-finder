import { App, Stack } from 'aws-cdk-lib';
import { Template, Match } from 'aws-cdk-lib/assertions';
import { DnsManagementConstruct } from '../dns-management';
import { DomainConfig } from '../../types/config';

describe('DnsManagementConstruct', () => {
  let app: App;
  let stack: Stack;
  let domainConfig: DomainConfig;

  beforeEach(() => {
    app = new App();
    stack = new Stack(app, 'TestStack', {
      env: { account: '123456789012', region: 'us-east-1' }
    });

    domainConfig = {
      domainName: 'app.minecraft.lockhead.cloud',
      hostedZoneId: 'Z1234567890ABC',
      crossAccountRoleArn: 'arn:aws:iam::987654321098:role/CrossAccountDNSRole',
      certificateRegion: 'us-east-1'
    };
  });

  describe('Constructor', () => {
    it('should create DNS management construct with valid configuration', () => {
      const construct = new DnsManagementConstruct(stack, 'DnsManagement', {
        domainConfig,
        cloudFrontDomainName: 'd123456789.cloudfront.net',
        environment: 'test'
      });

      expect(construct.domainName).toBe('app.minecraft.lockhead.cloud');
      expect(construct.cloudFrontDomainName).toBe('d123456789.cloudfront.net');
      expect(construct.hostedZoneId).toBe('Z1234567890ABC');
    });

    it('should apply tags correctly', () => {
      const tags = {
        Environment: 'test',
        Project: 'minecraft-finder'
      };

      new DnsManagementConstruct(stack, 'DnsManagement', {
        domainConfig,
        cloudFrontDomainName: 'd123456789.cloudfront.net',
        environment: 'test',
        tags
      });

      const template = Template.fromStack(stack);
      
      // Verify that the custom resource exists
      template.hasResourceProperties('AWS::CloudFormation::CustomResource', {
        ServiceToken: Match.anyValue()
      });
    });
  });

  describe('Input Validation', () => {
    it('should throw error for empty domain name', () => {
      const invalidConfig = { ...domainConfig, domainName: '' };

      expect(() => {
        new DnsManagementConstruct(stack, 'DnsManagement', {
          domainConfig: invalidConfig,
          cloudFrontDomainName: 'd123456789.cloudfront.net',
          environment: 'test'
        });
      }).toThrow('Domain name cannot be empty');
    });

    it('should throw error for empty CloudFront domain name', () => {
      expect(() => {
        new DnsManagementConstruct(stack, 'DnsManagement', {
          domainConfig,
          cloudFrontDomainName: '',
          environment: 'test'
        });
      }).toThrow('CloudFront domain name cannot be empty');
    });

    it('should throw error for empty hosted zone ID', () => {
      const invalidConfig = { ...domainConfig, hostedZoneId: '' };

      expect(() => {
        new DnsManagementConstruct(stack, 'DnsManagement', {
          domainConfig: invalidConfig,
          cloudFrontDomainName: 'd123456789.cloudfront.net',
          environment: 'test'
        });
      }).toThrow('Hosted zone ID cannot be empty');
    });

    it('should throw error for empty cross-account role ARN', () => {
      const invalidConfig = { ...domainConfig, crossAccountRoleArn: '' };

      expect(() => {
        new DnsManagementConstruct(stack, 'DnsManagement', {
          domainConfig: invalidConfig,
          cloudFrontDomainName: 'd123456789.cloudfront.net',
          environment: 'test'
        });
      }).toThrow('Cross-account role ARN cannot be empty');
    });

    it('should throw error for invalid domain name format', () => {
      const invalidConfig = { ...domainConfig, domainName: 'invalid..domain' };

      expect(() => {
        new DnsManagementConstruct(stack, 'DnsManagement', {
          domainConfig: invalidConfig,
          cloudFrontDomainName: 'd123456789.cloudfront.net',
          environment: 'test'
        });
      }).toThrow('Invalid domain name format');
    });

    it('should throw error for invalid CloudFront domain name format', () => {
      expect(() => {
        new DnsManagementConstruct(stack, 'DnsManagement', {
          domainConfig,
          cloudFrontDomainName: 'invalid-cloudfront-domain.com',
          environment: 'test'
        });
      }).toThrow('Invalid CloudFront domain name format');
    });

    it('should throw error for invalid hosted zone ID format', () => {
      const invalidConfig = { ...domainConfig, hostedZoneId: 'invalid-zone-id' };

      expect(() => {
        new DnsManagementConstruct(stack, 'DnsManagement', {
          domainConfig: invalidConfig,
          cloudFrontDomainName: 'd123456789.cloudfront.net',
          environment: 'test'
        });
      }).toThrow('Invalid hosted zone ID format');
    });

    it('should throw error for invalid cross-account role ARN format', () => {
      const invalidConfig = { ...domainConfig, crossAccountRoleArn: 'invalid-arn' };

      expect(() => {
        new DnsManagementConstruct(stack, 'DnsManagement', {
          domainConfig: invalidConfig,
          cloudFrontDomainName: 'd123456789.cloudfront.net',
          environment: 'test'
        });
      }).toThrow('Invalid cross-account role ARN format');
    });

    it('should accept valid domain name formats', () => {
      const validDomains = [
        'app.minecraft.lockhead.cloud',
        'test.example.com',
        'subdomain.domain.co.uk',
        'a.b.c.d.example.org'
      ];

      validDomains.forEach((domain, index) => {
        const testConfig = { ...domainConfig, domainName: domain };
        
        expect(() => {
          new DnsManagementConstruct(stack, `DnsManagement${index}`, {
            domainConfig: testConfig,
            cloudFrontDomainName: 'd123456789.cloudfront.net',
            environment: 'test'
          });
        }).not.toThrow();
      });
    });

    it('should accept valid CloudFront domain name formats', () => {
      const validCloudFrontDomains = [
        'd123456789.cloudfront.net',
        'dabcdef123.cloudfront.net',
        'd1a2b3c4d5e6f7.cloudfront.net'
      ];

      validCloudFrontDomains.forEach((cfDomain, index) => {
        expect(() => {
          new DnsManagementConstruct(stack, `DnsManagement${index}`, {
            domainConfig,
            cloudFrontDomainName: cfDomain,
            environment: 'test'
          });
        }).not.toThrow();
      });
    });
  });

  describe('AWS Resources', () => {
    let construct: DnsManagementConstruct;

    beforeEach(() => {
      construct = new DnsManagementConstruct(stack, 'DnsManagement', {
        domainConfig,
        cloudFrontDomainName: 'd123456789.cloudfront.net',
        environment: 'test'
      });
    });

    it('should create Lambda execution role with correct permissions', () => {
      const template = Template.fromStack(stack);

      template.hasResourceProperties('AWS::IAM::Role', {
        AssumeRolePolicyDocument: {
          Statement: [
            {
              Action: 'sts:AssumeRole',
              Effect: 'Allow',
              Principal: {
                Service: 'lambda.amazonaws.com'
              }
            }
          ]
        },
        ManagedPolicyArns: [
          {
            'Fn::Join': [
              '',
              [
                'arn:',
                { Ref: 'AWS::Partition' },
                ':iam::aws:policy/service-role/AWSLambdaBasicExecutionRole'
              ]
            ]
          }
        ]
      });

      // Check for cross-account role assumption policy
      template.hasResourceProperties('AWS::IAM::Policy', {
        PolicyDocument: {
          Statement: [
            {
              Action: 'sts:AssumeRole',
              Effect: 'Allow',
              Resource: 'arn:aws:iam::987654321098:role/CrossAccountDNSRole'
            }
          ]
        }
      });
    });

    it('should create Lambda function with correct configuration', () => {
      const template = Template.fromStack(stack);

      template.hasResourceProperties('AWS::Lambda::Function', {
        Runtime: 'python3.11',
        Handler: 'index.lambda_handler',
        Timeout: 300,
        Description: 'DNS management with cross-account Route53 access',
        Environment: {
          Variables: {
            LOG_LEVEL: 'INFO'
          }
        }
      });
    });

    it('should create custom resource with correct properties', () => {
      const template = Template.fromStack(stack);

      template.hasResourceProperties('AWS::CloudFormation::CustomResource', {
        DomainName: 'app.minecraft.lockhead.cloud',
        CloudFrontDomainName: 'd123456789.cloudfront.net',
        HostedZoneId: 'Z1234567890ABC',
        CrossAccountRoleArn: 'arn:aws:iam::987654321098:role/CrossAccountDNSRole',
        Timestamp: Match.anyValue()
      });
    });

    it('should create custom resource provider', () => {
      const template = Template.fromStack(stack);

      // The provider creates a Lambda function for the framework
      template.hasResourceProperties('AWS::Lambda::Function', {
        Description: Match.stringLikeRegexp('.*Provider.*')
      });
    });
  });

  describe('Public Methods', () => {
    let construct: DnsManagementConstruct;

    beforeEach(() => {
      construct = new DnsManagementConstruct(stack, 'DnsManagement', {
        domainConfig,
        cloudFrontDomainName: 'd123456789.cloudfront.net',
        environment: 'test'
      });
    });

    it('should return correct DNS record information', () => {
      const recordInfo = construct.getDnsRecordInfo();

      expect(recordInfo).toEqual({
        domainName: 'app.minecraft.lockhead.cloud',
        target: 'd123456789.cloudfront.net',
        type: 'CNAME'
      });
    });

    it('should return correct hosted zone ID', () => {
      const hostedZoneId = construct.getHostedZoneId();
      expect(hostedZoneId).toBe('Z1234567890ABC');
    });

    it('should validate DNS configuration correctly', () => {
      const isValid = construct.validateDnsConfiguration();
      expect(isValid).toBe(true);
    });

    it('should return public properties correctly', () => {
      expect(construct.domainName).toBe('app.minecraft.lockhead.cloud');
      expect(construct.cloudFrontDomainName).toBe('d123456789.cloudfront.net');
      expect(construct.hostedZoneId).toBe('Z1234567890ABC');
    });
  });

  describe('Error Handling', () => {
    it('should handle whitespace-only inputs', () => {
      const invalidConfig = { ...domainConfig, domainName: '   ' };

      expect(() => {
        new DnsManagementConstruct(stack, 'DnsManagement', {
          domainConfig: invalidConfig,
          cloudFrontDomainName: 'd123456789.cloudfront.net',
          environment: 'test'
        });
      }).toThrow('Domain name cannot be empty');
    });

    it('should handle null/undefined inputs gracefully', () => {
      expect(() => {
        new DnsManagementConstruct(stack, 'DnsManagement', {
          domainConfig: { ...domainConfig, domainName: null as any },
          cloudFrontDomainName: 'd123456789.cloudfront.net',
          environment: 'test'
        });
      }).toThrow();

      expect(() => {
        new DnsManagementConstruct(stack, 'DnsManagement', {
          domainConfig,
          cloudFrontDomainName: undefined as any,
          environment: 'test'
        });
      }).toThrow();
    });
  });

  describe('Integration with Other Constructs', () => {
    it('should work with different environment configurations', () => {
      const environments = ['dev', 'staging', 'prod'];

      environments.forEach((env, index) => {
        expect(() => {
          new DnsManagementConstruct(stack, `DnsManagement${env}`, {
            domainConfig: {
              ...domainConfig,
              domainName: `${env}.minecraft.lockhead.cloud`
            },
            cloudFrontDomainName: `d${index}23456789.cloudfront.net`,
            environment: env
          });
        }).not.toThrow();
      });
    });

    it('should handle different AWS regions correctly', () => {
      const regions = ['us-east-1', 'us-west-2', 'eu-west-1'];

      regions.forEach((region, index) => {
        const regionStack = new Stack(app, `TestStack${region}`, {
          env: { account: '123456789012', region }
        });

        expect(() => {
          new DnsManagementConstruct(regionStack, 'DnsManagement', {
            domainConfig,
            cloudFrontDomainName: `d${index}23456789.cloudfront.net`,
            environment: 'test'
          });
        }).not.toThrow();
      });
    });
  });

  describe('Lambda Function Code', () => {
    it('should include comprehensive error handling in Lambda code', () => {
      const construct = new DnsManagementConstruct(stack, 'DnsManagement', {
        domainConfig,
        cloudFrontDomainName: 'd123456789.cloudfront.net',
        environment: 'test'
      });

      const template = Template.fromStack(stack);
      
      // Get the Lambda function code
      const lambdaResources = template.findResources('AWS::Lambda::Function');
      const dnsManagementFunction = Object.values(lambdaResources).find(
        (resource: any) => resource.Properties.Description === 'DNS management with cross-account Route53 access'
      );

      expect(dnsManagementFunction).toBeDefined();
      
      const code = dnsManagementFunction?.Properties.Code.ZipFile;
      expect(code).toContain('handle_create_update');
      expect(code).toContain('handle_delete');
      expect(code).toContain('assume_cross_account_role');
      expect(code).toContain('validate_hosted_zone');
      expect(code).toContain('wait_for_dns_change');
      expect(code).toContain('verify_dns_record');
    });

    it('should include proper error messages in Lambda code', () => {
      const construct = new DnsManagementConstruct(stack, 'DnsManagement', {
        domainConfig,
        cloudFrontDomainName: 'd123456789.cloudfront.net',
        environment: 'test'
      });

      const template = Template.fromStack(stack);
      const lambdaResources = template.findResources('AWS::Lambda::Function');
      const dnsManagementFunction = Object.values(lambdaResources).find(
        (resource: any) => resource.Properties.Description === 'DNS management with cross-account Route53 access'
      );

      const code = dnsManagementFunction?.Properties.Code.ZipFile;
      expect(code).toContain('Access denied when assuming role');
      expect(code).toContain('Cross-account role not found');
      expect(code).toContain('Hosted zone');
      expect(code).toContain('not found');
      expect(code).toContain('DNS change');
      expect(code).toContain('did not complete');
    });
  });
});