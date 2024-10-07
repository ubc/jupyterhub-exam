output "exam_url" {
  value = "${var.exam_name}-exam.${var.route53_zone_name}"
}

output "exam_api_url" {
  value = "${var.exam_name}-api.${var.route53_zone_name}"
}

output "exam_api_key" {
  value = var.exam_api_key
}
