variable "name" {
  description = "Name prefix for global resources"
  type        = string
}

variable "domain_name" {
  description = "Route53 domain name"
  type        = string
}

variable "create_route53_zone" {
  description = "Whether to create a new Route53 hosted zone"
  type        = bool
  default     = true
}

variable "primary_alb_dns_name" {
  description = "Primary region ALB DNS name"
  type        = string
}

variable "primary_alb_zone_id" {
  description = "Primary region ALB hosted zone ID"
  type        = string
}

variable "dr_alb_dns_name" {
  description = "DR region ALB DNS name"
  type        = string
}

variable "dr_alb_zone_id" {
  description = "DR region ALB hosted zone ID"
  type        = string
}

variable "primary_alb_origin_id" {
  description = "CloudFront origin ID for the primary ALB"
  type        = string
  default     = "primary-alb"
}

variable "dr_alb_origin_id" {
  description = "CloudFront origin ID for the DR ALB"
  type        = string
  default     = "dr-alb"
}

variable "tags" {
  description = "Tags applied to all global resources"
  type        = map(string)
  default     = {}
}
