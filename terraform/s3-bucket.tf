locals {
  # Terraform files are in terraform/, your site is in ../code
  site_dir = "${path.module}/../code"
  files    = fileset(local.site_dir, "**")
  content_types = {
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    png  = "image/png"
    jpg  = "image/jpeg"
    jpeg = "application/jpeg"
    svg  = "image/svg+xml"
    ico  = "image/x-icon"
    json = "application/json"
    txt  = "text/plain"
    pdf  = "application/pdf"
  }
}

resource "aws_s3_bucket" "site" {
  bucket = var.bucket_name
  tags = {
  Name = "terraform-static-site"
  block_public_acls = false
  }
}

# allow public object reads (if using public bucket)
resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  index_document {
    suffix = "index.html"
  }
  #error_document {
  #  key = "error.html"
  #}
}

# upload all files from ../code
resource "aws_s3_object" "files" {
  for_each = { for f in local.files : f => f }

  bucket       = aws_s3_bucket.site.id
  key          = each.value
  source       = "${local.site_dir}/${each.value}"
  etag         = filemd5("${local.site_dir}/${each.value}")

  # set content type based on extension if found
  content_type = lookup(
    local.content_types,
    lower(trimspace(regex("\\.([^.]+)$", each.value)[0])),
    null
  )

  # optional: cache control (tweak as needed)
  # cache_control = "max-age=86400"

  # keep Terraform aware of changes
  lifecycle {
    # prevent accidental destroy? comment out if not needed
    # prevent_destroy = true
  }
}

data "aws_iam_policy_document" "public_read_objects" {
  statement {
    sid     = "PublicReadGetObject"
    effect  = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.public_read_objects.json
}

output "website_endpoint" {
  value = aws_s3_bucket_website_configuration.site.website_endpoint
}
