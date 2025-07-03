import { Construct } from 'constructs';
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import * as cloudwatchActions from 'aws-cdk-lib/aws-cloudwatch-actions';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as subscriptions from 'aws-cdk-lib/aws-sns-subscriptions';
import * as budgets from 'aws-cdk-lib/aws-budgets';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as synthetics from 'aws-cdk-lib/aws-synthetics';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as s3 from 'aws-cdk-lib/aws-s3';
import { Duration, RemovalPolicy, Stack, Tags as cdk } from 'aws-cdk-lib';
import { DeploymentConfig } from '../types/config';

/**
 * Properties for the MonitoringDashboard construct
 */
export interface MonitoringDashboardProps {
  /** Deployment configuration */
  config: DeploymentConfig;
  /** S3 bucket for static website hosting */
  s3Bucket: s3.IBucket;
  /** CloudFront distribution ID */
  distributionId: string;
  /** CloudFront distribution domain name */
  distributionDomainName: string;
  /** RUM application name */
  rumApplicationName: string;
  /** Custom domain name */
  customDomainName: string;
  /** Environment name */
  environment: string;
  /** Additional tags */
  tags?: Record<string, string>;
}

/**
 * Monitoring and alerting construct for the web hosting infrastructure
 * 
 * This construct creates:
 * - CloudWatch dashboards for application metrics
 * - Alarms for deployment failures and performance issues
 * - Cost monitoring and budget alerts
 * - Health checks and uptime monitoring
 * - SNS topics for notifications
 */
export class MonitoringDashboardConstruct extends Construct {
  /** Main application dashboard */
  public readonly applicationDashboard: cloudwatch.Dashboard;
  
  /** Performance monitoring dashboard */
  public readonly performanceDashboard: cloudwatch.Dashboard;
  
  /** Cost monitoring dashboard */
  public readonly costDashboard: cloudwatch.Dashboard;
  
  /** SNS topic for critical alerts */
  public readonly criticalAlertsTopic: sns.Topic;
  
  /** SNS topic for warning alerts */
  public readonly warningAlertsTopic: sns.Topic;
  
  /** SNS topic for cost alerts */
  public readonly costAlertsTopic: sns.Topic;
  
  /** Budget for cost monitoring */
  public readonly budget: budgets.CfnBudget;
  
  /** Synthetics canary for uptime monitoring */
  public readonly uptimeCanary: synthetics.Canary;
  
  /** CloudWatch alarms */
  public readonly alarms: {
    highErrorRate: cloudwatch.Alarm;
    highLatency: cloudwatch.Alarm;
    lowCacheHitRatio: cloudwatch.Alarm;
    budgetExceeded: cloudwatch.Alarm;
    uptimeFailure: cloudwatch.Alarm;
    rumErrorRate: cloudwatch.Alarm;
  };

  private readonly config: DeploymentConfig;
  private readonly environment: string;

  constructor(scope: Construct, id: string, props: MonitoringDashboardProps) {
    super(scope, id);

    this.config = props.config;
    this.environment = props.environment;

    // Create SNS topics for notifications
    this.criticalAlertsTopic = this.createCriticalAlertsTopic();
    this.warningAlertsTopic = this.createWarningAlertsTopic();
    this.costAlertsTopic = this.createCostAlertsTopic();

    // Create uptime monitoring canary
    this.uptimeCanary = this.createUptimeCanary(props.customDomainName);

    // Create CloudWatch alarms
    this.alarms = this.createCloudWatchAlarms(props);

    // Create budget for cost monitoring
    this.budget = this.createBudget();

    // Create dashboards
    this.applicationDashboard = this.createApplicationDashboard(props);
    this.performanceDashboard = this.createPerformanceDashboard(props);
    this.costDashboard = this.createCostDashboard(props);

    // Apply tags
    this.applyTags(props.tags);
  }

  /**
   * Creates SNS topic for critical alerts
   */
  private createCriticalAlertsTopic(): sns.Topic {
    const topic = new sns.Topic(this, 'CriticalAlertsTopic', {
      topicName: `web-hosting-critical-alerts-${this.environment}`,
      displayName: `Web Hosting Critical Alerts - ${this.environment.toUpperCase()}`,
      fifo: false,
    });

    // Add email subscription if configured
    if (this.config.costAllocation.customCostTags?.['AlertEmail']) {
      topic.addSubscription(
        new subscriptions.EmailSubscription(this.config.costAllocation.customCostTags['AlertEmail'])
      );
    }

    return topic;
  }

  /**
   * Creates SNS topic for warning alerts
   */
  private createWarningAlertsTopic(): sns.Topic {
    const topic = new sns.Topic(this, 'WarningAlertsTopic', {
      topicName: `web-hosting-warning-alerts-${this.environment}`,
      displayName: `Web Hosting Warning Alerts - ${this.environment.toUpperCase()}`,
      fifo: false,
    });

    // Add email subscription if configured
    if (this.config.costAllocation.customCostTags?.['AlertEmail']) {
      topic.addSubscription(
        new subscriptions.EmailSubscription(this.config.costAllocation.customCostTags['AlertEmail'])
      );
    }

    return topic;
  }

  /**
   * Creates SNS topic for cost alerts
   */
  private createCostAlertsTopic(): sns.Topic {
    const topic = new sns.Topic(this, 'CostAlertsTopic', {
      topicName: `web-hosting-cost-alerts-${this.environment}`,
      displayName: `Web Hosting Cost Alerts - ${this.environment.toUpperCase()}`,
      fifo: false,
    });

    // Add email subscription if configured
    if (this.config.costAllocation.customCostTags?.['AlertEmail']) {
      topic.addSubscription(
        new subscriptions.EmailSubscription(this.config.costAllocation.customCostTags['AlertEmail'])
      );
    }

    return topic;
  }

  /**
   * Creates Synthetics canary for uptime monitoring
   */
  private createUptimeCanary(domainName: string): synthetics.Canary {
    // Create S3 bucket for canary artifacts
    const canaryArtifactsBucket = new s3.Bucket(this, 'CanaryArtifactsBucket', {
      bucketName: `web-hosting-canary-artifacts-${this.environment}-${Stack.of(this).account}`,
      removalPolicy: RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
      lifecycleRules: [
        {
          id: 'DeleteOldArtifacts',
          enabled: true,
          expiration: Duration.days(30),
        },
      ],
    });

    // Create IAM role for canary
    const canaryRole = new iam.Role(this, 'CanaryRole', {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
      ],
      inlinePolicies: {
        CanaryPolicy: new iam.PolicyDocument({
          statements: [
            new iam.PolicyStatement({
              effect: iam.Effect.ALLOW,
              actions: [
                's3:PutObject',
                's3:GetBucketLocation',
                's3:ListAllMyBuckets',
                'cloudwatch:PutMetricData',
                'logs:CreateLogGroup',
                'logs:CreateLogStream',
                'logs:PutLogEvents',
              ],
              resources: [
                canaryArtifactsBucket.bucketArn,
                `${canaryArtifactsBucket.bucketArn}/*`,
                '*',
              ],
            }),
          ],
        }),
      },
    });

    // Create the canary
    const canary = new synthetics.Canary(this, 'UptimeCanary', {
      canaryName: `web-hosting-uptime-${this.environment}`,
      schedule: synthetics.Schedule.rate(Duration.minutes(5)),
      test: synthetics.Test.custom({
        code: synthetics.Code.fromInline(`
const synthetics = require('Synthetics');
const log = require('SyntheticsLogger');

const checkWebsite = async function () {
    const config = {
        includeRequestHeaders: true,
        includeResponseHeaders: true,
        restrictedHeaders: [],
        restrictedUrlParameters: []
    };

    const url = 'https://${domainName}';
    
    // Check main page
    const mainPageResponse = await synthetics.executeStep('checkMainPage', async () => {
        return await synthetics.getPage(url, config);
    });

    // Verify response status
    if (mainPageResponse.status !== 200) {
        throw new Error(\`Main page returned status \${mainPageResponse.status}\`);
    }

    // Check for Flutter app initialization
    await synthetics.executeStep('checkFlutterApp', async () => {
        const page = await synthetics.getPage();
        
        // Wait for Flutter app to load
        await page.waitForSelector('flutter-view', { timeout: 10000 });
        
        // Check for any JavaScript errors
        const errors = await page.evaluate(() => {
            return window.errors || [];
        });
        
        if (errors.length > 0) {
            log.warn('JavaScript errors detected:', errors);
        }
        
        // Take screenshot for debugging
        await synthetics.takeScreenshot('flutter-app-loaded', 'loaded');
    });

    log.info('Website check completed successfully');
};

exports.handler = async () => {
    return await synthetics.executeStep('checkWebsite', checkWebsite);
};
        `),
        handler: 'index.handler',
      }),
      runtime: synthetics.Runtime.SYNTHETICS_NODEJS_PUPPETEER_6_2,
      environmentVariables: {
        DOMAIN_NAME: domainName,
        ENVIRONMENT: this.environment,
      },
      role: canaryRole,
      artifactsBucketLocation: {
        bucket: canaryArtifactsBucket,
        prefix: 'canary-artifacts',
      },
      failureRetentionPeriod: Duration.days(30),
      successRetentionPeriod: Duration.days(7),
    });

    return canary;
  }

  /**
   * Creates CloudWatch alarms for monitoring
   */
  private createCloudWatchAlarms(props: MonitoringDashboardProps): typeof this.alarms {
    // High error rate alarm (CloudFront)
    const highErrorRate = new cloudwatch.Alarm(this, 'HighErrorRateAlarm', {
      alarmName: `web-hosting-high-error-rate-${this.environment}`,
      alarmDescription: 'High error rate detected in CloudFront distribution',
      metric: new cloudwatch.Metric({
        namespace: 'AWS/CloudFront',
        metricName: '4xxErrorRate',
        dimensionsMap: {
          DistributionId: props.distributionId,
        },
        statistic: 'Average',
        period: Duration.minutes(5),
      }),
      threshold: 5, // 5% error rate
      evaluationPeriods: 2,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    });
    highErrorRate.addAlarmAction(new cloudwatchActions.SnsAction(this.criticalAlertsTopic));

    // High latency alarm (CloudFront)
    const highLatency = new cloudwatch.Alarm(this, 'HighLatencyAlarm', {
      alarmName: `web-hosting-high-latency-${this.environment}`,
      alarmDescription: 'High latency detected in CloudFront distribution',
      metric: new cloudwatch.Metric({
        namespace: 'AWS/CloudFront',
        metricName: 'ResponseTime',
        dimensionsMap: {
          DistributionId: props.distributionId,
        },
        statistic: 'Average',
        period: Duration.minutes(5),
      }),
      threshold: 2000, // 2 seconds
      evaluationPeriods: 3,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    });
    highLatency.addAlarmAction(new cloudwatchActions.SnsAction(this.warningAlertsTopic));

    // Low cache hit ratio alarm
    const lowCacheHitRatio = new cloudwatch.Alarm(this, 'LowCacheHitRatioAlarm', {
      alarmName: `web-hosting-low-cache-hit-ratio-${this.environment}`,
      alarmDescription: 'Low cache hit ratio in CloudFront distribution',
      metric: new cloudwatch.Metric({
        namespace: 'AWS/CloudFront',
        metricName: 'CacheHitRate',
        dimensionsMap: {
          DistributionId: props.distributionId,
        },
        statistic: 'Average',
        period: Duration.minutes(15),
      }),
      threshold: 80, // 80% cache hit rate
      evaluationPeriods: 2,
      comparisonOperator: cloudwatch.ComparisonOperator.LESS_THAN_THRESHOLD,
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    });
    lowCacheHitRatio.addAlarmAction(new cloudwatchActions.SnsAction(this.warningAlertsTopic));

    // Budget exceeded alarm
    const budgetExceeded = new cloudwatch.Alarm(this, 'BudgetExceededAlarm', {
      alarmName: `web-hosting-budget-exceeded-${this.environment}`,
      alarmDescription: 'Monthly budget threshold exceeded',
      metric: new cloudwatch.Metric({
        namespace: 'AWS/Billing',
        metricName: 'EstimatedCharges',
        dimensionsMap: {
          Currency: 'USD',
        },
        statistic: 'Maximum',
        period: Duration.hours(6),
      }),
      threshold: this.config.costAllocation.budgetThreshold || 100,
      evaluationPeriods: 1,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    });
    budgetExceeded.addAlarmAction(new cloudwatchActions.SnsAction(this.costAlertsTopic));

    // Uptime failure alarm
    const uptimeFailure = new cloudwatch.Alarm(this, 'UptimeFailureAlarm', {
      alarmName: `web-hosting-uptime-failure-${this.environment}`,
      alarmDescription: 'Website uptime check failed',
      metric: this.uptimeCanary.metricSuccessPercent({
        period: Duration.minutes(5),
      }),
      threshold: 90, // 90% success rate
      evaluationPeriods: 2,
      comparisonOperator: cloudwatch.ComparisonOperator.LESS_THAN_THRESHOLD,
      treatMissingData: cloudwatch.TreatMissingData.BREACHING,
    });
    uptimeFailure.addAlarmAction(new cloudwatchActions.SnsAction(this.criticalAlertsTopic));

    // RUM error rate alarm
    const rumErrorRate = new cloudwatch.Alarm(this, 'RumErrorRateAlarm', {
      alarmName: `web-hosting-rum-error-rate-${this.environment}`,
      alarmDescription: 'High JavaScript error rate detected in RUM',
      metric: new cloudwatch.Metric({
        namespace: 'AWS/RUM',
        metricName: 'JsErrorCount',
        dimensionsMap: {
          ApplicationName: props.rumApplicationName,
        },
        statistic: 'Sum',
        period: Duration.minutes(15),
      }),
      threshold: 10, // 10 errors per 15 minutes
      evaluationPeriods: 2,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    });
    rumErrorRate.addAlarmAction(new cloudwatchActions.SnsAction(this.warningAlertsTopic));

    return {
      highErrorRate,
      highLatency,
      lowCacheHitRatio,
      budgetExceeded,
      uptimeFailure,
      rumErrorRate,
    };
  }

  /**
   * Creates budget for cost monitoring
   */
  private createBudget(): budgets.CfnBudget {
    const budgetThreshold = this.config.costAllocation.budgetThreshold || 100;
    
    return new budgets.CfnBudget(this, 'MonthlyBudget', {
      budget: {
        budgetName: `web-hosting-budget-${this.environment}`,
        budgetType: 'COST',
        timeUnit: 'MONTHLY',
        budgetLimit: {
          amount: budgetThreshold,
          unit: 'USD',
        },
        costFilters: {
          TagKey: ['ProjectCode'],
          TagValue: [this.config.costAllocation.projectCode],
        },
        plannedBudgetLimits: {
          [`${new Date().getFullYear()}-${String(new Date().getMonth() + 1).padStart(2, '0')}`]: {
            amount: budgetThreshold,
            unit: 'USD',
          },
        },
      },
      notificationsWithSubscribers: [
        {
          notification: {
            notificationType: 'ACTUAL',
            comparisonOperator: 'GREATER_THAN',
            threshold: 80, // 80% of budget
            thresholdType: 'PERCENTAGE',
          },
          subscribers: [
            {
              subscriptionType: 'SNS',
              address: this.costAlertsTopic.topicArn,
            },
          ],
        },
        {
          notification: {
            notificationType: 'FORECASTED',
            comparisonOperator: 'GREATER_THAN',
            threshold: 100, // 100% of budget
            thresholdType: 'PERCENTAGE',
          },
          subscribers: [
            {
              subscriptionType: 'SNS',
              address: this.costAlertsTopic.topicArn,
            },
          ],
        },
      ],
    });
  }  /**
 
  * Creates the main application dashboard
   */
  private createApplicationDashboard(props: MonitoringDashboardProps): cloudwatch.Dashboard {
    const dashboard = new cloudwatch.Dashboard(this, 'ApplicationDashboard', {
      dashboardName: `web-hosting-application-${this.environment}`,
      defaultInterval: Duration.hours(1),
    });

    // CloudFront metrics row
    dashboard.addWidgets(
      new cloudwatch.GraphWidget({
        title: 'CloudFront Requests',
        left: [
          new cloudwatch.Metric({
            namespace: 'AWS/CloudFront',
            metricName: 'Requests',
            dimensionsMap: {
              DistributionId: props.distributionId,
            },
            statistic: 'Sum',
            period: Duration.minutes(5),
          }),
        ],
        width: 12,
        height: 6,
      }),
      new cloudwatch.GraphWidget({
        title: 'CloudFront Error Rates',
        left: [
          new cloudwatch.Metric({
            namespace: 'AWS/CloudFront',
            metricName: '4xxErrorRate',
            dimensionsMap: {
              DistributionId: props.distributionId,
            },
            statistic: 'Average',
            period: Duration.minutes(5),
            label: '4xx Error Rate',
          }),
          new cloudwatch.Metric({
            namespace: 'AWS/CloudFront',
            metricName: '5xxErrorRate',
            dimensionsMap: {
              DistributionId: props.distributionId,
            },
            statistic: 'Average',
            period: Duration.minutes(5),
            label: '5xx Error Rate',
          }),
        ],
        width: 12,
        height: 6,
      }),
    );

    // Performance metrics row
    dashboard.addWidgets(
      new cloudwatch.GraphWidget({
        title: 'Response Time & Cache Performance',
        left: [
          new cloudwatch.Metric({
            namespace: 'AWS/CloudFront',
            metricName: 'ResponseTime',
            dimensionsMap: {
              DistributionId: props.distributionId,
            },
            statistic: 'Average',
            period: Duration.minutes(5),
            label: 'Response Time (ms)',
          }),
        ],
        right: [
          new cloudwatch.Metric({
            namespace: 'AWS/CloudFront',
            metricName: 'CacheHitRate',
            dimensionsMap: {
              DistributionId: props.distributionId,
            },
            statistic: 'Average',
            period: Duration.minutes(5),
            label: 'Cache Hit Rate (%)',
          }),
        ],
        width: 12,
        height: 6,
      }),
      new cloudwatch.GraphWidget({
        title: 'Data Transfer',
        left: [
          new cloudwatch.Metric({
            namespace: 'AWS/CloudFront',
            metricName: 'BytesDownloaded',
            dimensionsMap: {
              DistributionId: props.distributionId,
            },
            statistic: 'Sum',
            period: Duration.minutes(5),
            label: 'Bytes Downloaded',
          }),
          new cloudwatch.Metric({
            namespace: 'AWS/CloudFront',
            metricName: 'BytesUploaded',
            dimensionsMap: {
              DistributionId: props.distributionId,
            },
            statistic: 'Sum',
            period: Duration.minutes(5),
            label: 'Bytes Uploaded',
          }),
        ],
        width: 12,
        height: 6,
      }),
    );

    // S3 metrics row
    dashboard.addWidgets(
      new cloudwatch.GraphWidget({
        title: 'S3 Requests',
        left: [
          new cloudwatch.Metric({
            namespace: 'AWS/S3',
            metricName: 'NumberOfObjects',
            dimensionsMap: {
              BucketName: props.s3Bucket.bucketName,
              StorageType: 'AllStorageTypes',
            },
            statistic: 'Average',
            period: Duration.hours(1),
            label: 'Number of Objects',
          }),
        ],
        right: [
          new cloudwatch.Metric({
            namespace: 'AWS/S3',
            metricName: 'BucketSizeBytes',
            dimensionsMap: {
              BucketName: props.s3Bucket.bucketName,
              StorageType: 'StandardStorage',
            },
            statistic: 'Average',
            period: Duration.hours(1),
            label: 'Bucket Size (Bytes)',
          }),
        ],
        width: 12,
        height: 6,
      }),
      new cloudwatch.SingleValueWidget({
        title: 'Uptime Status',
        metrics: [
          this.uptimeCanary.metricSuccessPercent({
            period: Duration.hours(1),
          }),
        ],
        width: 6,
        height: 6,
      }),
      new cloudwatch.SingleValueWidget({
        title: 'Current Error Rate',
        metrics: [
          new cloudwatch.Metric({
            namespace: 'AWS/CloudFront',
            metricName: '4xxErrorRate',
            dimensionsMap: {
              DistributionId: props.distributionId,
            },
            statistic: 'Average',
            period: Duration.minutes(15),
          }),
        ],
        width: 6,
        height: 6,
      }),
    );

    return dashboard;
  }

  /**
   * Creates the performance monitoring dashboard
   */
  private createPerformanceDashboard(props: MonitoringDashboardProps): cloudwatch.Dashboard {
    const dashboard = new cloudwatch.Dashboard(this, 'PerformanceDashboard', {
      dashboardName: `web-hosting-performance-${this.environment}`,
      defaultInterval: Duration.hours(1),
    });

    // RUM metrics row
    dashboard.addWidgets(
      new cloudwatch.GraphWidget({
        title: 'RUM Page Load Performance',
        left: [
          new cloudwatch.Metric({
            namespace: 'AWS/RUM',
            metricName: 'PageLoadTime',
            dimensionsMap: {
              ApplicationName: props.rumApplicationName,
            },
            statistic: 'Average',
            period: Duration.minutes(15),
            label: 'Average Page Load Time',
          }),
          new cloudwatch.Metric({
            namespace: 'AWS/RUM',
            metricName: 'PageLoadTime',
            dimensionsMap: {
              ApplicationName: props.rumApplicationName,
            },
            statistic: 'p95',
            period: Duration.minutes(15),
            label: '95th Percentile Page Load Time',
          }),
        ],
        width: 12,
        height: 6,
      }),
      new cloudwatch.GraphWidget({
        title: 'RUM JavaScript Errors',
        left: [
          new cloudwatch.Metric({
            namespace: 'AWS/RUM',
            metricName: 'JsErrorCount',
            dimensionsMap: {
              ApplicationName: props.rumApplicationName,
            },
            statistic: 'Sum',
            period: Duration.minutes(15),
            label: 'JavaScript Errors',
          }),
        ],
        width: 12,
        height: 6,
      }),
    );

    // User interaction metrics
    dashboard.addWidgets(
      new cloudwatch.GraphWidget({
        title: 'User Sessions',
        left: [
          new cloudwatch.Metric({
            namespace: 'AWS/RUM',
            metricName: 'SessionCount',
            dimensionsMap: {
              ApplicationName: props.rumApplicationName,
            },
            statistic: 'Sum',
            period: Duration.hours(1),
            label: 'Active Sessions',
          }),
        ],
        width: 12,
        height: 6,
      }),
      new cloudwatch.GraphWidget({
        title: 'HTTP Request Performance',
        left: [
          new cloudwatch.Metric({
            namespace: 'AWS/RUM',
            metricName: 'HttpRequestTime',
            dimensionsMap: {
              ApplicationName: props.rumApplicationName,
            },
            statistic: 'Average',
            period: Duration.minutes(15),
            label: 'Average HTTP Request Time',
          }),
        ],
        right: [
          new cloudwatch.Metric({
            namespace: 'AWS/RUM',
            metricName: 'HttpErrorCount',
            dimensionsMap: {
              ApplicationName: props.rumApplicationName,
            },
            statistic: 'Sum',
            period: Duration.minutes(15),
            label: 'HTTP Errors',
          }),
        ],
        width: 12,
        height: 6,
      }),
    );

    // Synthetics canary metrics
    dashboard.addWidgets(
      new cloudwatch.GraphWidget({
        title: 'Uptime Monitoring',
        left: [
          this.uptimeCanary.metricSuccessPercent({
            period: Duration.minutes(15),
            label: 'Success Rate (%)',
          }),
        ],
        right: [
          this.uptimeCanary.metricDuration({
            period: Duration.minutes(15),
            label: 'Check Duration (ms)',
          }),
        ],
        width: 12,
        height: 6,
      }),
      new cloudwatch.GraphWidget({
        title: 'Canary Failures',
        left: [
          this.uptimeCanary.metricFailed({
            period: Duration.minutes(15),
            label: 'Failed Checks',
          }),
        ],
        width: 12,
        height: 6,
      }),
    );

    return dashboard;
  }

  /**
   * Creates the cost monitoring dashboard
   */
  private createCostDashboard(props: MonitoringDashboardProps): cloudwatch.Dashboard {
    const dashboard = new cloudwatch.Dashboard(this, 'CostDashboard', {
      dashboardName: `web-hosting-cost-${this.environment}`,
      defaultInterval: Duration.days(1),
    });

    // Billing metrics
    dashboard.addWidgets(
      new cloudwatch.GraphWidget({
        title: 'Estimated Monthly Charges',
        left: [
          new cloudwatch.Metric({
            namespace: 'AWS/Billing',
            metricName: 'EstimatedCharges',
            dimensionsMap: {
              Currency: 'USD',
            },
            statistic: 'Maximum',
            period: Duration.hours(6),
            label: 'Total Estimated Charges',
          }),
        ],
        width: 12,
        height: 6,
      }),
      new cloudwatch.SingleValueWidget({
        title: 'Current Month Spend',
        metrics: [
          new cloudwatch.Metric({
            namespace: 'AWS/Billing',
            metricName: 'EstimatedCharges',
            dimensionsMap: {
              Currency: 'USD',
            },
            statistic: 'Maximum',
            period: Duration.hours(6),
          }),
        ],
        width: 6,
        height: 6,
      }),
      new cloudwatch.SingleValueWidget({
        title: 'Budget Utilization',
        metrics: [
          new cloudwatch.MathExpression({
            expression: `(m1 / ${this.config.costAllocation.budgetThreshold || 100}) * 100`,
            usingMetrics: {
              m1: new cloudwatch.Metric({
                namespace: 'AWS/Billing',
                metricName: 'EstimatedCharges',
                dimensionsMap: {
                  Currency: 'USD',
                },
                statistic: 'Maximum',
                period: Duration.hours(6),
              }),
            },
            label: 'Budget Utilization (%)',
          }),
        ],
        width: 6,
        height: 6,
      }),
    );

    // Service-specific costs (if available)
    dashboard.addWidgets(
      new cloudwatch.GraphWidget({
        title: 'CloudFront Data Transfer',
        left: [
          new cloudwatch.Metric({
            namespace: 'AWS/CloudFront',
            metricName: 'BytesDownloaded',
            dimensionsMap: {
              DistributionId: props.distributionId,
            },
            statistic: 'Sum',
            period: Duration.hours(1),
            label: 'Data Transfer Out (Bytes)',
          }),
        ],
        width: 12,
        height: 6,
      }),
      new cloudwatch.GraphWidget({
        title: 'Request Volume (Cost Driver)',
        left: [
          new cloudwatch.Metric({
            namespace: 'AWS/CloudFront',
            metricName: 'Requests',
            dimensionsMap: {
              DistributionId: props.distributionId,
            },
            statistic: 'Sum',
            period: Duration.hours(1),
            label: 'CloudFront Requests',
          }),
        ],
        right: [
          new cloudwatch.Metric({
            namespace: 'AWS/RUM',
            metricName: 'SessionCount',
            dimensionsMap: {
              ApplicationName: props.rumApplicationName,
            },
            statistic: 'Sum',
            period: Duration.hours(1),
            label: 'RUM Sessions',
          }),
        ],
        width: 12,
        height: 6,
      }),
    );

    return dashboard;
  }

  /**
   * Applies tags to all monitoring resources
   */
  private applyTags(customTags: Record<string, string> = {}): void {
    const allTags = {
      ...customTags,
      Component: 'Monitoring',
      Purpose: 'ApplicationMonitoring',
      Environment: this.environment,
      Service: 'CloudWatch',
    };

    // Apply tags to all constructs
    Object.entries(allTags).forEach(([key, value]) => {
      cdk.of(this).add(key, value);
    });
  }

  /**
   * Gets monitoring configuration for external systems
   */
  public getMonitoringConfig() {
    return {
      dashboards: {
        application: this.applicationDashboard.dashboardName,
        performance: this.performanceDashboard.dashboardName,
        cost: this.costDashboard.dashboardName,
      },
      alarms: {
        critical: [
          this.alarms.highErrorRate.alarmName,
          this.alarms.uptimeFailure.alarmName,
        ],
        warning: [
          this.alarms.highLatency.alarmName,
          this.alarms.lowCacheHitRatio.alarmName,
          this.alarms.rumErrorRate.alarmName,
        ],
        cost: [
          this.alarms.budgetExceeded.alarmName,
        ],
      },
      topics: {
        critical: this.criticalAlertsTopic.topicArn,
        warning: this.warningAlertsTopic.topicArn,
        cost: this.costAlertsTopic.topicArn,
      },
      canary: {
        name: this.uptimeCanary.canaryName,
        arn: this.uptimeCanary.canaryId,
      },
      budget: {
        name: this.budget.ref,
        threshold: this.config.costAllocation.budgetThreshold || 100,
      },
    };
  }

  /**
   * Gets SNS topic ARNs for external notification setup
   */
  public getNotificationTopics() {
    return {
      criticalAlerts: this.criticalAlertsTopic.topicArn,
      warningAlerts: this.warningAlertsTopic.topicArn,
      costAlerts: this.costAlertsTopic.topicArn,
    };
  }

  /**
   * Gets dashboard URLs for quick access
   */
  public getDashboardUrls() {
    const region = Stack.of(this).region;
    const baseUrl = `https://${region}.console.aws.amazon.com/cloudwatch/home?region=${region}#dashboards:name=`;
    
    return {
      application: `${baseUrl}${this.applicationDashboard.dashboardName}`,
      performance: `${baseUrl}${this.performanceDashboard.dashboardName}`,
      cost: `${baseUrl}${this.costDashboard.dashboardName}`,
    };
  }
}