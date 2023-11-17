# Define an S3 bucket resource
resource "aws_s3_bucket" "this" {
 count = var.create_bucket ? 1 : 0 # Conditionally create bucket based on create_bucket variable

 bucket        = var.bucket        # Name of the S3 bucket
 bucket_prefix = var.bucket_prefix # Optional prefix for the bucket name

 force_destroy       = var.force_destroy       # Enable to allow deletion of the bucket even if it contains objects
 object_lock_enabled = var.object_lock_enabled # Enable S3 object locking for compliance purposes
 tags                = var.tags                # Map of tags to assign to the bucket
}

# S3 bucket logging resource
resource "aws_s3_bucket_logging" "this" {
 count = var.create_bucket && length(keys(var.logging)) > 0 ? 1 : 0

 bucket = aws_s3_bucket.this[0].id

 target_bucket = var.logging["target_bucket"]
 target_prefix = try(var.logging["target_prefix"], null)
}

# Define S3 bucket website configuration
resource "aws_s3_bucket_website_configuration" "this" {
 count = var.create_bucket && length(keys(var.website)) > 0 ? 1 : 0

 bucket                = aws_s3_bucket.this[0].id
 expected_bucket_owner = var.expected_bucket_owner

 # Set index document for bucket website
 dynamic "index_document" {
    for_each = try([var.website["index_document"]], [])

    content {
      suffix = index_document.value
    }
 }

 # Set error document for bucket website
 dynamic "error_document" {
    for_each = try([var.website["error_document"]], [])

    content {
      key = error_document.value
    }
 }

 # Redirect all requests to specific hostname
 dynamic "redirect_all_requests_to" {
    for_each = try([var.website["redirect_all_requests_to"]], [])

    content {
      host_name = redirect_all_requests_to.value.host_name
      protocol = try(redirect_all_requests_to.value.protocol, null)
    }
 }

 # Set routing rules for bucket website
 dynamic "routing_rule" {
    for_each = try(flatten([var.website["routing_rules"]]), [])

    content {
      dynamic "condition" {
        for_each = [try([routing_rule.value.condition], [])]

        content {
          http_error_code_returned_equals = try(routing_rule.value.condition["http_error_code_returned_equals"], null)
          key_prefix_equals               = try(routing_rule.value.condition["key_prefix_equals"], null)
        }
      }

      redirect {
        host_name               = try(routing_rule.value.redirect["host_name"], null)
        http_redirect_code      = try(routing_rule.value.redirect["http_redirect_code"], null)
        protocol                = try(routing_rule.value.redirect["protocol"], null)
        replace_key_prefix_with = try(routing_rule.value.redirect["replace_key_prefix_with"], null)
        replace_key_with        = try(routing_rule.value.redirect["replace_key_with"], null)
      }
    }
 }
}



