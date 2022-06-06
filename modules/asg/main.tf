data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_launch_configuration" "launch-config-1" {
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  security_groups             = [var.security_group_id]
  associate_public_ip_address = false
  key_name                    = "my-key-pair-1"
  user_data = templatefile("${path.module}/startup.tpl",
    { username = var.username,
      password = var.password,
  rds_endpoint = var.rds_endpoint })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg-1" {
  name                      = "${var.project}-asg-1"
  launch_configuration      = aws_launch_configuration.launch-config-1.name
  vpc_zone_identifier       = var.subnet_id
  target_group_arns         = [var.target_group_arns]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  force_delete              = true
  min_size                  = 1
  max_size                  = 2

  tag {
    key                 = "Name"
    value               = "${var.project}-asg-1"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "asp-1" {
  name                   = "${var.project}-asp-1"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 180
  autoscaling_group_name = aws_autoscaling_group.asg-1.name
}

resource "aws_cloudwatch_metric_alarm" "alarm-1" {
  alarm_name          = "${var.project}-alarm-1"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "70"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg-1.name
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.asp-1.arn]
}
