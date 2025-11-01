variable "instancetype" {
  type        = string
  default     = "t2.nano"
  description = "set aws instance type"
}

variable "aws_common_tag" {
  type        = map(any)
  description = "Set Aws Tag"
  default = {
    Name = "atp-easytraining"
  }
}