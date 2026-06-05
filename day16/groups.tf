resource "aws_iam_group" "education" {
  name = "education"
  path = "/groups/"
}
resource "aws_iam_group" "engineer" {
  name = "engineer"
  path = "/groups/"
}
resource "aws_iam_group" "managers" {
  name = "managers"
  path = "/groups/"
}
resource "aws_iam_group_membership" "education_members"{
    name = "education_membership"
    group = aws_iam_group.education.name
    users = [for user in aws_iam_user.users: user.name if user.tags.Department == "Education"]
}
resource "aws_iam_group_membership" "engineer_members"{
    name = "engineer_membership"
    group = aws_iam_group.engineer.name
    users = [for user in aws_iam_user.users: user.name if user.tags.Department == "Engineering"]
}
# Managers group will have users from both management and engineering department
resource "aws_iam_group_membership" "managers_members"{
    name = "managers_membership"
    group = aws_iam_group.managers.name
    users = [for user in aws_iam_user.users : user.name if contains(keys(user.tags), "JobTitle") && can(regex("Manager|CEO", user.tags.JobTitle))]
}
