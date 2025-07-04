import { App, Stack } from 'aws-cdk-lib';
import { Template, Match } from 'aws-cdk-lib/assertions';
import { CloudWatchRumConstruct } from '../cloudwatch-rum';
import { MonitoringConfig } from '../../types/config';

// Jest provides describe, it, beforeEach globally

describe('CloudWatchRumConstruct', () => {
  let app: App;
  let stack: Stack;
  let mockConfig: MonitoringConfig;

  beforeEach(() => {
    app = new App();
    stack = new Stack(app, 'TestStack', {
      env: {
        account: '123456789012',
        region: 'us-east-1',
      },
    });

    mockConfig = {
      rumAppName: 'minecraft-ore-finder',
      samplingRate: 0.1,
      enabledMetrics: ['http', 'navigation', 'interaction'],
      enableExtendedMetrics: true,
    };
  });

  describe('Basic Construction', () => {
    test('creates RUM app monitor with correct configuration', () => {
      // Arrange & Act
      const rumConstruct = new CloudWatchRumConstruct(stack, 'TestRum', {
        config: mockConfig,
        environment: 'dev',
        domainName: 'test.minecraft.lockhead.cloud',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      template.hasResourceProperties('AWS::RUM::AppMonitor', {
        Name: 'minecraft-ore-finder-dev',
        Domain: 'test.minecraft.lockhead.cloud',
        AppMonitorConfiguration: {
          AllowCookies: true,
          EnableXRay: true,
          ExcludedPages: [],
          FavoritePages: ['/'],
          SessionSampleRate: 0.1,
          Telemetries: Match.arrayWith(['errors', 'performance', 'http', 'navigation', 'interaction']),
        },
        CustomEvents: {
          Status: 'ENABLED',
        },
        CwLogEnabled: true,
      });

      expect(rumConstruct.rumAppName).toBe('minecraft-ore-finder-dev');
      expect(rumConstruct.rumAppId).toBeDefined();
    });

    test('creates guest role with correct permissions', () => {
      // Arrange & Act
      new CloudWatchRumConstruct(stack, 'TestRum', {
        config: mockConfig,
        environment: 'dev',
        domainName: 'test.minecraft.lockhead.cloud',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      template.hasResourceProperties('AWS::IAM::Role', {
        AssumeRolePolicyDocument: {
          Statement: [
            {
              Effect: 'Allow',
              Principal: {
                Service: 'rum.amazonaws.com',
              },
              Action: 'sts:AssumeRole',
            },
          ],
        },
        Policies: [
          {
            PolicyName: 'RumGuestPolicy',
            PolicyDocument: {
              Statement: [
                {
                  Effect: 'Allow',
                  Action: 'rum:PutRumEvents',
                  Resource: '*',
                },
              ],
            },
          },
        ],
      });
    });

    test('applies correct tags', () => {
      // Arrange
      const customTags = {
        Project: 'MinecraftOreFinder',
        Owner: 'DevTeam',
      };

      // Act
      new CloudWatchRumConstruct(stack, 'TestRum', {
        config: mockConfig,
        environment: 'prod',
        domainName: 'minecraft.lockhead.cloud',
        tags: customTags,
      });

      // Assert
      const template = Template.fromStack(stack);
      
      // Check that required tags are present
      template.hasResourceProperties('AWS::RUM::AppMonitor', {
        Tags: Match.arrayWith([
          { Key: 'Component', Value: 'Monitoring' },
          { Key: 'Purpose', Value: 'RealUserMonitoring' },
          { Key: 'Service', Value: 'CloudWatchRUM' },
        ]),
      });
      
      // Check that custom tags are also present
      const resources = template.findResources('AWS::RUM::AppMonitor');
      const rumResource = Object.values(resources)[0] as any;
      const tags = rumResource.Properties.Tags;
      
      expect(tags).toEqual(expect.arrayContaining([
        { Key: 'Environment', Value: 'prod' },
        { Key: 'Project', Value: 'MinecraftOreFinder' },
        { Key: 'Owner', Value: 'DevTeam' },
      ]));
    });
  });

  describe('Configuration Variations', () => {
    test('handles minimal configuration', () => {
      // Arrange
      const minimalConfig: MonitoringConfig = {
        rumAppName: 'minimal-app',
        samplingRate: 0.05,
        enabledMetrics: [],
        enableExtendedMetrics: false,
      };

      // Act
      new CloudWatchRumConstruct(stack, 'TestRum', {
        config: minimalConfig,
        environment: 'dev',
        domainName: 'test.example.com',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      template.hasResourceProperties('AWS::RUM::AppMonitor', {
        Name: 'minimal-app-dev',
        AppMonitorConfiguration: {
          SessionSampleRate: 0.05,
          Telemetries: ['errors', 'performance'], // Always includes these
        },
      });
    });

    test('handles extended metrics disabled', () => {
      // Arrange
      const configWithoutExtended: MonitoringConfig = {
        rumAppName: 'basic-app',
        samplingRate: 0.2,
        enabledMetrics: ['http', 'navigation', 'interaction'],
        enableExtendedMetrics: false,
      };

      // Act
      new CloudWatchRumConstruct(stack, 'TestRum', {
        config: configWithoutExtended,
        environment: 'staging',
        domainName: 'staging.example.com',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      template.hasResourceProperties('AWS::RUM::AppMonitor', {
        AppMonitorConfiguration: {
          Telemetries: ['errors', 'performance', 'http'], // No navigation/interaction without extended
        },
      });
    });

    test('handles different environments', () => {
      // Test dev environment
      const devStack = new Stack(new App(), 'DevStack', {
        env: { account: '123456789012', region: 'us-east-1' },
      });

      new CloudWatchRumConstruct(devStack, 'TestRum', {
        config: mockConfig,
        environment: 'dev',
        domainName: 'dev.example.com',
      });

      const devTemplate = Template.fromStack(devStack);
      devTemplate.hasResourceProperties('AWS::RUM::AppMonitor', {
        Name: 'minecraft-ore-finder-dev',
        Domain: 'dev.example.com',
      });

      // Test prod environment
      const prodStack = new Stack(new App(), 'ProdStack', {
        env: { account: '123456789012', region: 'us-east-1' },
      });

      new CloudWatchRumConstruct(prodStack, 'TestRum', {
        config: mockConfig,
        environment: 'prod',
        domainName: 'prod.example.com',
      });

      const prodTemplate = Template.fromStack(prodStack);
      prodTemplate.hasResourceProperties('AWS::RUM::AppMonitor', {
        Name: 'minecraft-ore-finder-prod',
        Domain: 'prod.example.com',
      });
    });
  });

  describe('Client Configuration', () => {
    test('generates correct RUM client configuration', () => {
      // Arrange
      const rumConstruct = new CloudWatchRumConstruct(stack, 'TestRum', {
        config: mockConfig,
        environment: 'dev',
        domainName: 'test.minecraft.lockhead.cloud',
      });

      // Act
      const clientConfig = rumConstruct.getRumClientConfig();

      // Assert
      expect(clientConfig.applicationId).toBeDefined();
      expect(clientConfig.applicationVersion).toBe('1.0.0');
      expect(clientConfig.applicationRegion).toBe('us-east-1');
      expect(clientConfig.sessionSampleRate).toBe(0.1);
      expect(clientConfig.guestRoleArn).toBeDefined();
      expect(clientConfig.enableXRay).toBe(true);
      expect(clientConfig.allowCookies).toBe(true);
    });

    test('generates valid initialization script', () => {
      // Arrange
      const rumConstruct = new CloudWatchRumConstruct(stack, 'TestRum', {
        config: mockConfig,
        environment: 'prod',
        domainName: 'minecraft.lockhead.cloud',
      });

      // Act
      const script = rumConstruct.getRumInitializationScript();

      // Assert
      expect(script).toContain('window.AwsRumClient');
      expect(script).toContain('sessionSampleRate: 0.1');
      expect(script).toContain('enableXRay: true');
      expect(script).toContain('allowCookies: true');
      expect(script).toContain('rum.us-east-1.amazonaws.com');
      expect(script).toContain("telemetries: ['performance','errors','http']");
    });
  });

  describe('Properties and Methods', () => {
    test('exposes correct properties', () => {
      // Arrange & Act
      const rumConstruct = new CloudWatchRumConstruct(stack, 'TestRum', {
        config: mockConfig,
        environment: 'dev',
        domainName: 'test.minecraft.lockhead.cloud',
      });

      // Assert
      expect(rumConstruct.rumAppName).toBe('minecraft-ore-finder-dev');
      expect(rumConstruct.applicationName).toBe('minecraft-ore-finder-dev');
      expect(rumConstruct.rumAppId).toBeDefined();
      expect(rumConstruct.rumAppArn).toBeDefined();
    });

    test('handles different sampling rates', () => {
      // Test low sampling rate
      const lowRateStack = new Stack(new App(), 'LowRateStack', {
        env: { account: '123456789012', region: 'us-east-1' },
      });

      const lowRateConfig: MonitoringConfig = {
        ...mockConfig,
        samplingRate: 0.01,
      };

      const lowRateConstruct = new CloudWatchRumConstruct(lowRateStack, 'TestRum', {
        config: lowRateConfig,
        environment: 'dev',
        domainName: 'test.example.com',
      });

      const lowRateTemplate = Template.fromStack(lowRateStack);
      lowRateTemplate.hasResourceProperties('AWS::RUM::AppMonitor', {
        AppMonitorConfiguration: {
          SessionSampleRate: 0.01,
        },
      });

      const lowRateClientConfig = lowRateConstruct.getRumClientConfig();
      expect(lowRateClientConfig.sessionSampleRate).toBe(0.01);

      // Test high sampling rate
      const highRateStack = new Stack(new App(), 'HighRateStack', {
        env: { account: '123456789012', region: 'us-east-1' },
      });

      const highRateConfig: MonitoringConfig = {
        ...mockConfig,
        samplingRate: 1.0,
      };

      const highRateConstruct = new CloudWatchRumConstruct(highRateStack, 'TestRum', {
        config: highRateConfig,
        environment: 'dev',
        domainName: 'test.example.com',
      });

      const highRateTemplate = Template.fromStack(highRateStack);
      highRateTemplate.hasResourceProperties('AWS::RUM::AppMonitor', {
        AppMonitorConfiguration: {
          SessionSampleRate: 1.0,
        },
      });

      const highRateClientConfig = highRateConstruct.getRumClientConfig();
      expect(highRateClientConfig.sessionSampleRate).toBe(1.0);
    });
  });

  describe('Cost Optimization', () => {
    test('applies cost optimization settings', () => {
      // Arrange
      const costOptimizedConfig: MonitoringConfig = {
        rumAppName: 'cost-optimized-app',
        samplingRate: 0.01, // Very low sampling rate
        enabledMetrics: ['http'], // Minimal metrics
        enableExtendedMetrics: false,
      };

      // Act
      new CloudWatchRumConstruct(stack, 'TestRum', {
        config: costOptimizedConfig,
        environment: 'prod',
        domainName: 'prod.example.com',
      });

      // Assert
      const template = Template.fromStack(stack);
      
      template.hasResourceProperties('AWS::RUM::AppMonitor', {
        AppMonitorConfiguration: {
          SessionSampleRate: 0.01,
          Telemetries: ['errors', 'performance', 'http'], // Minimal set
        },
        CwLogEnabled: true, // Enables log retention management
      });
    });

    test('validates sampling rate bounds', () => {
      // Test that sampling rates are within valid bounds (0.0 to 1.0)
      const validRates = [0.0, 0.1, 0.5, 1.0];
      
      validRates.forEach((rate, index) => {
        const testStack = new Stack(app, `ValidRateStack${index}`, {
          env: { account: '123456789012', region: 'us-east-1' },
        });

        const config: MonitoringConfig = {
          ...mockConfig,
          samplingRate: rate,
        };

        expect(() => {
          new CloudWatchRumConstruct(testStack, 'TestRum', {
            config,
            environment: 'dev',
            domainName: 'test.example.com',
          });
        }).not.toThrow();
      });
    });
  });

  describe('Integration Points', () => {
    test('provides Flutter web integration configuration', () => {
      // Arrange
      const rumConstruct = new CloudWatchRumConstruct(stack, 'TestRum', {
        config: mockConfig,
        environment: 'dev',
        domainName: 'test.minecraft.lockhead.cloud',
      });

      // Act
      const clientConfig = rumConstruct.getRumClientConfig();
      const initScript = rumConstruct.getRumInitializationScript();

      // Assert - Configuration should be suitable for Flutter web
      expect(clientConfig.allowCookies).toBe(true);
      expect(clientConfig.enableXRay).toBe(true);
      expect(clientConfig.applicationRegion).toBe('us-east-1');
      
      // Script should be embeddable in HTML
      expect(initScript).toContain('<script>');
      expect(initScript).toContain('</script>');
      expect(initScript).toContain('AwsRumClient');
    });

    test('supports different AWS regions', () => {
      // Arrange
      const regionApp = new App();
      const regionStack = new Stack(regionApp, 'RegionTestStack', {
        env: {
          account: '123456789012',
          region: 'eu-west-1',
        },
      });

      // Act
      const rumConstruct = new CloudWatchRumConstruct(regionStack, 'TestRum', {
        config: mockConfig,
        environment: 'dev',
        domainName: 'test.minecraft.lockhead.cloud',
      });

      const clientConfig = rumConstruct.getRumClientConfig();

      // Assert
      expect(clientConfig.applicationRegion).toBe('eu-west-1');
    });
  });
});