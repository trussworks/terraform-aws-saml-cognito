locals {
  zone_name                = "infra-test.truss.coffee"
  idp_redirect_binding_uri = "https://samltest.id/idp/profile/SAML2/Redirect/SSO"
  environment              = "test"
}

data "aws_route53_zone" "infra_test_truss_coffee" {
  name = local.zone_name
}

data "local_file" "saml_metadata" {
  filename = "${path.module}/saml_metadata.xml"
}

module "saml_cognito" {
  # This dependency isn't normally needed. We're doing this here for
  # testing purposes to make sure that our A record is completed before
  # trying to create this.
  depends_on = [aws_route53_record.a_infra_test_truss_coffee]

  source = "../.."

  name                                   = var.test_name
  dns_name                               = "${var.test_name}-sso.${local.zone_name}"
  zone_id                                = data.aws_route53_zone.infra_test_truss_coffee.zone_id
  environment                            = local.environment
  saml_metadata_file_content             = data.local_file.saml_metadata.content
  saml_metadata_sso_redirect_binding_uri = local.idp_redirect_binding_uri
  relying_party_dns_names = [
    "${var.test_name}-site.${local.zone_name}"
  ]

  providers = {
    aws           = aws
    aws.us-east-1 = aws.us-east-1
  }
}


# Enabling AWS Cognitio requires a domain record, an A record at the
# apex of the domain. If not set you will see the following error from
# Cognito. This will just create an A record pointing to localhost.
# "Was not able to resolve the root domain, please ensure an A record exists for the root domain."
# This is strictly for our terratests.
resource "aws_route53_record" "a_infra_test_truss_coffee" {
  zone_id = data.aws_route53_zone.infra_test_truss_coffee.zone_id
  name    = data.aws_route53_zone.infra_test_truss_coffee.name
  type    = "A"
  ttl     = "3600"
  records = ["127.0.0.1"]
}
