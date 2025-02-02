variable "eks_cluster_name" {
  description = "The name of the EKS cluster"
}

variable "exam_namespace" {
  description = "Kubernetes namespace for exam"
  default = "exam"
}

variable "exam_name" {
  description = "Exam name use for naming resources"
  default = "exam-sample"
}

variable "route53_zone_name" {
  description = "Existing route53 zone name for creating exam and API domains"
}

variable "helm_repo" {
  description = "The URL of helm repo"
  default = "oci://ghcr.io/ubc/jupyterhub"
}

variable "chart_name" {
  description = "The name of the chart"
  default = "jupyterhub"
}

variable "chart_version" {
  description = "The version of the chart"
  default = "3.2.2-0.dev.git.6529.hd1841a98"
}

variable "proxy_secret_token" {
  description = "Proxy.secretToken in Helm config"
  default = "supersecrettoken"
}

variable "lti_secret" {
  description = "hub.config.LTI11Authenticator.consumers in Helm config"
  default = "supersecretltisecret"
}

variable "exam_image" {
  description = "exam image name, singleuser.image.name in Helm config"
}

variable "exam_image_tag" {
  description = "exam image tag, singleuser.image.tag in Helm config"
}

variable "exam_api_key" {
  description = "API key to access exam APIs, examapi.apiKey in Helm config"
}

variable "efs_handle" {
  description = "EFS handle used for hosting exam content"
}
