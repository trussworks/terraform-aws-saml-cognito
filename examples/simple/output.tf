output "cognito_user_pool_arn" {
  value = module.saml_cognito.cognito_user_pool_arn
}

output "cognito_user_pool_client_id" {
  value = module.saml_cognito.cognito_user_pool_client_id
}
