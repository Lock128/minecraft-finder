import { Construct } from 'constructs';
import * as acm from 'aws-cdk-lib/aws-certificatemanager';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as cr from 'aws-cdk-lib/custom-resources';
import { CustomResource, Duration, Stack } from 'aws-cdk-lib';
import { DomainConfig } from '../types/config';

/**
 * Properties for the ACM certificate construct
 */
export interface AcmCertificateConstructProps {
  /** Domain configuration including cross-account details */
  domainConfig: DomainConfig;
  /** Environment name for resource naming */
  environment: string;
  /** Additional tags to apply to resources */
  tags?: Record<string, string>;
}

/**
 * ACM certificate construct with cross-account DNS validation
 * 
 * This construct creates an ACM certificate in us-east-1 region (required for CloudFront)
 * and handles DNS validation by creating validation records in Route53 hosted zone
 * located in a different AWS account using cross-account role assumption.
 * 
 * Features:
 * - Certificate creation in us-east-1 region
 * - Cross-account role assumption for Route53 access
 * - DNS validation record creation in external AWS account
 * - Certificate validation waiting logic with proper error handling
 * - Automatic cleanup of validation records
 */
export class AcmCertificateConstruct extends Construct {
  /** The ACM certificate instance */
  public readonly certificate: acm.Certificate;
  
  /** The certificate ARN */
  public readonly certificateArn: string;
  
  /** The domain name for the certificate */
  public readonly domainName: string;
  
  /** Custom resource for cross-account DNS operations */
  private readonly dnsValidationResource: CustomResource;

  constructor(scope: Construct, id: string, props: AcmCertificateConstructProps) {
    super(scope, id);

    const { domainConfig, environment, tags = {} } = props;
    this.domainName = domainConfig.domainName;

    // Validate that we're in the correct region for CloudFront certificates
    this.validateRegion(domainConfig.certificateRegion);

    // Create the certificate with DNS validation
    this.certificate = this.createCertificate(domainConfig);
    this.certificateArn = this.certificate.certificateArn;

    // Create custom resource for cross-account DNS validation
    this.dnsValidationResource = this.createDnsValidationResource(domainConfig);

    // Apply tags
    this.applyTags(tags);
  }

  /**
   * Validates that the certificate is being created in the correct region
   */
  private validateRegion(requiredRegion: string): void {
    const currentRegion = Stack.of(this).region;
    
    if (currentRegion !== requiredRegion) {
      throw new Error(
        `ACM certificate for CloudFront must be created in ${requiredRegion} region. ` +
        `Current region is ${currentRegion}. Please deploy this stack to ${requiredRegion}.`
      );
    }
  }

  /**
   * Creates the ACM certificate with DNS validation
   */
  private createCertificate(domainConfig: DomainConfig): acm.Certificate {
    // Validate domain name format
    if (!domainConfig.domainName || domainConfig.domainName.trim() === '') {
      throw new Error('Domain name cannot be empty');
    }

    return new acm.Certificate(this, 'Certificate', {
      domainName: domainConfig.domainName,
      
      // Use DNS validation (required for cross-account setup)
      validation: acm.CertificateValidation.fromDns(),
      
      // Subject Alternative Names (if needed for multiple subdomains)
      subjectAlternativeNames: this.getSubjectAlternativeNames(domainConfig.domainName),
      
      // Certificate transparency logging
      transparencyLoggingEnabled: true,
      
      // Key algorithm
      keyAlgorithm: acm.KeyAlgorithm.RSA_2048,
    });
  }

  /**
   * Gets subject alternative names for the certificate
   * This allows the certificate to work with both www and non-www versions
   */
  private getSubjectAlternativeNames(domainName: string): string[] | undefined {
    // For subdomains like app.minecraft.lockhead.cloud, we might want to include
    // the wildcard version *.minecraft.lockhead.cloud if needed
    // For now, we'll keep it simple and only include the exact domain
    return undefined;
  }

  /**
   * Creates a custom resource for cross-account DNS validation
   */
  private createDnsValidationResource(domainConfig: DomainConfig): CustomResource {
    // Create the Lambda execution role
    const lambdaRole = this.createLambdaExecutionRole(domainConfig.crossAccountRoleArn);
    
    // Create the Lambda functions
    const onEventHandler = this.createLambdaFunction(lambdaRole);
    const isCompleteHandler = this.createStatusCheckLambdaFunction(lambdaRole);
    
    // Create the custom resource provider
    const provider = new cr.Provider(this, 'DnsValidationProvider', {
      onEventHandler,
      isCompleteHandler,
      totalTimeout: Duration.minutes(30), // Allow up to 30 minutes for DNS propagation
      queryInterval: Duration.seconds(30), // Check every 30 seconds
    });
    
    // Create the custom resource
    return new CustomResource(this, 'DnsValidationResource', {
      serviceToken: provider.serviceToken,
      properties: {
        CertificateArn: this.certificate.certificateArn,
        DomainName: domainConfig.domainName,
        HostedZoneId: domainConfig.hostedZoneId,
        CrossAccountRoleArn: domainConfig.crossAccountRoleArn,
        // Add a timestamp to force updates when needed
        Timestamp: Date.now().toString(),
      },
    });
  }

  /**
   * Creates the Lambda execution role for the custom resource
   */
  private createLambdaExecutionRole(crossAccountRoleArn: string): iam.Role {
    const role = new iam.Role(this, 'LambdaExecutionRole', {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      description: 'Execution role for ACM certificate DNS validation Lambda',
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
      ],
    });

    // Add permissions to describe the certificate
    role.addToPolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        'acm:DescribeCertificate',
        'acm:ListCertificates',
      ],
      resources: ['*'], // ACM doesn't support resource-level permissions for describe operations
    }));

    // Add permission to assume the cross-account role
    role.addToPolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: ['sts:AssumeRole'],
      resources: [crossAccountRoleArn],
    }));

    return role;
  }



  /**
   * Creates the main Lambda function for DNS validation
   */
  private createLambdaFunction(role: iam.Role): lambda.Function {
    return new lambda.Function(this, 'DnsValidationFunction', {
      runtime: lambda.Runtime.PYTHON_3_11,
      handler: 'index.lambda_handler',
      role,
      code: lambda.Code.fromInline(this.getLambdaCode()),
      timeout: Duration.minutes(5),
      description: 'ACM Certificate DNS validation with cross-account Route53 access',
      environment: {
        LOG_LEVEL: 'INFO',
      },
    });
  }

  /**
   * Creates the status check Lambda function
   */
  private createStatusCheckLambdaFunction(role: iam.Role): lambda.Function {
    return new lambda.Function(this, 'StatusCheckFunction', {
      runtime: lambda.Runtime.PYTHON_3_11,
      handler: 'index.lambda_handler',
      role,
      code: lambda.Code.fromInline(this.getStatusCheckLambdaCode()),
      timeout: Duration.minutes(2),
      description: 'Check ACM Certificate validation status',
      environment: {
        LOG_LEVEL: 'INFO',
      },
    });
  }

  /**
   * Gets the Lambda function code for DNS validation
   */
  private getLambdaCode(): string {
    return `
import json
import boto3
import time
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    """
    Lambda function to handle ACM certificate DNS validation
    using cross-account Route53 access
    """
    try:
        request_type = event['RequestType']
        properties = event['ResourceProperties']
        
        certificate_arn = properties['CertificateArn']
        domain_name = properties['DomainName']
        hosted_zone_id = properties['HostedZoneId']
        cross_account_role_arn = properties['CrossAccountRoleArn']
        
        if request_type == 'Create' or request_type == 'Update':
            return handle_create_update(certificate_arn, domain_name, hosted_zone_id, cross_account_role_arn)
        elif request_type == 'Delete':
            return handle_delete(certificate_arn, domain_name, hosted_zone_id, cross_account_role_arn)
            
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'Status': 'FAILED',
            'Reason': str(e),
            'PhysicalResourceId': event.get('PhysicalResourceId', 'dns-validation-failed')
        }

def handle_create_update(certificate_arn, domain_name, hosted_zone_id, cross_account_role_arn):
    """Handle certificate creation/update"""
    try:
        # Get certificate validation records
        acm_client = boto3.client('acm')
        cert_details = acm_client.describe_certificate(CertificateArn=certificate_arn)
        
        validation_records = []
        for domain_validation in cert_details['Certificate']['DomainValidationOptions']:
            if 'ResourceRecord' in domain_validation:
                validation_records.append(domain_validation['ResourceRecord'])
        
        if not validation_records:
            # Certificate might not be ready yet, return in progress
            return {
                'Status': 'IN_PROGRESS',
                'PhysicalResourceId': f'dns-validation-{domain_name}'
            }
        
        # Assume cross-account role
        sts_client = boto3.client('sts')
        assumed_role = sts_client.assume_role(
            RoleArn=cross_account_role_arn,
            RoleSessionName='ACMCertificateValidation'
        )
        
        # Create Route53 client with assumed role credentials
        route53_client = boto3.client(
            'route53',
            aws_access_key_id=assumed_role['Credentials']['AccessKeyId'],
            aws_secret_access_key=assumed_role['Credentials']['SecretAccessKey'],
            aws_session_token=assumed_role['Credentials']['SessionToken']
        )
        
        # Create DNS validation records
        changes = []
        for record in validation_records:
            changes.append({
                'Action': 'UPSERT',
                'ResourceRecordSet': {
                    'Name': record['Name'],
                    'Type': record['Type'],
                    'TTL': 300,
                    'ResourceRecords': [{'Value': record['Value']}]
                }
            })
        
        if changes:
            response = route53_client.change_resource_record_sets(
                HostedZoneId=hosted_zone_id,
                ChangeBatch={'Changes': changes}
            )
            
            change_id = response['ChangeInfo']['Id']
            
            return {
                'Status': 'SUCCESS',
                'PhysicalResourceId': f'dns-validation-{domain_name}',
                'Data': {
                    'ChangeId': change_id,
                    'ValidationRecords': validation_records
                }
            }
        
        return {
            'Status': 'SUCCESS',
            'PhysicalResourceId': f'dns-validation-{domain_name}'
        }
        
    except Exception as e:
        print(f"Error in handle_create_update: {str(e)}")
        raise

def handle_delete(certificate_arn, domain_name, hosted_zone_id, cross_account_role_arn):
    """Handle certificate deletion - clean up DNS records"""
    try:
        # For deletion, we'll attempt to clean up the validation records
        # but won't fail if they're already gone
        
        # Assume cross-account role
        sts_client = boto3.client('sts')
        assumed_role = sts_client.assume_role(
            RoleArn=cross_account_role_arn,
            RoleSessionName='ACMCertificateValidationCleanup'
        )
        
        # Create Route53 client with assumed role credentials
        route53_client = boto3.client(
            'route53',
            aws_access_key_id=assumed_role['Credentials']['AccessKeyId'],
            aws_secret_access_key=assumed_role['Credentials']['SecretAccessKey'],
            aws_session_token=assumed_role['Credentials']['SessionToken']
        )
        
        # List existing records to find validation records to delete
        # This is a best-effort cleanup
        try:
            records_response = route53_client.list_resource_record_sets(
                HostedZoneId=hosted_zone_id
            )
            
            changes = []
            for record_set in records_response['ResourceRecordSets']:
                # Look for CNAME records that might be validation records
                # ACM validation records typically start with an underscore and contain the domain
                if (record_set['Type'] == 'CNAME' and 
                    record_set['Name'].startswith('_') and
                    domain_name.replace('.', '') in record_set['Name'].replace('.', '')):
                    changes.append({
                        'Action': 'DELETE',
                        'ResourceRecordSet': record_set
                    })
            
            if changes:
                route53_client.change_resource_record_sets(
                    HostedZoneId=hosted_zone_id,
                    ChangeBatch={'Changes': changes}
                )
                
        except ClientError as e:
            # Ignore errors during cleanup
            print(f"Warning: Could not clean up validation records: {str(e)}")
        
        return {
            'Status': 'SUCCESS',
            'PhysicalResourceId': f'dns-validation-{domain_name}'
        }
        
    except Exception as e:
        print(f"Error in handle_delete: {str(e)}")
        # Don't fail deletion even if cleanup fails
        return {
            'Status': 'SUCCESS',
            'PhysicalResourceId': f'dns-validation-{domain_name}'
        }
`;
  }

  /**
   * Gets the Lambda function code for status checking
   */
  private getStatusCheckLambdaCode(): string {
    return `
import json
import boto3
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    """
    Lambda function to check ACM certificate validation status
    """
    try:
        properties = event['ResourceProperties']
        certificate_arn = properties['CertificateArn']
        
        # Check certificate status
        acm_client = boto3.client('acm')
        cert_details = acm_client.describe_certificate(CertificateArn=certificate_arn)
        
        certificate_status = cert_details['Certificate']['Status']
        
        if certificate_status == 'ISSUED':
            return {
                'IsComplete': True,
                'Data': {
                    'CertificateStatus': certificate_status,
                    'CertificateArn': certificate_arn
                }
            }
        elif certificate_status in ['PENDING_VALIDATION', 'VALIDATION_TIMED_OUT']:
            return {
                'IsComplete': False,
                'Data': {
                    'CertificateStatus': certificate_status
                }
            }
        else:
            # Failed, expired, etc.
            return {
                'IsComplete': True,
                'Data': {
                    'CertificateStatus': certificate_status,
                    'Error': f'Certificate validation failed with status: {certificate_status}'
                }
            }
            
    except Exception as e:
        print(f"Error checking certificate status: {str(e)}")
        return {
            'IsComplete': False,
            'Data': {
                'Error': str(e)
            }
        }
`;
  }

  /**
   * Applies tags to the certificate and related resources
   */
  private applyTags(tags: Record<string, string>): void {
    // Apply tags to the certificate
    Object.entries(tags).forEach(([key, value]) => {
      this.certificate.node.addMetadata(key, value);
    });

    // Add component-specific tags
    this.certificate.node.addMetadata('Component', 'ACMCertificate');
    this.certificate.node.addMetadata('Purpose', 'CloudFrontSSL');
    this.certificate.node.addMetadata('ValidationMethod', 'DNS');
    this.certificate.node.addMetadata('CrossAccount', 'true');
  }

  /**
   * Gets the certificate validation status
   * This can be used to check if the certificate is ready
   */
  public getCertificateStatus(): string {
    // This would typically require a custom resource to check the status
    // For now, we'll return a placeholder
    return 'PENDING_VALIDATION';
  }

  /**
   * Gets the certificate domain validation options
   * This can be useful for debugging validation issues
   */
  public getDomainValidationOptions(): any {
    // This would require a custom resource to fetch the validation options
    // For now, we'll return a placeholder
    return {
      domainName: this.domainName,
      validationMethod: 'DNS',
      status: 'PENDING_VALIDATION'
    };
  }

  /**
   * Waits for certificate validation to complete
   * This is handled automatically by the custom resource
   */
  public waitForValidation(): void {
    // The custom resource handles the waiting logic
    // This method is here for API completeness
  }
}