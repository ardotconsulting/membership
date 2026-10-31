# Input Variables
# https://www.terraform.io/language/values/variables

variable "admins" {
  description = "A set of admins to add to the organization"
  type        = set(string)
}

variable "super_admins" {
  description = "A set of users who have operational permissions to add to the organization"
  type        = set(string)
}

variable "members" {
  description = "A set of members to add to the organization"
  type        = set(string)
  default     = []
}

variable "organization_teams" {
  description = "Map of Ardot Consulting organization teams to manage"
  type = map(object({
    description               = string
    maintainers               = optional(set(string), [])
    members                   = optional(set(string), [])
    permission                = optional(string, null)
    privacy                   = optional(string, "closed")
    review_request_delegation = optional(bool, false)
  }))
}