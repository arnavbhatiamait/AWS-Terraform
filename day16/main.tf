resource "aws_iam_user" "users" {
  for_each = { for user in local.users : user.first_name => user }
  name     = "${lower(substr(each.value.first_name, 0, 1))}_${lower(substr(each.value.last_name, 0, 1))}"
  path     = "/users/"
  tags = {
    "DisplayName" = "${each.value.first_name} ${each.value.last_name}"
    "Department"  = each.value.department
    "JobTitle"     = each.value.job_title
  }
}

resource "aws_iam_user_login_profile" "users" {
  for_each = aws_iam_user.users
  user     = each.value.name
  password_length = 16
  password_reset_required = true
  lifecycle{
    ignore_changes = [password_reset_required,password_length]
  }
}

resource "aws_secretsmanager_secret" "user_password" {
  for_each = aws_iam_user.users
  name = "${each.value.name}_password"
  
}

resource "aws_secretsmanager_secret_version" "user_password" {
  for_each = aws_iam_user.users
  secret_id     = aws_secretsmanager_secret.user_password[each.key].id
  secret_string =jsonencode({
    username = each.value.name,
    password = aws_iam_user_login_profile.users[each.key].password
  })
}
