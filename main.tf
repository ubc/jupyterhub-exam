data "aws_eks_cluster" "eks" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  name = var.eks_cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     args        = flatten(["eks", "get-token", "--cluster-name", var.eks_cluster_name,
#         var.assume_role_arn != "" ? ["--role-arn", var.assume_role_arn] : []])
#     command     = "aws"
#   }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       args = flatten(["eks", "get-token", "--cluster-name", var.eks_cluster_name, "--region", var.region,
#           var.assume_role_arn != "" ? ["--role-arn", var.assume_role_arn] : []])
#       command     = "aws"
#     }
    #    load_config_file       = false
  }
#
#   registry {
#     url = "oci://ghcr.io"
#     password = ""
#     username = ""
#   }
}

# resource "kubernetes_namespace" "exam-namespace" {
#   metadata {
#     name = var.exam_namespace
#   }
# }

data "aws_route53_zone" "jupyterhub-zone" {
  name         = var.route53_zone_name
  private_zone = false
}

resource "aws_acm_certificate" "cert-exam" {
  domain_name       = "${var.exam_name}-exam.${var.route53_zone_name}"
  validation_method = "DNS"

  tags = {
    Environment = "exam"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert-exam" {
  for_each = {
    for dvo in aws_acm_certificate.cert-exam.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.jupyterhub-zone.zone_id
}

resource "aws_acm_certificate" "cert-api" {
  domain_name       = "${var.exam_name}-api.${var.route53_zone_name}"
  validation_method = "DNS"

  tags = {
    Environment = "exam-api"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert-apit" {
  for_each = {
    for dvo in aws_acm_certificate.cert-api.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.jupyterhub-zone.zone_id
}

# install jupyterhub helm deployment
resource "helm_release" "jupyterhub-exam" {
  name       = "exam-${var.exam_name}"
  create_namespace = true
  namespace  = var.exam_namespace
  repository = var.helm_repo
  chart      = var.chart_name
  version    = var.chart_version
  values     = [templatefile("config.yaml", {
    secret_token = var.proxy_secret_token
    lti_consumers = "{\"${var.exam_name}\":\"${var.lti_secret}\"}"
    ingress_host = "${var.exam_name}-exam.${var.route53_zone_name}"
    user_image = var.exam_image
    user_image_tag = var.exam_image_tag
    static_pvc_name = "efs"
    static_sub_path = "${var.exam_name}/{username}"
    course_code = var.exam_name
    api_key = var.exam_api_key
    efs_handle = var.efs_handle
    exam_api_host = "${var.exam_name}-api.${var.route53_zone_name}"
  })]
}

data "kubernetes_ingress_v1" "jupyterhub" {
  metadata {
    name = "jupyterhub"
    namespace = var.exam_namespace
  }

  depends_on = [
    helm_release.jupyterhub-exam
  ]
}

data "kubernetes_ingress_v1" "exam-api" {
  metadata {
    name = "exam-api"
    namespace = var.exam_namespace
  }

  depends_on = [
    helm_release.jupyterhub-exam
  ]
}

resource "aws_route53_record" "jupyterhub" {
  zone_id = data.aws_route53_zone.jupyterhub-zone.zone_id
  name    = "${var.exam_name}-exam"
  type    = "CNAME"
  ttl     = "300"
  records = [data.kubernetes_ingress_v1.jupyterhub.status.0.load_balancer.0.ingress.0.hostname]

  depends_on = [
    helm_release.jupyterhub-exam
  ]
}

resource "aws_route53_record" "exam-api" {
  zone_id = data.aws_route53_zone.jupyterhub-zone.zone_id
  name    = "${var.exam_name}-api"
  type    = "CNAME"
  ttl     = "300"
  records = [data.kubernetes_ingress_v1.exam-api.status.0.load_balancer.0.ingress.0.hostname]

  depends_on = [
    helm_release.jupyterhub-exam
  ]
}
