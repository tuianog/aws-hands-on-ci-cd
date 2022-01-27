locals {
  secret_name          = "test_webhook"
  # Use Bitbucket technical user
  # Get the webhook configured secret from Keepass
  secret_payload = {
    "privateKey"    = "Paste the private key here"
    "webhookSecret" = "Paste the configured webhook secret here"
  }
}

resource "aws_secretsmanager_secret" "ssh_secrets_manager" {
  name                    = local.secret_name
  description             = "Private secret for webhook"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "ssh_secrets_manager_version" {
  secret_id     = aws_secretsmanager_secret.ssh_secrets_manager.id
  secret_string = jsonencode(local.secret_payload)
}