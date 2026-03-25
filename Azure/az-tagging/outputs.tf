output "tags" {
  description = "Complete tag map to pass to all module calls"
  value       = local.tags
}

output "required_tags" {
  description = "Only the required tags (without additional)"
  value       = local.required_tags
}
