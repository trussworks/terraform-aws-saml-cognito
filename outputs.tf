output "cognito_user_pool_arn" {
  description = "ARN for the Cognito User Pool"
  value       = aws_cognito_user_pool.saml.arn
}

output "cognito_user_pool_client_id" {
  description = "ID for the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.saml.id
}

output "cognito_user_pool_domain" {
  description = "Name for the Cognito User Pool Domain"
  value       = var.dns_name
}
