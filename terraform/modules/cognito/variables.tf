variable "region_name" {
  description = "리소스 이름 태그용 접두어"
  type        = string
}

variable "site_url" {
  description = "Public web origin allowed for Cognito OAuth callbacks"
  type        = string
}
