import { SecurityConfig } from '../security-config';
import { App, Stack } from 'aws-cdk-lib';
import { Template, Match } from 'aws-cdk-lib/assertions';

describe('SecurityConfig', () => {
  let app: App;
  let stack: Stack;

  beforeEach(() => {
    app = new App();
    stack = new Stack(app, 'TestStack');
  });

  describe('validateSecurityConfig', () => {
    it('should pass validation with valid configuration', () => {
      const validConfig = {
        environment: 'prod',
        domainName: 'example.com',
        hostedZoneId: 'Z123456789',
      };

      expect(() => SecurityConfig.validateSecurityConfig(validConfig)).not.toThrow();
    });

    it('should fail validation with missing required fields', () => {
      const invalidConfig = {
        environment: 'prod',
        // Missing domainName and hostedZoneId
      };

      expect(() => SecurityConfig.validateSecurityConfig(invalidConfig))
        .toThrow('Security validation failed: Missing required field \'domainName\'');
    });

    it('should fail validation with invalid domain name', () => {
      const invalidConfig = {
        environment: 'prod',
        domainName: 'invalid-domain',
        hostedZoneId: 'Z123456789',
      };

      expect(() => SecurityConfig.validateSecurityConfig(invalidConfig))
        .toThrow('Security validation failed: Invalid domain name format');
    });

    it('should fail validation with invalid environment', () => {
      const invalidConfig = {
        environment: 'invalid',
        domainName: 'example.com',
        hostedZoneId: 'Z123456789',
      };

      expect(() => SecurityConfig.validateSecurityConfig(invalidConfig))
        .toThrow('Security validation failed: Invalid environment. Must be dev, staging, or prod');
    });

    it('should warn about missing KMS configuration in production', () => {
      const prodConfig = {
        environment: 'prod',
        domainName: 'example.com',
        hostedZoneId: 'Z123456789',
      };

      const consoleSpy = jest.spyOn(console, 'warn').mockImplementation();
      SecurityConfig.validateSecurityConfig(prodConfig);
      
      expect(consoleSpy).toHaveBeenCalledWith(
        'Warning: Production environment should use KMS encryption'
      );
      
      consoleSpy.mockRestore();
    });
  });

  describe('createGitHubActionsRole', () => {
    it('should create IAM role with correct trust policy', () => {
      const role = SecurityConfig.createGitHubActionsRole(stack, 'dev');
      const template = Template.fromStack(stack);

      template.hasResourceProperties('AWS::IAM::Role', {
        RoleName: 'github-actions-web-hosting-dev',
        AssumeRolePolicyDocument: {
          Statement: [
            {
              Effect: 'Allow',
              Principal: {
                Federated: 'arn:aws:iam::*:oidc-provider/token.actions.githubusercontent.com'
              },
              Action: 'sts:AssumeRoleWithWebIdentity',
              Condition: {
                StringEquals: {
                  'token.actions.githubusercontent.com:aud': 'sts.amazonaws.com'
                },
                StringLike: {
                  'token.actions.githubusercontent.com:sub': 'repo:*:ref:refs/heads/main'
                }
              }
            }
          ]
        }
      });
    });

    it('should create role with minimal required policies', () => {
      const role = SecurityConfig.createGitHubActionsRole(stack, 'dev');
      const template = Template.fromStack(stack);

      template.hasResourceProperties('AWS::IAM::Role', {
        Policies: [
          {
            PolicyName: 'CDKDeploymentPolicy'
          },
          {
            PolicyName: 'S3AssetUploadPolicy'
          },
          {
            PolicyName: 'CloudFrontInvalidationPolicy'
          }
        ]
      });
    });

    it('should set maximum session duration', () => {
      const role = SecurityConfig.createGitHubActionsRole(stack, 'dev');
      const template = Template.fromStack(stack);

      template.hasResourceProperties('AWS::IAM::Role', {
        MaxSessionDuration: 7200 // 2 hours
      });
    });
  });

  describe('createCrossAccountDNSRole', () => {
    it('should create cross-account role with correct trust policy', () => {
      const trustedAccountId = '123456789012';
      const role = SecurityConfig.createCrossAccountDNSRole(stack, trustedAccountId);
      const template = Template.fromStack(stack);

      template.hasResourceProperties('AWS::IAM::Role', {
        RoleName: 'web-hosting-dns-management',
        AssumeRolePolicyDocument: {
          Statement: Match.arrayWith([
            Match.objectLike({
              Effect: 'Allow',
              Action: 'sts:AssumeRole',
              Condition: {
                StringEquals: {
                  'sts:ExternalId': 'web-hosting-dns-2024'
                }
              }
            })
          ])
        }
      });
    });

    it('should have minimal Route53 permissions', () => {
      const trustedAccountId = '123456789012';
      const role = SecurityConfig.createCrossAccountDNSRole(stack, trustedAccountId);
      const template = Template.fromStack(stack);

      template.hasResourceProperties('AWS::IAM::Role', {
        Policies: [
          {
            PolicyName: 'Route53Access',
            PolicyDocument: {
              Statement: [
                {
                  Sid: 'Route53RecordManagement',
                  Effect: 'Allow',
                  Action: [
                    'route53:GetHostedZone',
                    'route53:ListResourceRecordSets',
                    'route53:ChangeResourceRecordSets'
                  ],
                  Resource: 'arn:aws:route53:::hostedzone/*'
                },
                {
                  Sid: 'Route53ChangeInfo',
                  Effect: 'Allow',
                  Action: 'route53:GetChange',
                  Resource: 'arn:aws:route53:::change/*'
                }
              ]
            }
          }
        ]
      });
    });
  });

  describe('getSecurityHeaders', () => {
    it('should return base security headers for all content types', () => {
      const headers = SecurityConfig.getSecurityHeaders('text/plain');
      
      expect(headers).toHaveProperty('X-Content-Type-Options', 'nosniff');
      expect(headers).toHaveProperty('X-Frame-Options', 'DENY');
      expect(headers).toHaveProperty('X-XSS-Protection', '1; mode=block');
      expect(headers).toHaveProperty('Referrer-Policy', 'strict-origin-when-cross-origin');
      expect(headers).toHaveProperty('Strict-Transport-Security');
    });

    it('should include CSP for HTML content', () => {
      const headers = SecurityConfig.getSecurityHeaders('text/html');
      
      expect(headers).toHaveProperty('Content-Security-Policy');
      expect(headers).toHaveProperty('Permissions-Policy');
      expect(headers['Content-Security-Policy']).toContain("default-src 'self'");
    });

    it('should include cache headers for JavaScript', () => {
      const headers = SecurityConfig.getSecurityHeaders('application/javascript');
      
      expect(headers).toHaveProperty('Cache-Control', 'public, max-age=31536000, immutable');
    });

    it('should include cache headers for CSS', () => {
      const headers = SecurityConfig.getSecurityHeaders('text/css');
      
      expect(headers).toHaveProperty('Cache-Control', 'public, max-age=31536000, immutable');
    });
  });

  describe('createSecurityMonitoringPolicies', () => {
    it('should create policies for security monitoring', () => {
      const policies = SecurityConfig.createSecurityMonitoringPolicies();
      
      expect(policies.statementCount).toBeGreaterThan(0);
      
      const statements = policies.toJSON().Statement;
      expect(statements).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            Sid: 'SecurityLogsAccess',
            Effect: 'Allow',
            Action: expect.arrayContaining([
              'logs:CreateLogGroup',
              'logs:CreateLogStream',
              'logs:PutLogEvents'
            ])
          }),
          expect.objectContaining({
            Sid: 'SecurityMetricsAccess',
            Effect: 'Allow',
            Action: expect.arrayContaining([
              'cloudwatch:PutMetricData',
              'cloudwatch:GetMetricStatistics'
            ])
          })
        ])
      );
    });
  });

  describe('Content Security Policy', () => {
    it('should generate secure CSP for Flutter apps', () => {
      const headers = SecurityConfig.getSecurityHeaders('text/html');
      const csp = headers['Content-Security-Policy'];
      
      // Check for essential CSP directives
      expect(csp).toContain("default-src 'self'");
      expect(csp).toContain("object-src 'none'");
      expect(csp).toContain("frame-ancestors 'none'");
      expect(csp).toContain("upgrade-insecure-requests");
      expect(csp).toContain("block-all-mixed-content");
      
      // Check Flutter-specific allowances
      expect(csp).toContain("script-src 'self' 'unsafe-inline' 'unsafe-eval' blob:");
      expect(csp).toContain("style-src 'self' 'unsafe-inline'");
      expect(csp).toContain("worker-src 'self' blob:");
    });

    it('should provide secure CSP for Flutter web apps', () => {
      const headers = SecurityConfig.getSecurityHeaders('text/html');
      const csp = headers['Content-Security-Policy'];
      
      // Should contain Flutter-specific but controlled directives
      expect(csp).toContain("default-src 'self'"); // Restrictive default
      expect(csp).toContain("object-src 'none'"); // Block objects
      expect(csp).toContain("frame-ancestors 'none'"); // Prevent framing
      expect(csp).not.toContain("*"); // No wildcard sources in main directives
    });
  });

  describe('Security validation edge cases', () => {
    it('should handle null/undefined configuration gracefully', () => {
      expect(() => SecurityConfig.validateSecurityConfig(null as any))
        .toThrow('Security validation failed: Configuration is null or undefined');
      
      expect(() => SecurityConfig.validateSecurityConfig(undefined as any))
        .toThrow('Security validation failed: Configuration is null or undefined');
    });

    it('should validate complex domain names correctly', () => {
      const validDomains = [
        'example.com',
        'sub.example.com',
        'app-name.example.co.uk',
        'test123.example.org'
      ];

      const invalidDomains = [
        'invalid',
        '.example.com',
        'example.',
        'ex ample.com',
        'example..com'
      ];

      validDomains.forEach(domain => {
        const config = {
          environment: 'dev',
          domainName: domain,
          hostedZoneId: 'Z123456789'
        };
        expect(() => SecurityConfig.validateSecurityConfig(config)).not.toThrow();
      });

      invalidDomains.forEach(domain => {
        const config = {
          environment: 'dev',
          domainName: domain,
          hostedZoneId: 'Z123456789'
        };
        expect(() => SecurityConfig.validateSecurityConfig(config))
          .toThrow('Invalid domain name format');
      });
    });
  });
});