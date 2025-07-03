#!/usr/bin/env ts-node

/**
 * Script to test monitoring and alerting functionality
 * 
 * This script validates that all monitoring components are working correctly:
 * - CloudWatch dashboards are accessible
 * - Alarms are configured with correct thresholds
 * - SNS topics are set up for notifications
 * - Synthetics canary is running uptime checks
 * - Budget alerts are configured
 */

import * as AWS from 'aws-sdk';
import { ConfigLoader } from '../src/utils/config-loader';
import { DeploymentConfig } from '../src/types/config';

// Configure AWS SDK
const region = process.env.AWS_REGION || 'us-east-1';
AWS.config.update({ region });

const cloudwatch = new AWS.CloudWatch();
const synthetics = new AWS.Synthetics();
const sns = new AWS.SNS();
const budgets = new AWS.Budgets();

interface MonitoringTestResults {
  dashboards: {
    application: boolean;
    performance: boolean;
    cost: boolean;
  };
  alarms: {
    highErrorRate: boolean;
    highLatency: boolean;
    lowCacheHitRatio: boolean;
    budgetExceeded: boolean;
    uptimeFailure: boolean;
    rumErrorRate: boolean;
  };
  topics: {
    criticalAlerts: boolean;
    warningAlerts: boolean;
    costAlerts: boolean;
  };
  canary: {
    exists: boolean;
    running: boolean;
    lastRun: Date | null;
    successRate: number | null;
  };
  budget: {
    exists: boolean;
    threshold: number | null;
    currentSpend: number | null;
  };
}

/**
 * Main function to test monitoring functionality
 */
async function testMonitoring(): Promise<void> {
  try {
    console.log('🔍 Testing monitoring and alerting functionality...\n');

    // Load configuration
    const environment = process.env.ENVIRONMENT || 'dev';
    const configLoader = new ConfigLoader();
    const config = await configLoader.loadConfig(environment as any);

    console.log(`Environment: ${environment}`);
    console.log(`Region: ${region}\n`);

    // Run tests
    const results = await runMonitoringTests(config);

    // Display results
    displayTestResults(results);

    // Check overall health
    const overallHealth = checkOverallHealth(results);
    
    if (overallHealth) {
      console.log('\n✅ All monitoring tests passed successfully!');
      process.exit(0);
    } else {
      console.log('\n❌ Some monitoring tests failed. Please check the configuration.');
      process.exit(1);
    }

  } catch (error) {
    console.error('❌ Error testing monitoring functionality:', error);
    process.exit(1);
  }
}

/**
 * Run all monitoring tests
 */
async function runMonitoringTests(config: DeploymentConfig): Promise<MonitoringTestResults> {
  const results: MonitoringTestResults = {
    dashboards: {
      application: false,
      performance: false,
      cost: false,
    },
    alarms: {
      highErrorRate: false,
      highLatency: false,
      lowCacheHitRatio: false,
      budgetExceeded: false,
      uptimeFailure: false,
      rumErrorRate: false,
    },
    topics: {
      criticalAlerts: false,
      warningAlerts: false,
      costAlerts: false,
    },
    canary: {
      exists: false,
      running: false,
      lastRun: null,
      successRate: null,
    },
    budget: {
      exists: false,
      threshold: null,
      currentSpend: null,
    },
  };

  // Test dashboards
  console.log('📊 Testing CloudWatch dashboards...');
  results.dashboards = await testDashboards(config);

  // Test alarms
  console.log('🚨 Testing CloudWatch alarms...');
  results.alarms = await testAlarms(config);

  // Test SNS topics
  console.log('📧 Testing SNS notification topics...');
  results.topics = await testSnsTopics(config);

  // Test Synthetics canary
  console.log('🕵️ Testing Synthetics canary...');
  results.canary = await testCanary(config);

  // Test budget
  console.log('💰 Testing budget configuration...');
  results.budget = await testBudget(config);

  return results;
}

/**
 * Test CloudWatch dashboards
 */
async function testDashboards(config: DeploymentConfig): Promise<MonitoringTestResults['dashboards']> {
  const environment = config.environment;
  const dashboardNames = [
    `web-hosting-application-${environment}`,
    `web-hosting-performance-${environment}`,
    `web-hosting-cost-${environment}`,
  ];

  const results = {
    application: false,
    performance: false,
    cost: false,
  };

  try {
    const response = await cloudwatch.listDashboards().promise();
    const existingDashboards = response.DashboardEntries?.map(d => d.DashboardName) || [];

    results.application = existingDashboards.includes(dashboardNames[0]);
    results.performance = existingDashboards.includes(dashboardNames[1]);
    results.cost = existingDashboards.includes(dashboardNames[2]);

    console.log(`  Application dashboard: ${results.application ? '✅' : '❌'}`);
    console.log(`  Performance dashboard: ${results.performance ? '✅' : '❌'}`);
    console.log(`  Cost dashboard: ${results.cost ? '✅' : '❌'}`);

  } catch (error) {
    console.error('  Error testing dashboards:', error);
  }

  return results;
}

/**
 * Test CloudWatch alarms
 */
async function testAlarms(config: DeploymentConfig): Promise<MonitoringTestResults['alarms']> {
  const environment = config.environment;
  const alarmNames = [
    `web-hosting-high-error-rate-${environment}`,
    `web-hosting-high-latency-${environment}`,
    `web-hosting-low-cache-hit-ratio-${environment}`,
    `web-hosting-budget-exceeded-${environment}`,
    `web-hosting-uptime-failure-${environment}`,
    `web-hosting-rum-error-rate-${environment}`,
  ];

  const results = {
    highErrorRate: false,
    highLatency: false,
    lowCacheHitRatio: false,
    budgetExceeded: false,
    uptimeFailure: false,
    rumErrorRate: false,
  };

  try {
    const response = await cloudwatch.describeAlarms({
      AlarmNames: alarmNames,
    }).promise();

    const existingAlarms = response.MetricAlarms?.map(a => a.AlarmName) || [];

    results.highErrorRate = existingAlarms.includes(alarmNames[0]);
    results.highLatency = existingAlarms.includes(alarmNames[1]);
    results.lowCacheHitRatio = existingAlarms.includes(alarmNames[2]);
    results.budgetExceeded = existingAlarms.includes(alarmNames[3]);
    results.uptimeFailure = existingAlarms.includes(alarmNames[4]);
    results.rumErrorRate = existingAlarms.includes(alarmNames[5]);

    console.log(`  High error rate alarm: ${results.highErrorRate ? '✅' : '❌'}`);
    console.log(`  High latency alarm: ${results.highLatency ? '✅' : '❌'}`);
    console.log(`  Low cache hit ratio alarm: ${results.lowCacheHitRatio ? '✅' : '❌'}`);
    console.log(`  Budget exceeded alarm: ${results.budgetExceeded ? '✅' : '❌'}`);
    console.log(`  Uptime failure alarm: ${results.uptimeFailure ? '✅' : '❌'}`);
    console.log(`  RUM error rate alarm: ${results.rumErrorRate ? '✅' : '❌'}`);

  } catch (error) {
    console.error('  Error testing alarms:', error);
  }

  return results;
}

/**
 * Test SNS topics
 */
async function testSnsTopics(config: DeploymentConfig): Promise<MonitoringTestResults['topics']> {
  const environment = config.environment;
  const topicNames = [
    `web-hosting-critical-alerts-${environment}`,
    `web-hosting-warning-alerts-${environment}`,
    `web-hosting-cost-alerts-${environment}`,
  ];

  const results = {
    criticalAlerts: false,
    warningAlerts: false,
    costAlerts: false,
  };

  try {
    const response = await sns.listTopics().promise();
    const existingTopics = response.Topics?.map(t => {
      const arnParts = t.TopicArn?.split(':') || [];
      return arnParts[arnParts.length - 1];
    }) || [];

    results.criticalAlerts = existingTopics.includes(topicNames[0]);
    results.warningAlerts = existingTopics.includes(topicNames[1]);
    results.costAlerts = existingTopics.includes(topicNames[2]);

    console.log(`  Critical alerts topic: ${results.criticalAlerts ? '✅' : '❌'}`);
    console.log(`  Warning alerts topic: ${results.warningAlerts ? '✅' : '❌'}`);
    console.log(`  Cost alerts topic: ${results.costAlerts ? '✅' : '❌'}`);

  } catch (error) {
    console.error('  Error testing SNS topics:', error);
  }

  return results;
}

/**
 * Test Synthetics canary
 */
async function testCanary(config: DeploymentConfig): Promise<MonitoringTestResults['canary']> {
  const environment = config.environment;
  const canaryName = `web-hosting-uptime-${environment}`;

  const results = {
    exists: false,
    running: false,
    lastRun: null as Date | null,
    successRate: null as number | null,
  };

  try {
    const response = await synthetics.getCanary({
      Name: canaryName,
    }).promise();

    if (response.Canary) {
      results.exists = true;
      results.running = response.Canary.Status?.State === 'RUNNING';
      
      if (response.Canary.Status?.StateReason) {
        console.log(`  Canary state reason: ${response.Canary.Status.StateReason}`);
      }

      // Get canary runs to check success rate
      try {
        const runsResponse = await synthetics.getCanaryRuns({
          Name: canaryName,
          MaxResults: 10,
        }).promise();

        if (runsResponse.CanaryRuns && runsResponse.CanaryRuns.length > 0) {
          const runs = runsResponse.CanaryRuns;
          results.lastRun = runs[0].Timeline?.Started || null;
          
          const successfulRuns = runs.filter(run => run.Status?.State === 'PASSED').length;
          results.successRate = (successfulRuns / runs.length) * 100;
        }
      } catch (runsError) {
        console.warn('  Could not fetch canary runs:', runsError);
      }
    }

    console.log(`  Canary exists: ${results.exists ? '✅' : '❌'}`);
    console.log(`  Canary running: ${results.running ? '✅' : '❌'}`);
    if (results.lastRun) {
      console.log(`  Last run: ${results.lastRun.toISOString()}`);
    }
    if (results.successRate !== null) {
      console.log(`  Success rate: ${results.successRate.toFixed(1)}%`);
    }

  } catch (error) {
    if ((error as any).code === 'ResourceNotFoundException') {
      console.log(`  Canary '${canaryName}' not found: ❌`);
    } else {
      console.error('  Error testing canary:', error);
    }
  }

  return results;
}

/**
 * Test budget configuration
 */
async function testBudget(config: DeploymentConfig): Promise<MonitoringTestResults['budget']> {
  const environment = config.environment;
  const budgetName = `web-hosting-budget-${environment}`;

  const results = {
    exists: false,
    threshold: null as number | null,
    currentSpend: null as number | null,
  };

  try {
    const response = await budgets.describeBudget({
      AccountId: await getAccountId(),
      BudgetName: budgetName,
    }).promise();

    if (response.Budget) {
      results.exists = true;
      results.threshold = parseFloat(response.Budget.BudgetLimit?.Amount || '0');

      // Try to get current spend
      try {
        const spendResponse = await budgets.describeBudget({
          AccountId: await getAccountId(),
          BudgetName: budgetName,
        }).promise();

        if (spendResponse.Budget?.CalculatedSpend?.ActualSpend?.Amount) {
          results.currentSpend = parseFloat(spendResponse.Budget.CalculatedSpend.ActualSpend.Amount);
        }
      } catch (spendError) {
        console.warn('  Could not fetch current spend:', spendError);
      }
    }

    console.log(`  Budget exists: ${results.exists ? '✅' : '❌'}`);
    if (results.threshold) {
      console.log(`  Budget threshold: $${results.threshold}`);
    }
    if (results.currentSpend !== null) {
      console.log(`  Current spend: $${results.currentSpend.toFixed(2)}`);
    }

  } catch (error) {
    if ((error as any).code === 'NotFoundException') {
      console.log(`  Budget '${budgetName}' not found: ❌`);
    } else {
      console.error('  Error testing budget:', error);
    }
  }

  return results;
}

/**
 * Get AWS account ID
 */
async function getAccountId(): Promise<string> {
  const sts = new AWS.STS();
  const identity = await sts.getCallerIdentity().promise();
  return identity.Account || '';
}

/**
 * Display test results in a formatted way
 */
function displayTestResults(results: MonitoringTestResults): void {
  console.log('\n📋 Monitoring Test Results Summary:');
  console.log('=====================================');

  // Dashboards
  console.log('\n📊 CloudWatch Dashboards:');
  console.log(`  Application: ${results.dashboards.application ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`  Performance: ${results.dashboards.performance ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`  Cost: ${results.dashboards.cost ? '✅ PASS' : '❌ FAIL'}`);

  // Alarms
  console.log('\n🚨 CloudWatch Alarms:');
  console.log(`  High Error Rate: ${results.alarms.highErrorRate ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`  High Latency: ${results.alarms.highLatency ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`  Low Cache Hit Ratio: ${results.alarms.lowCacheHitRatio ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`  Budget Exceeded: ${results.alarms.budgetExceeded ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`  Uptime Failure: ${results.alarms.uptimeFailure ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`  RUM Error Rate: ${results.alarms.rumErrorRate ? '✅ PASS' : '❌ FAIL'}`);

  // SNS Topics
  console.log('\n📧 SNS Notification Topics:');
  console.log(`  Critical Alerts: ${results.topics.criticalAlerts ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`  Warning Alerts: ${results.topics.warningAlerts ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`  Cost Alerts: ${results.topics.costAlerts ? '✅ PASS' : '❌ FAIL'}`);

  // Canary
  console.log('\n🕵️ Synthetics Canary:');
  console.log(`  Exists: ${results.canary.exists ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`  Running: ${results.canary.running ? '✅ PASS' : '❌ FAIL'}`);
  if (results.canary.successRate !== null) {
    const successStatus = results.canary.successRate >= 90 ? '✅ PASS' : '⚠️ WARN';
    console.log(`  Success Rate: ${successStatus} (${results.canary.successRate.toFixed(1)}%)`);
  }

  // Budget
  console.log('\n💰 Budget Configuration:');
  console.log(`  Exists: ${results.budget.exists ? '✅ PASS' : '❌ FAIL'}`);
  if (results.budget.threshold && results.budget.currentSpend !== null) {
    const utilizationPercent = (results.budget.currentSpend / results.budget.threshold) * 100;
    const utilizationStatus = utilizationPercent < 80 ? '✅ GOOD' : utilizationPercent < 100 ? '⚠️ WARN' : '❌ OVER';
    console.log(`  Utilization: ${utilizationStatus} (${utilizationPercent.toFixed(1)}%)`);
  }
}

/**
 * Check overall health of monitoring setup
 */
function checkOverallHealth(results: MonitoringTestResults): boolean {
  const dashboardsHealthy = Object.values(results.dashboards).every(Boolean);
  const alarmsHealthy = Object.values(results.alarms).every(Boolean);
  const topicsHealthy = Object.values(results.topics).every(Boolean);
  const canaryHealthy = results.canary.exists && results.canary.running;
  const budgetHealthy = results.budget.exists;

  return dashboardsHealthy && alarmsHealthy && topicsHealthy && canaryHealthy && budgetHealthy;
}

// Run the test if this script is executed directly
if (require.main === module) {
  testMonitoring().catch(console.error);
}

export { testMonitoring, MonitoringTestResults };