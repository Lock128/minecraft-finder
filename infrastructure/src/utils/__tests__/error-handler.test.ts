import { Construct } from 'constructs';
import { App, Stack } from 'aws-cdk-lib';
import { ErrorHandler, ErrorSeverity, ErrorCategory, CommonErrorHandlers } from '../error-handler';

// Jest provides describe, it, beforeEach globally - no need to import

describe('ErrorHandler', () => {
  let app: App;
  let stack: Stack;
  let errorHandler: ErrorHandler;

  beforeEach(() => {
    app = new App();
    stack = new Stack(app, 'TestStack');
    errorHandler = new ErrorHandler(stack, 'TestErrorHandler', { environment: 'test' });
  });

  describe('createError', () => {
    it('should create a structured error with all properties', () => {
      const error = errorHandler.createError(
        'TEST_ERROR',
        'Test error message',
        ErrorSeverity.HIGH,
        ErrorCategory.VALIDATION,
        { testContext: 'value' },
        true,
        'Test suggested action'
      );

      expect(error.code).toBe('TEST_ERROR');
      expect(error.message).toBe('Test error message');
      expect(error.severity).toBe(ErrorSeverity.HIGH);
      expect(error.category).toBe(ErrorCategory.VALIDATION);
      expect(error.context).toEqual({ environment: 'test', testContext: 'value' });
      expect(error.retryable).toBe(true);
      expect(error.suggestedAction).toBe('Test suggested action');
      expect(error.timestamp).toBeDefined();
      expect(error.stackTrace).toBeDefined();
    });

    it('should include stack trace in error', () => {
      const error = errorHandler.createError(
        'TEST_ERROR',
        'Test message',
        ErrorSeverity.LOW,
        ErrorCategory.CONFIGURATION
      );

      expect(error.stackTrace).toContain('error-handler.test.ts');
    });
  });

  describe('validate', () => {
    it('should not throw when condition is true', () => {
      expect(() => {
        errorHandler.validate(true, 'TEST_CODE', 'Test message');
      }).not.toThrow();
    });

    it('should throw structured error when condition is false', () => {
      expect(() => {
        errorHandler.validate(false, 'TEST_CODE', 'Test message', ErrorCategory.VALIDATION);
      }).toThrow('TEST_CODE: Test message');
    });
  });

  describe('validateRequired', () => {
    it('should return value when not null or undefined', () => {
      const value = 'test-value';
      const result = errorHandler.validateRequired(value, 'testField');
      expect(result).toBe(value);
    });

    it('should throw error when value is null', () => {
      expect(() => {
        errorHandler.validateRequired(null, 'testField');
      }).toThrow('REQUIRED_FIELD_MISSING: Required field \'testField\' is missing or null');
    });

    it('should throw error when value is undefined', () => {
      expect(() => {
        errorHandler.validateRequired(undefined, 'testField');
      }).toThrow('REQUIRED_FIELD_MISSING: Required field \'testField\' is missing or null');
    });
  });

  describe('validateArn', () => {
    it('should validate correct ARN format', () => {
      const validArn = 'arn:aws:iam::123456789012:role/test-role';
      expect(() => {
        errorHandler.validateArn(validArn, 'IAM Role');
      }).not.toThrow();
    });

    it('should throw error for invalid ARN format', () => {
      const invalidArn = 'invalid-arn-format';
      expect(() => {
        errorHandler.validateArn(invalidArn, 'IAM Role');
      }).toThrow('INVALID_ARN_FORMAT');
    });
  });

  describe('validateDomainName', () => {
    it('should validate correct domain name', () => {
      const validDomain = 'app.example.com';
      expect(() => {
        errorHandler.validateDomainName(validDomain);
      }).not.toThrow();
    });

    it('should throw error for invalid domain name', () => {
      const invalidDomain = 'invalid..domain';
      expect(() => {
        errorHandler.validateDomainName(invalidDomain);
      }).toThrow('INVALID_DOMAIN_FORMAT');
    });
  });

  describe('validateRegion', () => {
    it('should validate correct region format', () => {
      const validRegion = 'us-east-1';
      expect(() => {
        errorHandler.validateRegion(validRegion);
      }).not.toThrow();
    });

    it('should throw error for invalid region format', () => {
      const invalidRegion = 'invalid-region';
      expect(() => {
        errorHandler.validateRegion(invalidRegion);
      }).toThrow('INVALID_REGION_FORMAT');
    });

    it('should validate allowed regions', () => {
      const region = 'us-west-2';
      const allowedRegions = ['us-east-1', 'us-west-2'];
      expect(() => {
        errorHandler.validateRegion(region, allowedRegions);
      }).not.toThrow();
    });

    it('should throw error for disallowed region', () => {
      const region = 'eu-west-1';
      const allowedRegions = ['us-east-1', 'us-west-2'];
      expect(() => {
        errorHandler.validateRegion(region, allowedRegions);
      }).toThrow('REGION_NOT_ALLOWED');
    });
  });

  describe('withRetry', () => {
    it('should succeed on first attempt', async () => {
      const operation = jest.fn().mockResolvedValue('success');
      
      const result = await errorHandler.withRetry(operation, 'Test Operation');
      
      expect(result).toBe('success');
      expect(operation).toHaveBeenCalledTimes(1);
    });

    it('should retry on retryable error', async () => {
      const operation = jest.fn()
        .mockRejectedValueOnce(new Error('ThrottlingException'))
        .mockResolvedValue('success');
      
      const result = await errorHandler.withRetry(
        operation, 
        'Test Operation',
        { maxAttempts: 2, baseDelay: 10 }
      );
      
      expect(result).toBe('success');
      expect(operation).toHaveBeenCalledTimes(2);
    });

    it('should not retry on non-retryable error', async () => {
      const operation = jest.fn().mockRejectedValue(new Error('ValidationError'));
      
      await expect(
        errorHandler.withRetry(operation, 'Test Operation', { maxAttempts: 3 })
      ).rejects.toThrow('ValidationError');
      
      expect(operation).toHaveBeenCalledTimes(1);
    });

    it('should fail after max attempts', async () => {
      const operation = jest.fn().mockRejectedValue(new Error('ThrottlingException'));
      
      await expect(
        errorHandler.withRetry(
          operation, 
          'Test Operation',
          { maxAttempts: 2, baseDelay: 10 }
        )
      ).rejects.toThrow('ThrottlingException');
      
      expect(operation).toHaveBeenCalledTimes(2);
    });
  });

  describe('withTimeout', () => {
    it('should complete operation within timeout', async () => {
      const operation = () => Promise.resolve('success');
      
      const result = await errorHandler.withTimeout(operation, 1000, 'Test Operation');
      
      expect(result).toBe('success');
    });

    it('should timeout long-running operation', async () => {
      const operation = () => new Promise(resolve => setTimeout(() => resolve('success'), 200));
      
      await expect(
        errorHandler.withTimeout(operation, 100, 'Test Operation')
      ).rejects.toThrow('Test Operation timed out after 100ms');
    });
  });

  describe('createChild', () => {
    it('should create child handler with merged context', () => {
      const childHandler = errorHandler.createChild({ childContext: 'value' });
      
      const error = childHandler.createError(
        'TEST_ERROR',
        'Test message',
        ErrorSeverity.LOW,
        ErrorCategory.CONFIGURATION
      );
      
      expect(error.context).toEqual({
        environment: 'test',
        childContext: 'value'
      });
    });
  });
});

describe('CommonErrorHandlers', () => {
  let app: App;
  let stack: Stack;

  beforeEach(() => {
    app = new App();
    stack = new Stack(app, 'TestStack');
  });

  it('should create S3 error handler', () => {
    const handler = CommonErrorHandlers.createS3ErrorHandler(stack, { bucket: 'test' });
    
    const error = handler.createError(
      'TEST_ERROR',
      'Test message',
      ErrorSeverity.LOW,
      ErrorCategory.CONFIGURATION
    );
    
    expect(error.context).toEqual({
      service: 'S3',
      bucket: 'test'
    });
  });

  it('should create CloudFront error handler', () => {
    const handler = CommonErrorHandlers.createCloudFrontErrorHandler(stack, { distribution: 'test' });
    
    const error = handler.createError(
      'TEST_ERROR',
      'Test message',
      ErrorSeverity.LOW,
      ErrorCategory.CONFIGURATION
    );
    
    expect(error.context).toEqual({
      service: 'CloudFront',
      distribution: 'test'
    });
  });

  it('should create ACM error handler', () => {
    const handler = CommonErrorHandlers.createACMErrorHandler(stack, { certificate: 'test' });
    
    const error = handler.createError(
      'TEST_ERROR',
      'Test message',
      ErrorSeverity.LOW,
      ErrorCategory.CONFIGURATION
    );
    
    expect(error.context).toEqual({
      service: 'ACM',
      certificate: 'test'
    });
  });

  it('should create Route53 error handler', () => {
    const handler = CommonErrorHandlers.createRoute53ErrorHandler(stack, { hostedZone: 'test' });
    
    const error = handler.createError(
      'TEST_ERROR',
      'Test message',
      ErrorSeverity.LOW,
      ErrorCategory.CONFIGURATION
    );
    
    expect(error.context).toEqual({
      service: 'Route53',
      hostedZone: 'test'
    });
  });

  it('should create CloudWatch error handler', () => {
    const handler = CommonErrorHandlers.createCloudWatchErrorHandler(stack, { logGroup: 'test' });
    
    const error = handler.createError(
      'TEST_ERROR',
      'Test message',
      ErrorSeverity.LOW,
      ErrorCategory.CONFIGURATION
    );
    
    expect(error.context).toEqual({
      service: 'CloudWatch',
      logGroup: 'test'
    });
  });
});

// Error scenario integration tests
describe('Error Scenarios Integration Tests', () => {
  let app: App;
  let stack: Stack;
  let errorHandler: ErrorHandler;

  beforeEach(() => {
    app = new App();
    stack = new Stack(app, 'TestStack');
    errorHandler = new ErrorHandler(stack, 'TestErrorHandler', { environment: 'test' });
  });

  describe('Configuration Errors', () => {
    it('should handle missing configuration gracefully', () => {
      expect(() => {
        errorHandler.validateRequired(undefined, 'config');
      }).toThrow('REQUIRED_FIELD_MISSING');
    });

    it('should handle invalid domain configuration', () => {
      expect(() => {
        errorHandler.validateDomainName('');
      }).toThrow('INVALID_DOMAIN_FORMAT');
    });

    it('should handle invalid ARN configuration', () => {
      expect(() => {
        errorHandler.validateArn('not-an-arn', 'Role');
      }).toThrow('INVALID_ARN_FORMAT');
    });
  });

  describe('Deployment Errors', () => {
    it('should handle timeout scenarios', async () => {
      const slowOperation = () => new Promise(resolve => setTimeout(resolve, 200));
      
      await expect(
        errorHandler.withTimeout(slowOperation, 100, 'Slow Operation')
      ).rejects.toThrow('Slow Operation timed out after 100ms');
    });

    it('should handle retry scenarios with exponential backoff', async () => {
      let attempts = 0;
      const flakyOperation = () => {
        attempts++;
        if (attempts < 3) {
          return Promise.reject(new Error('ThrottlingException'));
        }
        return Promise.resolve('success');
      };
      
      const result = await errorHandler.withRetry(
        flakyOperation,
        'Flaky Operation',
        { maxAttempts: 3, baseDelay: 10, backoffMultiplier: 2 }
      );
      
      expect(result).toBe('success');
      expect(attempts).toBe(3);
    });
  });

  describe('Cross-Account Errors', () => {
    it('should handle cross-account role assumption failures', () => {
      const invalidRoleArn = 'arn:aws:iam::invalid:role/test';
      
      expect(() => {
        errorHandler.validateArn(invalidRoleArn, 'Cross-account role');
      }).toThrow('INVALID_ARN_FORMAT');
    });
  });

  describe('Network Errors', () => {
    it('should handle network timeout errors', async () => {
      const networkOperation = () => new Promise((_, reject) => {
        setTimeout(() => reject(new Error('NetworkError')), 50);
      });
      
      await expect(
        errorHandler.withRetry(
          networkOperation,
          'Network Operation',
          { maxAttempts: 2, baseDelay: 10 }
        )
      ).rejects.toThrow('NetworkError');
    });
  });

  describe('Permission Errors', () => {
    it('should handle permission denied scenarios', async () => {
      const permissionDeniedOperation = () => Promise.reject(new Error('AccessDenied'));
      
      await expect(
        errorHandler.withRetry(
          permissionDeniedOperation,
          'Permission Operation',
          { maxAttempts: 1 } // Don't retry permission errors
        )
      ).rejects.toThrow('AccessDenied');
    });
  });

  describe('Resource Creation Errors', () => {
    it('should handle resource limit exceeded errors', async () => {
      const resourceLimitOperation = () => Promise.reject(new Error('LimitExceeded'));
      
      await expect(
        errorHandler.withRetry(
          resourceLimitOperation,
          'Resource Creation',
          { maxAttempts: 1 } // Don't retry limit errors
        )
      ).rejects.toThrow('LimitExceeded');
    });
  });
});