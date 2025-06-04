output "arn" {
  description = "The ARN of the load balancer."
  value       = aws_lb.main.arn
}

output "arn_suffix" {
  description = "The ARN suffix for use with CloudWatch Metrics."
  value       = aws_lb.main.arn_suffix
}

output "name" {
  description = "The name of the load balancer."
  value       = element(split("/", aws_lb.main.name), 2)
}

output "dns_name" {
  description = "The DNS name of the load balancer."
  value       = aws_lb.main.dns_name
}

output "zone_id" {
  description = "The canonical hosted zone ID of the load balancer (to be used in a Route 53 Alias record)."
  value       = aws_lb.main.zone_id
}

output "origin_id" {
  description = "First part of the DNS name of the load balancer."
  value       = element(split(".", aws_lb.main.dns_name), 0)
}

output "security_group_id" {
  description = "The ID of the security group."
  value       = try(aws_security_group.this[0].id, null)
}

output "https_listener_arn" {
  description = "Listener for HTTPS (port 443) traffic"
  value = try(aws_lb_listener.https[0].arn, null)
}

output "http_listener_arn" {
  description = "Listener for HTTP (port 80) traffic"
  value = try(aws_lb_listener.http[0].arn, null)
}

output "https_test_listener_arn" {
  description = "Listener for HTTPS (port 8443) traffic"
  value = try(aws_lb_listener.https_test[0].arn, null)
}
