import { Construct } from 'constructs';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as cr from 'aws-cdk-lib/custom-resources';
import { CustomResource, Duration } from 'aws-cdk-lib';
import { DomainConfig } from '../types/config';

/**
 * Properties for the DNS management construct
 */
export interface DnsManagementConstructProps {
  /** Domain configuration including cross-account details */
  domainConfig: DomainConfig;
  /** CloudFront distribution domain name to point to */
  cloudFrontDomainName: string;
  /** Environment name for resource naming */
  environment: string;
  /** Additional tags to apply to resources */
  tags?: Record<string, string>;
}

/**
 * DNS management construct for cross-account Route53 operations
 * 
 * This construct manages DNS records in a Route53 hosted zone located in a different
 * AWS account using cross-account role assumption. It creates CNAME records pointing
 * the custom subdomain to the CloudFront distribution.
 * 
 * Features:
 * - Cross-account role assumption for Route53 access
 * - CNAME record creation pointing subdomain to CloudFront distribution
 * - Proper error handling for cross-account failures
 * - Validation checks for DNS configuration
 * - Automatic cleanup of DNS records on stack deletion
 * - Retry logic for transient failures
 */
export class DnsManagementConstruct extends Construct {
  /** The domain name being managed */
  public readonly domainName: string;
  
  /** The CloudFront domain name being pointed to */
  public readonly cloudFrontDomainName: string;
  
  /** Custom resource for cross-account DNS operations */
  private readonly dnsManagementResource: CustomResource;
  
  /** The hosted zone ID */
  public readonly hostedZoneId: string;

  constructor(scope: Construct, id: string, props: DnsManagementConstructProps) {
    super(scope, id);

    const { domainConfig, cloudFrontDomainName, environment, tags = {} } = props;
    
    // Validate inputs
    this.validateInputs(domainConfig, cloudFrontDomainName);
    
    this.domainName = domainConfig.domainName;
    this.cloudFrontDomainName = cloudFrontDomainName;
    this.hostedZoneId = domainConfig.hostedZoneId;

    // Create custom resource for cross-account DNS management
    this.dnsManagementResource = this.createDnsManagementResource(domainConfig, cloudFrontDomainName);

    // Apply tags
    this.applyTags(tags);
  }

  /**
   * Validates the input parameters
   */
  private validateInputs(domainConfig: DomainConfig, cloudFrontDomainName: string): void {
    if (!domainConfig.domainName || domainConfig.domainName.trim() === '') {
      throw new Error('Domain name cannot be empty');
    }

    if (!cloudFrontDomainName || cloudFrontDomainName.trim() === '') {
      throw new Error('CloudFront domain name cannot be empty');
    }

    if (!domainConfig.hostedZoneId || domainConfig.hostedZoneId.trim() === '') {
      throw new Error('Hosted zone ID cannot be empty');
    }

    if (!domainConfig.crossAccountRoleArn || domainConfig.crossAccountRoleArn.trim() === '') {
      throw new Error('Cross-account role ARN cannot be empty');
    }

    // Skip validation for CDK tokens (during synthesis/testing)
    if (this.isToken(cloudFrontDomainName) || this.isToken(domainConfig.domainName) || 
        this.isToken(domainConfig.hostedZoneId) || this.isToken(domainConfig.crossAccountRoleArn)) {
      return;
    }

    // Validate domain name format (basic validation)
    const domainRegex = /^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\.([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\.)*[a-zA-Z]{2,}$/;
    if (!domainRegex.test(domainConfig.domainName)) {
      throw new Error(`Invalid domain name format: ${domainConfig.domainName}`);
    }

    // Validate CloudFront domain name format
    const cloudFrontRegex = /^[a-zA-Z0-9][a-zA-Z0-9-]*\.cloudfront\.net$/;
    if (!cloudFrontRegex.test(cloudFrontDomainName)) {
      throw new Error(`Invalid CloudFront domain name format: ${cloudFrontDomainName}`);
    }

    // Validate hosted zone ID format
    const hostedZoneRegex = /^Z[A-Z0-9]{10,32}$/;
    if (!hostedZoneRegex.test(domainConfig.hostedZoneId)) {
      throw new Error(`Invalid hosted zone ID format: ${domainConfig.hostedZoneId}`);
    }

    // Validate cross-account role ARN format
    const roleArnRegex = /^arn:aws:iam::\d{12}:role\/[a-zA-Z0-9+=,.@_-]+$/;
    if (!roleArnRegex.test(domainConfig.crossAccountRoleArn)) {
      throw new Error(`Invalid cross-account role ARN format: ${domainConfig.crossAccountRoleArn}`);
    }
  }

  /**
   * Checks if a value is a CDK token (used during synthesis)
   */
  private isToken(value: string): boolean {
    return value.includes('${Token[') || value.includes('#{') || value.startsWith('${') ||
           value.startsWith('REPLACE_WITH_');
  }

  /**
   * Creates a custom resource for cross-account DNS management
   */
  private createDnsManagementResource(domainConfig: DomainConfig, cloudFrontDomainName: string): CustomResource {
    // Create the Lambda execution role
    const lambdaRole = this.createLambdaExecutionRole(domainConfig.crossAccountRoleArn);
    
    // Create the Lambda function
    const onEventHandler = this.createLambdaFunction(lambdaRole);
    
    // Create the custom resource provider
    const provider = new cr.Provider(this, 'DnsManagementProvider', {
      onEventHandler,
    });
    
    // Create the custom resource
    return new CustomResource(this, 'DnsManagementResource', {
      serviceToken: provider.serviceToken,
      properties: {
        DomainName: domainConfig.domainName,
        CloudFrontDomainName: cloudFrontDomainName,
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
    const role = new iam.Role(this, 'DnsManagementLambdaRole', {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      description: 'Execution role for DNS management Lambda function',
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSLambdaBasicExecutionRole'),
      ],
    });

    // Add permission to assume the cross-account role
    role.addToPolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: ['sts:AssumeRole'],
      resources: [crossAccountRoleArn],
    }));

    return role;
  }

  /**
   * Creates the Lambda function for DNS management
   */
  private createLambdaFunction(role: iam.Role): lambda.Function {
    return new lambda.Function(this, 'DnsManagementFunction', {
      runtime: lambda.Runtime.PYTHON_3_11,
      handler: 'index.lambda_handler',
      role,
      code: lambda.Code.fromInline(this.getLambdaCode()),
      timeout: Duration.minutes(5),
      description: 'DNS management with cross-account Route53 access',
      environment: {
        LOG_LEVEL: 'INFO',
      },
    });
  }

  /**
   * Gets the Lambda function code for DNS management
   */
  private getLambdaCode(): string {
    return `
import json
import boto3
import time
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    """
    Lambda function to handle DNS record management
    using cross-account Route53 access
    """
    try:
        request_type = event['RequestType']
        properties = event['ResourceProperties']
        
        domain_name = properties['DomainName']
        cloudfront_domain_name = properties['CloudFrontDomainName']
        hosted_zone_id = properties['HostedZoneId']
        cross_account_role_arn = properties['CrossAccountRoleArn']
        
        print(f"Processing {request_type} request for domain {domain_name}")
        
        if request_type == 'Create' or request_type == 'Update':
            return handle_create_update(domain_name, cloudfront_domain_name, hosted_zone_id, cross_account_role_arn)
        elif request_type == 'Delete':
            return handle_delete(domain_name, hosted_zone_id, cross_account_role_arn)
            
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'Status': 'FAILED',
            'Reason': str(e),
            'PhysicalResourceId': event.get('PhysicalResourceId', f'dns-management-{properties.get("DomainName", "unknown")}')
        }

def handle_create_update(domain_name, cloudfront_domain_name, hosted_zone_id, cross_account_role_arn):
    """Handle DNS record creation/update"""
    try:
        print(f"Creating/updating CNAME record for {domain_name} -> {cloudfront_domain_name}")
        
        # Assume cross-account role
        route53_client = assume_cross_account_role(cross_account_role_arn)
        
        # Validate hosted zone exists and is accessible
        validate_hosted_zone(route53_client, hosted_zone_id, domain_name)
        
        # Create or update the CNAME record
        change_response = route53_client.change_resource_record_sets(
            HostedZoneId=hosted_zone_id,
            ChangeBatch={
                'Comment': f'CNAME record for {domain_name} pointing to CloudFront distribution',
                'Changes': [{
                    'Action': 'UPSERT',
                    'ResourceRecordSet': {
                        'Name': domain_name,
                        'Type': 'CNAME',
                        'TTL': 300,  # 5 minutes TTL for faster updates during deployment
                        'ResourceRecords': [{'Value': cloudfront_domain_name}]
                    }
                }]
            }
        )
        
        change_id = change_response['ChangeInfo']['Id']
        print(f"DNS change submitted with ID: {change_id}")
        
        # Wait for the change to propagate (with timeout)
        wait_for_dns_change(route53_client, change_id)
        
        # Verify the record was created correctly
        verify_dns_record(route53_client, hosted_zone_id, domain_name, cloudfront_domain_name)
        
        return {
            'Status': 'SUCCESS',
            'PhysicalResourceId': f'dns-management-{domain_name}',
            'Data': {
                'ChangeId': change_id,
                'DomainName': domain_name,
                'CloudFrontDomainName': cloudfront_domain_name,
                'RecordType': 'CNAME'
            }
        }
        
    except Exception as e:
        print(f"Error in handle_create_update: {str(e)}")
        raise

def handle_delete(domain_name, hosted_zone_id, cross_account_role_arn):
    """Handle DNS record deletion"""
    try:
        print(f"Deleting CNAME record for {domain_name}")
        
        # Assume cross-account role
        route53_client = assume_cross_account_role(cross_account_role_arn)
        
        # First, check if the record exists
        try:
            records_response = route53_client.list_resource_record_sets(
                HostedZoneId=hosted_zone_id,
                StartRecordName=domain_name,
                StartRecordType='CNAME',
                MaxItems='1'
            )
            
            record_to_delete = None
            for record_set in records_response['ResourceRecordSets']:
                if record_set['Name'].rstrip('.') == domain_name and record_set['Type'] == 'CNAME':
                    record_to_delete = record_set
                    break
            
            if record_to_delete:
                # Delete the record
                change_response = route53_client.change_resource_record_sets(
                    HostedZoneId=hosted_zone_id,
                    ChangeBatch={
                        'Comment': f'Delete CNAME record for {domain_name}',
                        'Changes': [{
                            'Action': 'DELETE',
                            'ResourceRecordSet': record_to_delete
                        }]
                    }
                )
                
                change_id = change_response['ChangeInfo']['Id']
                print(f"DNS deletion submitted with ID: {change_id}")
                
                # Wait for the change to propagate
                wait_for_dns_change(route53_client, change_id)
                
            else:
                print(f"CNAME record for {domain_name} not found, nothing to delete")
                
        except ClientError as e:
            error_code = e.response['Error']['Code']
            if error_code in ['NoSuchHostedZone', 'InvalidInput']:
                print(f"Hosted zone or record not found during deletion: {str(e)}")
                # Don't fail deletion if the resource is already gone
            else:
                raise
        
        return {
            'Status': 'SUCCESS',
            'PhysicalResourceId': f'dns-management-{domain_name}'
        }
        
    except Exception as e:
        print(f"Error in handle_delete: {str(e)}")
        # Don't fail deletion even if cleanup fails
        return {
            'Status': 'SUCCESS',
            'PhysicalResourceId': f'dns-management-{domain_name}',
            'Data': {
                'Warning': f'Cleanup may have failed: {str(e)}'
            }
        }

def assume_cross_account_role(cross_account_role_arn):
    """Assume the cross-account role and return Route53 client"""
    try:
        sts_client = boto3.client('sts')
        
        print(f"Assuming role: {cross_account_role_arn}")
        assumed_role = sts_client.assume_role(
            RoleArn=cross_account_role_arn,
            RoleSessionName='DNSManagement',
            DurationSeconds=3600  # 1 hour
        )
        
        # Create Route53 client with assumed role credentials
        route53_client = boto3.client(
            'route53',
            aws_access_key_id=assumed_role['Credentials']['AccessKeyId'],
            aws_secret_access_key=assumed_role['Credentials']['SecretAccessKey'],
            aws_session_token=assumed_role['Credentials']['SessionToken']
        )
        
        return route53_client
        
    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'AccessDenied':
            raise Exception(f"Access denied when assuming role {cross_account_role_arn}. Check role permissions and trust policy.")
        elif error_code == 'InvalidUserID.NotFound':
            raise Exception(f"Cross-account role not found: {cross_account_role_arn}")
        else:
            raise Exception(f"Failed to assume cross-account role: {str(e)}")

def validate_hosted_zone(route53_client, hosted_zone_id, domain_name):
    """Validate that the hosted zone exists and can manage the domain"""
    try:
        # Get hosted zone details
        response = route53_client.get_hosted_zone(Id=hosted_zone_id)
        hosted_zone = response['HostedZone']
        
        zone_name = hosted_zone['Name'].rstrip('.')
        
        # Check if the domain is within this hosted zone
        if not domain_name.endswith(zone_name):
            raise Exception(f"Domain {domain_name} is not within hosted zone {zone_name}")
        
        print(f"Validated hosted zone {hosted_zone_id} for domain {domain_name}")
        
    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'NoSuchHostedZone':
            raise Exception(f"Hosted zone {hosted_zone_id} not found")
        elif error_code == 'AccessDenied':
            raise Exception(f"Access denied to hosted zone {hosted_zone_id}")
        else:
            raise Exception(f"Failed to validate hosted zone: {str(e)}")

def wait_for_dns_change(route53_client, change_id, max_wait_time=600):
    """Wait for DNS change to propagate"""
    start_time = time.time()
    
    while time.time() - start_time < max_wait_time:
        try:
            response = route53_client.get_change(Id=change_id)
            status = response['ChangeInfo']['Status']
            
            if status == 'INSYNC':
                print(f"DNS change {change_id} completed successfully")
                return
            
            print(f"DNS change {change_id} status: {status}, waiting...")
            time.sleep(10)
            
        except ClientError as e:
            print(f"Error checking change status: {str(e)}")
            time.sleep(10)
    
    raise Exception(f"DNS change {change_id} did not complete within {max_wait_time} seconds")

def verify_dns_record(route53_client, hosted_zone_id, domain_name, expected_value):
    """Verify that the DNS record was created correctly"""
    try:
        records_response = route53_client.list_resource_record_sets(
            HostedZoneId=hosted_zone_id,
            StartRecordName=domain_name,
            StartRecordType='CNAME',
            MaxItems='1'
        )
        
        for record_set in records_response['ResourceRecordSets']:
            if record_set['Name'].rstrip('.') == domain_name and record_set['Type'] == 'CNAME':
                actual_value = record_set['ResourceRecords'][0]['Value']
                if actual_value == expected_value:
                    print(f"DNS record verified: {domain_name} -> {actual_value}")
                    return
                else:
                    raise Exception(f"DNS record mismatch: expected {expected_value}, got {actual_value}")
        
        raise Exception(f"DNS record not found after creation: {domain_name}")
        
    except ClientError as e:
        print(f"Warning: Could not verify DNS record: {str(e)}")
        # Don't fail the operation if verification fails
`;
  }

  /**
   * Applies tags to the DNS management resources
   */
  private applyTags(tags: Record<string, string>): void {
    // Apply tags to the custom resource
    Object.entries(tags).forEach(([key, value]) => {
      this.dnsManagementResource.node.addMetadata(key, value);
    });

    // Add component-specific tags
    this.dnsManagementResource.node.addMetadata('Component', 'DNSManagement');
    this.dnsManagementResource.node.addMetadata('Purpose', 'CrossAccountDNS');
    this.dnsManagementResource.node.addMetadata('RecordType', 'CNAME');
    this.dnsManagementResource.node.addMetadata('CrossAccount', 'true');
  }

  /**
   * Gets the DNS record information
   */
  public getDnsRecordInfo(): { domainName: string; target: string; type: string } {
    return {
      domainName: this.domainName,
      target: this.cloudFrontDomainName,
      type: 'CNAME'
    };
  }

  /**
   * Gets the hosted zone ID
   */
  public getHostedZoneId(): string {
    return this.hostedZoneId;
  }

  /**
   * Validates the DNS configuration
   * This method can be used to perform additional validation checks
   */
  public validateDnsConfiguration(): boolean {
    // Basic validation - more comprehensive validation is done in the Lambda function
    return !!(this.domainName && this.cloudFrontDomainName && this.hostedZoneId);
  }
}