import { Construct } from 'constructs';
import * as logs from 'aws-cdk-lib/aws-logs';
import { Duration, Stack, RemovalPolicy } from 'aws-cdk-lib';

/**
 * Error severity levels
 */
export enum ErrorSeverity {
  LOW = 'LOW',
  MEDIUM = 'MEDIUM',
  HIGH = 'HIGH',
  CRITICAL = 'CRITICAL'
}

/**
 * Error categories for better classification
 */
export enum ErrorCategory {
  CONFIGURATION = 'CONFIGURATION',
  DEPLOYMENT = 'DEPLOYMENT',
  VALIDATION = 'VALIDATION',
  NETWORK = 'NETWORK',
  PERMISSIONS = 'PERMISSIONS',
  RESOURCE_CREATION = 'RESOURCE_CREATION',
  CROSS_ACCOUNT = 'CROSS_ACCOUNT',
  TIMEOUT = 'TIMEOUT'
}

/**
 * Structured error information
 */
export interface StructuredError {
  code: string;
  message: string;
  severity: ErrorSeverity;
  category: ErrorCategory;
  context?: Record<string, any>;
  timestamp: string;
  stackTrace?: string;
  retryable: boolean;
  suggestedAction?: string;
}

/**
 * Retry configuration
 */
export interface RetryConfig {
  maxAttempts: number;
  baseDelay: number;
  maxDelay: number;
  backoffMultiplier: number;
  retryableErrors: string[];
}

/**
 * Default retry configuration
 */
export const DEFAULT_RETRY_CONFIG: RetryConfig = {
  maxAttempts: 3,
  baseDelay: 1000,
  maxDelay: 30000,
  backoffMultiplier: 2,
  retryableErrors: [
    'ThrottlingException',
    'ServiceUnavailableException',
    'InternalServerError',
    'RequestTimeout',
    'NetworkError',
    'TemporaryFailure'
  ]
};

/**
 * Enhanced error handler for CDK constructs
 */
export class ErrorHandler {
  private readonly logGroup: logs.LogGroup;
  private readonly context: Record<string, any>;

  constructor(scope: Construct, id: string, context: Record<string, any> = {}) {
    this.context = context;
    
    // Create CloudWatch log group for error logging
    this.logGroup = new logs.LogGroup(scope, `${id}ErrorLogs`, {
      logGroupName: `/aws/cdk/${Stack.of(scope).stackName}/${id}/errors`,
      retention: logs.RetentionDays.ONE_MONTH,
      removalPolicy: context.environment === 'prod' ? 
        RemovalPolicy.RETAIN : 
        RemovalPolicy.DESTROY,
    });
  }

  /**
   * Creates a structured error with context
   */
  public createError(
    code: string,
    message: string,
    severity: ErrorSeverity,
    category: ErrorCategory,
    context?: Record<string, any>,
    retryable: boolean = false,
    suggestedAction?: string
  ): StructuredError {
    const error: StructuredError = {
      code,
      message,
      severity,
      category,
      context: { ...this.context, ...context },
      timestamp: new Date().toISOString(),
      retryable,
      suggestedAction
    };

    // Capture stack trace for debugging
    const stack = new Error().stack;
    if (stack) {
      error.stackTrace = stack;
    }

    return error;
  }

  /**
   * Logs an error with structured format
   */
  public logError(error: StructuredError): void {
    const logMessage = {
      level: 'ERROR',
      severity: error.severity,
      category: error.category,
      code: error.code,
      message: error.message,
      context: error.context,
      timestamp: error.timestamp,
      retryable: error.retryable,
      suggestedAction: error.suggestedAction,
      stackTrace: error.stackTrace
    };

    console.error(`[${error.severity}] ${error.category}: ${error.code} - ${error.message}`);
    console.error('Context:', JSON.stringify(error.context, null, 2));
    
    if (error.suggestedAction) {
      console.error('Suggested Action:', error.suggestedAction);
    }

    // In a real implementation, this would send to CloudWatch Logs
    // For now, we'll log to console with structured format
    console.error('Structured Error Log:', JSON.stringify(logMessage, null, 2));
  }

  /**
   * Handles and logs an error, then throws it
   */
  public handleError(
    code: string,
    message: string,
    severity: ErrorSeverity,
    category: ErrorCategory,
    context?: Record<string, any>,
    suggestedAction?: string
  ): never {
    const error = this.createError(code, message, severity, category, context, false, suggestedAction);
    this.logError(error);
    throw new Error(`${code}: ${message}`);
  }

  /**
   * Executes a function with retry logic
   */
  public async withRetry<T>(
    operation: () => Promise<T>,
    operationName: string,
    retryConfig: Partial<RetryConfig> = {}
  ): Promise<T> {
    const config = { ...DEFAULT_RETRY_CONFIG, ...retryConfig };
    let lastError: Error | undefined;

    for (let attempt = 1; attempt <= config.maxAttempts; attempt++) {
      try {
        console.log(`Attempting ${operationName} (attempt ${attempt}/${config.maxAttempts})`);
        return await operation();
      } catch (error) {
        lastError = error as Error;
        
        const isRetryable = this.isRetryableError(error as Error, config.retryableErrors);
        const isLastAttempt = attempt === config.maxAttempts;

        if (!isRetryable || isLastAttempt) {
          const structuredError = this.createError(
            'OPERATION_FAILED',
            `${operationName} failed after ${attempt} attempt(s): ${lastError.message}`,
            isLastAttempt ? ErrorSeverity.HIGH : ErrorSeverity.MEDIUM,
            ErrorCategory.DEPLOYMENT,
            {
              operationName,
              attempt,
              maxAttempts: config.maxAttempts,
              isRetryable,
              originalError: lastError.message
            },
            isRetryable && !isLastAttempt,
            isRetryable ? 'Check network connectivity and AWS service status' : 'Review error details and fix underlying issue'
          );

          this.logError(structuredError);
          
          if (isLastAttempt) {
            throw lastError;
          }
        }

        if (attempt < config.maxAttempts) {
          const delay = Math.min(
            config.baseDelay * Math.pow(config.backoffMultiplier, attempt - 1),
            config.maxDelay
          );
          
          console.log(`Retrying ${operationName} in ${delay}ms...`);
          await this.sleep(delay);
        }
      }
    }

    throw lastError;
  }

  /**
   * Validates a condition and throws structured error if false
   */
  public validate(
    condition: boolean,
    code: string,
    message: string,
    category: ErrorCategory = ErrorCategory.VALIDATION,
    context?: Record<string, any>,
    suggestedAction?: string
  ): void {
    if (!condition) {
      this.handleError(code, message, ErrorSeverity.HIGH, category, context, suggestedAction);
    }
  }

  /**
   * Validates that a value is not null or undefined
   */
  public validateRequired<T>(
    value: T | null | undefined,
    fieldName: string,
    context?: Record<string, any>
  ): T {
    if (value === null || value === undefined) {
      this.handleError(
        'REQUIRED_FIELD_MISSING',
        `Required field '${fieldName}' is missing or null`,
        ErrorSeverity.HIGH,
        ErrorCategory.VALIDATION,
        { fieldName, ...context },
        `Provide a valid value for '${fieldName}'`
      );
    }
    return value;
  }

  /**
   * Validates AWS resource ARN format
   */
  public validateArn(arn: string, resourceType: string, context?: Record<string, any>): void {
    const arnPattern = /^arn:aws:[a-zA-Z0-9-]+:[a-zA-Z0-9-]*:\d{12}:[a-zA-Z0-9-\/]+$/;
    
    this.validate(
      arnPattern.test(arn),
      'INVALID_ARN_FORMAT',
      `Invalid ARN format for ${resourceType}: ${arn}`,
      ErrorCategory.VALIDATION,
      { arn, resourceType, ...context },
      `Provide a valid AWS ARN in the format: arn:aws:service:region:account:resource`
    );
  }

  /**
   * Validates domain name format
   */
  public validateDomainName(domainName: string, context?: Record<string, any>): void {
    const domainPattern = /^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\.([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\.)*[a-zA-Z]{2,}$/;
    
    this.validate(
      domainPattern.test(domainName),
      'INVALID_DOMAIN_FORMAT',
      `Invalid domain name format: ${domainName}`,
      ErrorCategory.VALIDATION,
      { domainName, ...context },
      'Provide a valid domain name (e.g., app.example.com)'
    );
  }

  /**
   * Validates AWS region format
   */
  public validateRegion(region: string, allowedRegions?: string[], context?: Record<string, any>): void {
    const regionPattern = /^[a-z]{2}-[a-z]+-\d{1}$/;
    
    this.validate(
      regionPattern.test(region),
      'INVALID_REGION_FORMAT',
      `Invalid AWS region format: ${region}`,
      ErrorCategory.VALIDATION,
      { region, ...context },
      'Provide a valid AWS region (e.g., us-east-1, eu-west-1)'
    );

    if (allowedRegions && allowedRegions.length > 0) {
      this.validate(
        allowedRegions.includes(region),
        'REGION_NOT_ALLOWED',
        `Region ${region} is not allowed. Allowed regions: ${allowedRegions.join(', ')}`,
        ErrorCategory.VALIDATION,
        { region, allowedRegions, ...context },
        `Use one of the allowed regions: ${allowedRegions.join(', ')}`
      );
    }
  }

  /**
   * Creates a timeout wrapper for operations
   */
  public async withTimeout<T>(
    operation: () => Promise<T>,
    timeoutMs: number,
    operationName: string
  ): Promise<T> {
    const timeoutPromise = new Promise<never>((_, reject) => {
      setTimeout(() => {
        const error = this.createError(
          'OPERATION_TIMEOUT',
          `${operationName} timed out after ${timeoutMs}ms`,
          ErrorSeverity.HIGH,
          ErrorCategory.TIMEOUT,
          { operationName, timeoutMs },
          true,
          'Increase timeout value or check for underlying performance issues'
        );
        this.logError(error);
        reject(new Error(error.message));
      }, timeoutMs);
    });

    return Promise.race([operation(), timeoutPromise]);
  }

  /**
   * Checks if an error is retryable based on error patterns
   */
  private isRetryableError(error: Error, retryableErrors: string[]): boolean {
    const errorMessage = error.message.toLowerCase();
    const errorName = error.name;

    return retryableErrors.some(pattern => 
      errorMessage.includes(pattern.toLowerCase()) || 
      errorName.includes(pattern)
    );
  }

  /**
   * Sleep utility for retry delays
   */
  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Gets the CloudWatch log group for external access
   */
  public getLogGroup(): logs.LogGroup {
    return this.logGroup;
  }

  /**
   * Creates a child error handler with additional context
   */
  public createChild(additionalContext: Record<string, any>): ErrorHandler {
    // Create a new instance with merged context
    const childHandler = Object.create(ErrorHandler.prototype);
    childHandler.logGroup = this.logGroup;
    childHandler.context = { ...this.context, ...additionalContext };
    return childHandler;
  }
}

/**
 * Pre-configured error handlers for common scenarios
 */
export class CommonErrorHandlers {
  /**
   * Creates error handler for S3 operations
   */
  static createS3ErrorHandler(scope: Construct, context: Record<string, any>): ErrorHandler {
    return new ErrorHandler(scope, 'S3Operations', {
      service: 'S3',
      ...context
    });
  }

  /**
   * Creates error handler for CloudFront operations
   */
  static createCloudFrontErrorHandler(scope: Construct, context: Record<string, any>): ErrorHandler {
    return new ErrorHandler(scope, 'CloudFrontOperations', {
      service: 'CloudFront',
      ...context
    });
  }

  /**
   * Creates error handler for ACM operations
   */
  static createACMErrorHandler(scope: Construct, context: Record<string, any>): ErrorHandler {
    return new ErrorHandler(scope, 'ACMOperations', {
      service: 'ACM',
      ...context
    });
  }

  /**
   * Creates error handler for Route53 operations
   */
  static createRoute53ErrorHandler(scope: Construct, context: Record<string, any>): ErrorHandler {
    return new ErrorHandler(scope, 'Route53Operations', {
      service: 'Route53',
      ...context
    });
  }

  /**
   * Creates error handler for CloudWatch operations
   */
  static createCloudWatchErrorHandler(scope: Construct, context: Record<string, any>): ErrorHandler {
    return new ErrorHandler(scope, 'CloudWatchOperations', {
      service: 'CloudWatch',
      ...context
    });
  }
}