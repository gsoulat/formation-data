variable "organization_name" {
  description = "Name of the GitHub organization"
  type        = string

}

variable "organization_display_name" {
  description = "Display name of the GitHub organization"
  type        = string
  default     = ""
}

variable "organization_description" {
  description = "Description of the GitHub organization"
  type        = string
  default     = ""
}

variable "organization_email" {
  description = "Email of the GitHub organization"
  type        = string
  default     = ""
}

variable "organization_blog" {
  description = "Blog URL of the GitHub organization"
  type        = string
  default     = ""
}

variable "organization_location" {
  description = "Location of the GitHub organization"
  type        = string
  default     = ""
}
