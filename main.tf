locals {
  # See: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-route53-aliastarget.html#cfn-route53-aliastarget-hostedzoneid
  cloudfront_zone_id = "Z2FDTNDATAQYW2"
}

data "aws_route53_zone" "selected" {
  zone_id = var.zone_id
}

resource "aws_cognito_user_pool" "saml" {
  name             = var.name
  alias_attributes = ["email"]

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true

    // Required to be mutable for any attribute that comes from a SAML IDP.
    mutable = true

    // These are just the defaults, but if you don't include them then you
    // trigger:
    // https://github.com/hashicorp/terraform-provider-aws/issues/3891
    // https://github.com/hashicorp/terraform-provider-aws/issues/4227
    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }
}

resource "aws_cognito_user_pool_client" "saml" {
  name                         = var.name
  user_pool_id                 = aws_cognito_user_pool.saml.id
  supported_identity_providers = [aws_cognito_identity_provider.saml.provider_name]
  callback_urls = toset(concat(
    [
      "https://${var.dns_name}",
      "https://${var.dns_name}/oauth2/idpresponse",
      "https://${var.dns_name}/saml2/idpresponse",
    ],
    sort(flatten([for dns_name in var.relying_party_dns_names :
      [
        "https://${dns_name}/",
        "https://${dns_name}/oauth2/idpresponse",
        "https://${dns_name}/saml2/idpresponse",
      ]
    ]))
  ))
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid"]
  generate_secret                      = true
}

module "auth_domain_certificate" {
  source = "trussworks/acm-cert/aws"

  domain_name = var.dns_name
  zone_id     = data.aws_route53_zone.selected.id

  providers = {
    aws = aws.us-east-1
  }
}

resource "aws_cognito_user_pool_domain" "saml" {
  domain          = var.dns_name
  user_pool_id    = aws_cognito_user_pool.saml.id
  certificate_arn = module.auth_domain_certificate.acm_arn
}

resource "aws_route53_record" "cognito_auth" {
  name    = var.dns_name
  zone_id = var.zone_id
  type    = "A"

  alias {
    name                   = aws_cognito_user_pool_domain.saml.cloudfront_distribution_arn
    zone_id                = local.cloudfront_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cognito_auth_ipv6" {
  name    = var.dns_name
  zone_id = var.zone_id
  type    = "AAAA"

  alias {
    name                   = aws_cognito_user_pool_domain.saml.cloudfront_distribution_arn
    zone_id                = local.cloudfront_zone_id
    evaluate_target_health = false
  }
}

resource "aws_cognito_identity_provider" "saml" {
  user_pool_id  = aws_cognito_user_pool.saml.id
  provider_name = var.name
  provider_type = "SAML"

  provider_details = {
    MetadataFile = var.saml_metadata_file_content
    // AWS actually computes this value automatically from the MetadataFile,
    // but if we don't specify it, terraform always thinks this resource has
    // changed:
    // https://github.com/terraform-providers/terraform-provider-aws/issues/4831
    SSORedirectBindingURI = var.saml_metadata_sso_redirect_binding_uri
  }

  attribute_mapping = {
    email = "email"
  }

  lifecycle {
    ignore_changes = [
      // This is a computed value, so we need to ignore it.
      provider_details["ActiveEncryptionCertificate"],
    ]
  }
}
