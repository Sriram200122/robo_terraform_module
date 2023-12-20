################# Policy ###################
resource "aws_iam_policy" "policy" {
  name        = "${var.component}.${var.env}.ssm.policy"
  path        = "/"
  description = "Used to access the ssm parameters"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameter*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "test_role" {
  name               = "${var.component}.${var.env}.ec2.Role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Sid       = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

  ################ I am instance profile#####################
  resource "aws_iam_instance_profile" "profile" {
    name = "${var.component}.${var.env}"
    role = aws_iam_role.role.name
  }

  ################ Policy attachment##############
  resource "aws_iam_role_policy_attachment" "attach" {
    role       = "${var.component}.${var.env}"
    policy_arn = aws_iam_policy.policy.arn
  }

  ###### create ec2 instance terraform with vpc######
  resource "aws_instance" "web" {
    ami                    = data.aws_ami.example.id
    instance_type          = "t2.micro"
    vpc_security_group_ids = [aws_security_group.sg.id]
    iam_instance_profile = aws_iam_instance_profile.profile.name

    tags = {
      Name = "${var.component}.${var.env}"
    }
  }

  ################ creating provisioner with null resource ################
  resource "null_resource" "ansible" {
    depends_on = [aws_instance.web, aws_route53_record.www]
    provisioner "remote-exec" {
      connection {
        type     = "ssh"
        user     = "centos"
        password = "DevOps321"
        host     = aws_instance.web.public_ip
      }
      inline = [
        "sudo labauto ansible",
        "ansible-pull -i localhost, -U https://github.com/Suryakumari76k/robo-ansible roboshop.yml -e env=dev -e role_name=${var.component}"
      ]
    }
  }

  ######### Security group terraform ##########
  resource "aws_security_group" "sg" {
    name        = "${var.component}.${var.env}"
    description = "Allow TLS inbound traffic"

    ingress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
    }

    egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
      Name = "${var.component}.${var.env}"
    }
  }

  ################# creating dns records #################
  resource "aws_route53_record" "www" {
    zone_id = "Z01768852GJ4FV6EFJ9QG"
    name    = "${var.component}.${var.env}"
    type    = "A"
    ttl     = 300
    records = [aws_instance.web.private_ip]
  }




