resource "aws_iam_role" "lambda-ebs-backup" {
    provider           = "aws.${var.region}"
    name               = "lambda-ebs-backup"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
resource "aws_iam_policy" "ebs-backup-worker" {
    provider    = "aws.${var.region}"
    name        = "ebs-backup-worker"
    description = "ebs-backup-worker"
    policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:*"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": "ec2:Describe*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateSnapshot",
                "ec2:DeleteSnapshot",
                "ec2:CreateTags",
                "ec2:ModifySnapshotAttribute",
                "ec2:ResetSnapshotAttribute"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "sns:Publish"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "describe-attach" {
    provider   = "aws.${var.region}"
    role       = "${aws_iam_role.lambda-ebs-backup.name}"
    policy_arn = "${aws_iam_policy.ebs-backup-worker.arn}"
}

resource "aws_lambda_function" "ebs-backup-create" {
    provider         = "aws.${var.region}"
    filename         = "${path.module}/lambda/createSnapshot/createSnapshot.zip"
    function_name    = "createSnapshot"
    role             = "${aws_iam_role.lambda-ebs-backup.arn}"
    handler          = "createSnapshot.lambda_handler"
    source_code_hash = "${base64sha256(file("${path.module}/lambda/createSnapshot/createSnapshot.zip"))}"
    runtime          = "python2.7"

    environment {
        variables = {
            Source  = "Terraform"
            Project = "${var.project}"
        }
    }
}
resource "aws_lambda_function" "ebs-backup-delete" {
    provider         = "aws.${var.region}"
    filename         = "${path.module}/lambda/deleteSnapshot/deleteSnapshot.zip"
    function_name    = "deleteSnapshot"
    role             = "${aws_iam_role.lambda-ebs-backup.arn}"
    handler          = "deleteSnapshot.lambda_handler"
    source_code_hash = "${base64sha256(file("${path.module}/lambda/deleteSnapshot/deleteSnapshot.zip"))}"
    runtime          = "python2.7"

    environment {
        variables = {
            Source = "Terraform"
        }
    }
}
resource "aws_cloudwatch_event_rule" "every_day" {
    provider            = "aws.${var.region}"
    name                = "every-day"
    description         = "Fires every day"
    schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "snapshot_every_day" {
    provider  = "aws.${var.region}"
    rule      = "${aws_cloudwatch_event_rule.every_day.name}"
    target_id = "takeSnapshot"
    arn       = "${aws_lambda_function.ebs-backup-create.arn}"
}
resource "aws_cloudwatch_event_target" "cleanup_every_day" {
    provider  = "aws.${var.region}"
    rule      = "${aws_cloudwatch_event_rule.every_day.name}"
    target_id = "cleanSnapshot"
    arn       = "${aws_lambda_function.ebs-backup-delete.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_EBSToSnapshotBackup" {
    provider      = "aws.${var.region}"
    statement_id  = "AllowExecutionFromCloudWatch"
    action        = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.ebs-backup-create.function_name}"
    principal     = "events.amazonaws.com"
    source_arn    = "${aws_cloudwatch_event_rule.every_day.arn}"
}
resource "aws_lambda_permission" "allow_cloudwatch_to_call_EBSToSnapshotCleanup" {
    provider      = "aws.${var.region}"
    statement_id  = "AllowExecutionFromCloudWatch"
    action        = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.ebs-backup-delete.function_name}"
    principal     = "events.amazonaws.com"
    source_arn    = "${aws_cloudwatch_event_rule.every_day.arn}"
}
