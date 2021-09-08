variable project {
  description = "Project ID"
  type        = string
}

variable numnodes {
    description = "number of nodes"
    default     = 3
}

variable "region" {
  description = "gcp region"
  type        = string
  default     = "europe-west3"
}

variable "zone" {
  description = "gcp zone"
  type        = string
  default     = "europe-west3-c"
}

variable "credentials" {
    description = "path to or the contents of a service account key file in JSON format"
    type        = string
}

variable "ssh_pub_key" {
    description = "path for ssh pub key on you locla machine"
    type        = string
}

variable "ssh_secret_key" {
    description = "path for ssh secret key on you locla machine"
    type        = string
}

variable "user" {
    description = "user for connection to nodes"
    type        = string
}