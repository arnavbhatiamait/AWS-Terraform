output "account_id" {
  value = data.aws_caller_identity.name
}
output "usernames" {
  value = [for user in local.users: "${user.first_name} ${user.last_name}"]
}