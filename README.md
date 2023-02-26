# `terraform-aws-saml-cognito`

Provisions AWS Cognito resources for connecting SAML authentication.

This gives you a user pool, user pool client, and user pool domain (using a
custom domain with a certificate and both A and AAAA records), which can be
used with ALB's authentication support.

## Usage Example

In order to use this module, you will need to define a `us-east-1` provider using the following code:

```hcl
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}
```

Process wise, you'll need to setup and download the SAML Metadata XML file from your chosen IDP, then create the Terraform resources.

Using GSuite for example, you'll use the following configuration values in the GSuite admin:

- `ACS URL`: `https://{dns_name}/saml2/idpresponse`
- `Entity ID`: `urn:amazon:cognito:sp:{id}` where `id` is the final component
  of the Cognito User Pool ARN.
- `Name ID Format`: `EMAIL`
- `Attribute Mapping`:
  - Add a value named `email` which maps to `Primary Email`

```hcl
module "saml_cognito" {
  source = "trussworks/saml-cognito/aws"

  name                                   = "GSuiteSAML"
  dns_name                               = "cognito-sso.my-corp.com"
  zone_id                                = aws_route53_zone.my_corp.zone_id
  saml_metadata_file_content             = file("cognito-gsuite-saml-metadata.xml")
  saml_metadata_sso_redirect_binding_uri = "https://accounts.google.com/o/saml2/idp?idpid=<id>"
  relying_party_dns_names                = ["my-app.int.my-corp.com", "my-other-app.int.my-corp.com"]

  providers = {
    aws           = aws
    aws.us-east-1 = aws.us-east-1
  }
}
```

This will leave you with Cognito resources, that use
`https://cognito-sso.my-corp.com` as the domain that is a RP for the GSuite
SAML IDP. It can be used to provide authentication for apps running on the
domains `my-app.int.my-corp.com` and `my-other-app.int.my-corp.com`.


## Terraform Versions

- Terraform 0.13 and newer. Pin module version to ~> 3.0. Submit pull requests to `main` branch.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13 |
| aws | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| auth\_domain\_certificate | trussworks/acm-cert/aws | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cognito_identity_provider.saml](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_identity_provider) | resource |
| [aws_cognito_user_pool.saml](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool) | resource |
| [aws_cognito_user_pool_client.saml](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_client) | resource |
| [aws_cognito_user_pool_domain.saml](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_domain) | resource |
| [aws_route53_record.cognito_auth](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cognito_auth_ipv6](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| dns\_name | DNS name for the authenticate page (e.g. `auth.my-company.com`) | `string` | n/a | yes |
| environment | Environment tag. e.g. prod | `string` | n/a | yes |
| name | Name for the various cognito resources | `string` | n/a | yes |
| relying\_party\_dns\_names | List of DNS names for the relying parties (i.e. the applications you are authenticating with this) | `list(string)` | n/a | yes |
| saml\_metadata\_file\_content | Contents of the SAML metadata file | `string` | n/a | yes |
| saml\_metadata\_sso\_redirect\_binding\_uri | The HTTP-Redirect SSO binding from the SAML metadata file. Must be kept in sync with saml\_metadata\_file\_content! | `string` | n/a | yes |
| zone\_id | Route53 zone id to put DNS records in | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| cognito\_user\_pool\_arn | ARN for the Cognito User Pool |
| cognito\_user\_pool\_client\_id | ID for the Cognito User Pool Client |
| cognito\_user\_pool\_domain | Name for the Cognito User Pool Domain |
<!-- END_TF_DOCS -->

## Attribution

This module has been based on [alloy-commons/alloy-open-source](https://github.com/alloy-commons/alloy-open-source/tree/master/terraform-modules/gsuite-saml-cognito)
