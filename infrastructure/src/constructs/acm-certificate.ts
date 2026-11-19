import { Construct } from 'constructs';
import * as acm from 'aws-cdk-lib/aws-certificatemanager';
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
 * The certificate is requested by a custom resource Lambda (ACM RequestCertificate)
 * instead of an AWS::CertificateManager::Certificate resource. A CloudFormation
 * certificate resource only reaches CREATE_COMPLETE once the certificate is ISSUED,
 * which requires the DNS validation records to exist. Because the hosted zone lives in
 * another AWS account, those records can only be written by our own Lambda, which needs
 * the certificate's validation CNAMEs first. Using a CloudFormation certificate here
 * would therefore deadlock until the deployment times out.
 *
 * Flow (all inside the custom resource):
 * 1. onEvent: request the certificate, read the validation CNAMEs, upsert them into the
 *    Route53 zone using the cross-account role. PhysicalResourceId is the certificate ARN.
 * 2. isComplete: poll until the certificate status is ISSUED (fails on FAILED etc.).
 * 3. On delete: remove the validation records and delete the certificate.
 */
export class AcmCertificateConstruct extends Construct {
  /** The ACM certificate (imported by ARN from the custom resource) */
  public readonly certificate: acm.ICertificate;

  /** The certificate ARN (resolves once the certificate is ISSUED) */
  public readonly certificateArn: string;

  /** The domain name for the certificate */
  public readonly domainName: string;

  /** Custom resource that requests and validates the certificate */
  private readonly dnsValidationResource: CustomResource;

  constructor(scope: Construct, id: string, props: AcmCertificateConstructProps) {
    super(scope, id);

    const { domainConfig, tags = {} } = props;
    this.domainName = domainConfig.domainName;

    // Validate that we're in the correct region for CloudFront certificates
    this.validateRegion(domainConfig.certificateRegion);

    // Validate domain name format
    if (!domainConfig.domainName || domainConfig.domainName.trim() === '') {
      throw new Error('Domain name cannot be empty');
    }

    // Custom resource requests the certificate and creates the cross-account DNS records
    this.dnsValidationResource = this.createDnsValidationResource(domainConfig);
    this.certificateArn = this.dnsValidationResource.getAttString('CertificateArn');
    this.certificate = acm.Certificate.fromCertificateArn(this, 'Certificate', this.certificateArn);

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
      // DNS validation normally completes within a few minutes. Fail well before the
      // CI job timeout so CloudFormation reports a clear error and rolls back.
      totalTimeout: Duration.minutes(20),
      queryInterval: Duration.seconds(30),
    });

    // No Timestamp property: the resource only updates when its inputs change
    return new CustomResource(this, 'DnsValidationResource', {
      serviceToken: provider.serviceToken,
      properties: {
        DomainName: domainConfig.domainName,
        HostedZoneId: domainConfig.hostedZoneId,
        CrossAccountRoleArn: domainConfig.crossAccountRoleArn,
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

    // Add permissions to request, describe and delete the certificate
    role.addToPolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        'acm:RequestCertificate',
        'acm:DescribeCertificate',
        'acm:DeleteCertificate',
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
      description: 'ACM Certificate request and DNS validation with cross-account Route53 access',
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
import boto3
import time
from botocore.exceptions import ClientError

def get_route53(role_arn, session_name):
    creds = boto3.client('sts').assume_role(
        RoleArn=role_arn, RoleSessionName=session_name)['Credentials']
    return boto3.client(
        'route53',
        aws_access_key_id=creds['AccessKeyId'],
        aws_secret_access_key=creds['SecretAccessKey'],
        aws_session_token=creds['SessionToken'])

def wait_for_validation_records(acm_client, arn, timeout=120):
    """ACM populates ResourceRecord a few seconds after RequestCertificate"""
    deadline = time.time() + timeout
    while True:
        cert = acm_client.describe_certificate(CertificateArn=arn)['Certificate']
        records = [o['ResourceRecord'] for o in cert.get('DomainValidationOptions', [])
                   if 'ResourceRecord' in o]
        if records or time.time() > deadline:
            return records
        time.sleep(5)

def lambda_handler(event, context):
    request_type = event['RequestType']
    props = event['ResourceProperties']
    domain_name = props['DomainName']
    hosted_zone_id = props['HostedZoneId']
    role_arn = props['CrossAccountRoleArn']
    acm_client = boto3.client('acm')

    old_domain = event.get('OldResourceProperties', {}).get('DomainName')
    if request_type == 'Create' or (request_type == 'Update' and old_domain != domain_name):
        token = ''.join(c for c in event['RequestId'] if c.isalnum())[:32]
        arn = acm_client.request_certificate(
            DomainName=domain_name,
            ValidationMethod='DNS',
            IdempotencyToken=token,
            Options={'CertificateTransparencyLoggingPreference': 'ENABLED'},
        )['CertificateArn']
        records = wait_for_validation_records(acm_client, arn)
        if not records:
            raise Exception(f'ACM did not return DNS validation records for {arn}')
        route53 = get_route53(role_arn, 'ACMCertificateValidation')
        route53.change_resource_record_sets(
            HostedZoneId=hosted_zone_id,
            ChangeBatch={'Changes': [{
                'Action': 'UPSERT',
                'ResourceRecordSet': {
                    'Name': r['Name'], 'Type': r['Type'], 'TTL': 300,
                    'ResourceRecords': [{'Value': r['Value']}],
                }} for r in records]})
        return {'PhysicalResourceId': arn, 'Data': {'CertificateArn': arn}}

    arn = event['PhysicalResourceId']

    if request_type == 'Update':
        # A domain change is handled above as a new request; CloudFormation then
        # deletes the old certificate via the Delete cleanup
        return {'PhysicalResourceId': arn, 'Data': {'CertificateArn': arn}}

    # Delete: best-effort cleanup, never leave the stack stuck
    try:
        if arn.startswith('arn:'):
            cleanup(acm_client, arn, hosted_zone_id, role_arn)
    except Exception as e:
        print(f'Warning: cleanup failed: {e}')
    return {'PhysicalResourceId': arn}

def cleanup(acm_client, arn, hosted_zone_id, role_arn):
    try:
        cert = acm_client.describe_certificate(CertificateArn=arn)['Certificate']
    except ClientError as e:
        if e.response['Error']['Code'] == 'ResourceNotFoundException':
            return
        raise
    records = [o['ResourceRecord'] for o in cert.get('DomainValidationOptions', [])
               if 'ResourceRecord' in o]
    # Delete the certificate first (retry while CloudFront still releases it)
    for _ in range(20):
        try:
            acm_client.delete_certificate(CertificateArn=arn)
            break
        except ClientError as e:
            code = e.response['Error']['Code']
            if code == 'ResourceNotFoundException':
                break
            if code != 'ResourceInUseException':
                raise
            time.sleep(10)
    else:
        print(f'Warning: certificate {arn} still in use, leaving it in place')
        return
    if not records:
        return
    route53 = get_route53(role_arn, 'ACMCertificateValidationCleanup')
    for r in records:
        sets = route53.list_resource_record_sets(
            HostedZoneId=hosted_zone_id, StartRecordName=r['Name'],
            StartRecordType=r['Type'], MaxItems='1')['ResourceRecordSets']
        for rs in sets:
            if rs['Name'].rstrip('.') == r['Name'].rstrip('.') and rs['Type'] == r['Type']:
                route53.change_resource_record_sets(
                    HostedZoneId=hosted_zone_id,
                    ChangeBatch={'Changes': [{'Action': 'DELETE', 'ResourceRecordSet': rs}]})
`;
  }

  /**
   * Gets the Lambda function code for status checking
   */
  private getStatusCheckLambdaCode(): string {
    return `
import boto3

def lambda_handler(event, context):
    """Poll ACM until the certificate is ISSUED (called by the CDK Provider framework)"""
    if event['RequestType'] != 'Create':
        return {'IsComplete': True}

    arn = event['PhysicalResourceId']
    status = boto3.client('acm').describe_certificate(CertificateArn=arn)['Certificate']['Status']
    print(f'Certificate {arn} status: {status}')

    if status == 'ISSUED':
        return {'IsComplete': True}
    if status == 'PENDING_VALIDATION':
        return {'IsComplete': False}
    # FAILED, VALIDATION_TIMED_OUT, REVOKED, ... : fail the deployment with a clear reason
    raise Exception(f'Certificate {arn} entered unexpected status {status}')
`;
  }

  /**
   * Applies tags to the certificate and related resources
   */
  private applyTags(tags: Record<string, string>): void {
    Object.entries(tags).forEach(([key, value]) => {
      this.dnsValidationResource.node.addMetadata(key, value);
    });

    this.dnsValidationResource.node.addMetadata('Component', 'ACMCertificate');
    this.dnsValidationResource.node.addMetadata('Purpose', 'CloudFrontSSL');
    this.dnsValidationResource.node.addMetadata('ValidationMethod', 'DNS');
    this.dnsValidationResource.node.addMetadata('CrossAccount', 'true');
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