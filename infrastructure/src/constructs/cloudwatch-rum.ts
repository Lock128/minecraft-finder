import { Construct } from 'constructs';
import * as rum from 'aws-cdk-lib/aws-rum';
import * as iam from 'aws-cdk-lib/aws-iam';
import { RemovalPolicy, Stack } from 'aws-cdk-lib';
import { MonitoringConfig } from '../types/config';

/**
 * Properties for the CloudWatch RUM construct
 */
export interface CloudWatchRumConstructProps {
  /** RUM monitoring configuration */
  config: MonitoringConfig;
  /** Environment name for resource naming */
  environment: string;
  /** Domain name for the application */
  domainName: string;
  /** Additional tags to apply to resources */
  tags?: Record<string, string>;
}

/**
 * CloudWatch RUM construct for real user monitoring
 * 
 * This construct creates a CloudWatch RUM application monitor to collect
 * real user monitoring data from the Flutter web application. It includes
 * cost optimization through sampling rate configuration and selective
 * metric collection.
 */
export class CloudWatchRumConstruct extends Construct {
  /** The RUM application monitor */
  public readonly rumAppMonitor: rum.CfnAppMonitor;
  
  /** The RUM application name */
  public readonly rumAppName: string;
  
  /** The RUM application ID */
  public readonly rumAppId: string;
  
  /** The configuration used for this construct */
  private readonly config: MonitoringConfig;
  
  /** The guest role for unauthenticated access */
  private readonly guestRole: iam.Role;

  constructor(scope: Construct, id: string, props: CloudWatchRumConstructProps) {
    super(scope, id);

    const { config, environment, domainName, tags = {} } = props;

    // Store config for later use
    this.config = config;

    // Generate RUM application name
    this.rumAppName = `${config.rumAppName}-${environment}`;

    // Create the guest role first
    this.guestRole = this.createGuestRole();

    // Create the RUM application monitor
    this.rumAppMonitor = new rum.CfnAppMonitor(this, 'RumAppMonitor', {
      name: this.rumAppName,
      domain: domainName,
      
      // Application configuration
      appMonitorConfiguration: {
        // Allow cookies for session tracking
        allowCookies: true,
        
        // Enable X-Ray tracing integration
        enableXRay: true,
        
        // Excluded pages (none for now, but can be configured)
        excludedPages: [],
        
        // Favorite pages to prioritize monitoring
        favoritePages: ['/'],
        
        // Guest role ARN for unauthenticated users
        guestRoleArn: this.guestRole.roleArn,
        
        // Identity pool ID (not needed for guest-only access)
        identityPoolId: undefined,
        
        // Included pages (all pages by default)
        includedPages: [],
        
        // Session sample rate for cost optimization
        sessionSampleRate: config.samplingRate,
        
        // Telemetry configuration
        telemetries: this.getTelemetryConfig(config),
      },
      
      // Custom events configuration
      customEvents: {
        status: 'ENABLED',
      },
      
      // Cost optimization - remove data after retention period
      cwLogEnabled: true,
      
      // Tags
      tags: this.buildTags(tags, environment),
    });

    // Store the app ID for client configuration
    this.rumAppId = this.rumAppMonitor.ref;
  }

  /**
   * Creates an IAM role for guest (unauthenticated) users to send RUM data
   */
  private createGuestRole(): iam.Role {
    const guestRole = new iam.Role(this, 'RumGuestRole', {
      assumedBy: new iam.ServicePrincipal('rum.amazonaws.com'),
      description: 'Role for CloudWatch RUM to collect data from unauthenticated users',
      
      // Inline policy for RUM permissions
      inlinePolicies: {
        RumGuestPolicy: new iam.PolicyDocument({
          statements: [
            new iam.PolicyStatement({
              effect: iam.Effect.ALLOW,
              actions: [
                'rum:PutRumEvents',
              ],
              resources: ['*'],
            }),
          ],
        }),
      },
    });

    return guestRole;
  }

  /**
   * Gets telemetry configuration based on enabled metrics
   */
  private getTelemetryConfig(config: MonitoringConfig): string[] {
    const telemetries: string[] = [];
    
    // Always include errors and performance
    telemetries.push('errors', 'performance');
    
    // Add additional telemetries based on configuration
    if (config.enabledMetrics.includes('http')) {
      telemetries.push('http');
    }
    
    if (config.enableExtendedMetrics) {
      // Add extended metrics for detailed monitoring
      if (config.enabledMetrics.includes('navigation')) {
        telemetries.push('navigation');
      }
      
      if (config.enabledMetrics.includes('interaction')) {
        telemetries.push('interaction');
      }
    }
    
    return telemetries;
  }

  /**
   * Builds tags for the RUM application
   */
  private buildTags(customTags: Record<string, string>, environment: string): { key: string; value: string }[] {
    const allTags = {
      ...customTags,
      Component: 'Monitoring',
      Purpose: 'RealUserMonitoring',
      Environment: environment,
      Service: 'CloudWatchRUM',
    };

    return Object.entries(allTags).map(([key, value]) => ({
      key,
      value,
    }));
  }

  /**
   * Gets the RUM client configuration for Flutter web integration
   * This configuration should be used to initialize the RUM client in the web app
   */
  public getRumClientConfig(): RumClientConfig {
    // Get the region from the stack
    const stack = Stack.of(this);
    const region = stack.region || 'us-east-1';
    
    return {
      applicationId: this.rumAppId,
      applicationVersion: '1.0.0',
      applicationRegion: region,
      sessionSampleRate: this.config.samplingRate,
      guestRoleArn: this.guestRole.roleArn,
      enableXRay: true,
      allowCookies: true,
    };
  }

  /**
   * Gets the JavaScript snippet for RUM client initialization
   * This can be embedded in the Flutter web app's index.html
   */
  public getRumInitializationScript(): string {
    const config = this.getRumClientConfig();
    
    return `
<!-- CloudWatch RUM -->
<script>
  (function(n,i,v,r,s,c,x,z){x=window.AwsRumClient={q:[],n:n,i:i,v:v,r:r,c:c};window[n]=function(c,p){x.q.push({c:c,p:p});};z=document.createElement('script');z.async=true;z.src=s;document.head.appendChild(z);})(
    'cwr',
    '${config.applicationId}',
    '${config.applicationVersion}',
    '${config.applicationRegion}',
    'https://client.rum.us-east-1.amazonaws.com/1.x/js/rum.js',
    {
      sessionSampleRate: ${config.sessionSampleRate},
      guestRoleArn: '${config.guestRoleArn}',
      identityPoolId: '',
      endpoint: 'https://dataplane.rum.${config.applicationRegion}.amazonaws.com',
      telemetries: ['performance','errors','http'],
      allowCookies: ${config.allowCookies},
      enableXRay: ${config.enableXRay}
    }
  );
</script>
`.trim();
  }

  /**
   * Gets the RUM application ARN
   */
  public get rumAppArn(): string {
    const stack = Stack.of(this);
    return `arn:aws:rum:${stack.region || 'us-east-1'}:${stack.account}:appmonitor/${this.rumAppName}`;
  }

  /**
   * Gets the RUM application name for reference
   */
  public get applicationName(): string {
    return this.rumAppName;
  }
}

/**
 * RUM client configuration interface for Flutter web integration
 */
export interface RumClientConfig {
  /** RUM application ID */
  applicationId: string;
  /** Application version */
  applicationVersion: string;
  /** AWS region where RUM is deployed */
  applicationRegion: string;
  /** Session sampling rate */
  sessionSampleRate: number;
  /** Guest role ARN for unauthenticated access */
  guestRoleArn?: string;
  /** Whether X-Ray tracing is enabled */
  enableXRay: boolean;
  /** Whether cookies are allowed */
  allowCookies: boolean;
}