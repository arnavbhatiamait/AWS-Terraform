output "account_id" {
  value = data.aws_caller_identity.name
}
output "usernames" {
  value = [for user in local.users: "${user.first_name} ${user.last_name}"]
}
output "password"{
  value = {for user,profile in aws_iam_user_login_profile.users: user => "Password created"}
  sensitive = true
}
output "secrets"{
  value = {for user,secret in aws_secretsmanager_secret.user_password: user => secret.arn}
  # sensitive = true
}