resource "aws_iam_role" "lambda-ebs-backup" {
  name = "lambda-ebs-backup"

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
    name        = "ebs-backup-worker"
    description = "ebs-backup-worker"
    policy = <<EOF
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
    role       = "${aws_iam_role.lambda-ebs-backup.name}"
    policy_arn = "${aws_iam_policy.ebs-backup-worker.arn}"
}

resource "aws_lambda_function" "ebs-backup" {
    filename         = "${path.module}/lambda/createSnapshot/createSnapshot.zip"
    function_name    = "createSnapshot"
    role             = "${aws_iam_role.lambda-ebs-backup.arn}"
    handler          = "createSnapshot.lambda_handler"
    source_code_hash = "${base64sha256(file("${path.module}/lambda/createSnapshot/createSnapshot.zip"))}"
    runtime          = "python2.7"

    environment {
        variables = {
            Source = "Terraform"
        }
    }
}
resource "aws_lambda_function" "ebs-backup-delete" {
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
