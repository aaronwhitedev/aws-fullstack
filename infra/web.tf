resource "aws_acm_certificate" "www_cert" {
  domain_name       = "www.${var.domain}"
  validation_method = "DNS"

  provider = aws.acm

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "apex_cert" {
  domain_name       = var.domain
  validation_method = "DNS"
  provider          = aws.acm

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "www_cert_dns" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.www_cert.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.www_cert.domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.www_cert.domain_validation_options)[0].resource_record_type
  zone_id         = aws_route53_zone.hosted_zone.zone_id
  ttl             = 60
}

resource "aws_route53_record" "apex_cert_dns" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.apex_cert.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.apex_cert.domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.apex_cert.domain_validation_options)[0].resource_record_type
  zone_id         = aws_route53_zone.hosted_zone.zone_id
  ttl             = 60
}

resource "aws_acm_certificate_validation" "www_cert_validate" {
  certificate_arn         = aws_acm_certificate.www_cert.arn
  provider                = aws.acm
  validation_record_fqdns = [aws_route53_record.www_cert_dns.fqdn]
}

resource "aws_acm_certificate_validation" "apex_cert_validate" {
  certificate_arn         = aws_acm_certificate.apex_cert.arn
  provider                = aws.acm
  validation_record_fqdns = [aws_route53_record.apex_cert_dns.fqdn]
  # validation_record_fqdns = [for record in aws_route53_record.ic_DNS_validation : record.fqdn]

}

#################################################################################################
resource "aws_s3_bucket" "www_bucket" {
  bucket = "www.${var.domain}"
}

resource "aws_s3_bucket_public_access_block" "www_bucket_access_block" {
  bucket = aws_s3_bucket.www_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "www_bucket_policy" {
  depends_on = [aws_s3_bucket_public_access_block.www_bucket_access_block]
  bucket     = aws_s3_bucket.www_bucket.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "PublicReadGetObject",
          "Effect" : "Allow",
          "Principal" : "*",
          "Action" : "s3:GetObject",
          "Resource" : "arn:aws:s3:::${aws_s3_bucket.www_bucket.id}/*"
        }
      ]
    }
  )
}

resource "aws_s3_bucket_website_configuration" "www_hosting" {
  bucket = aws_s3_bucket.www_bucket.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_cloudfront_distribution" "www_cloudfront" {
  enabled         = true
  is_ipv6_enabled = false

  origin {
    domain_name = aws_s3_bucket_website_configuration.www_hosting.website_endpoint
    origin_id   = aws_s3_bucket.www_bucket.bucket_regional_domain_name

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "http-only"
      origin_read_timeout      = 30
      origin_ssl_protocols = [
        "TLSv1.2",
      ]
    }
  }

  aliases     = ["www.${var.domain}"]
  price_class = "PriceClass_100"

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate_validation.www_cert_validate.certificate_arn
    cloudfront_default_certificate = false
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.1_2016"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.www_bucket.bucket_regional_domain_name
    compress         = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

}

#################################################################################################
resource "aws_s3_bucket" "apex_bucket" {
  bucket = var.domain
}

resource "aws_s3_bucket_public_access_block" "apex_bucket_access_block" {
  bucket = aws_s3_bucket.apex_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "apex_bucket_policy" {
  depends_on = [aws_s3_bucket_public_access_block.apex_bucket_access_block]
  bucket     = aws_s3_bucket.apex_bucket.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "PublicReadGetObject",
          "Effect" : "Allow",
          "Principal" : "*",
          "Action" : "s3:GetObject",
          "Resource" : "arn:aws:s3:::${aws_s3_bucket.apex_bucket.id}/*"
        }
      ]
    }
  )
}

resource "aws_s3_bucket_website_configuration" "apex_hosting" {
  bucket = aws_s3_bucket.apex_bucket.id

  redirect_all_requests_to {
    host_name = "www.${var.domain}"
    protocol  = "https"
  }
}

resource "aws_cloudfront_distribution" "apex_cloudfront" {
  enabled         = true
  is_ipv6_enabled = false

  origin {
    domain_name = aws_s3_bucket_website_configuration.apex_hosting.website_endpoint
    origin_id   = aws_s3_bucket.apex_bucket.bucket_regional_domain_name

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "http-only"
      origin_read_timeout      = 30
      origin_ssl_protocols = [
        "TLSv1.2",
      ]
    }
  }

  aliases     = [var.domain]
  price_class = "PriceClass_100"


  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate_validation.apex_cert_validate.certificate_arn
    cloudfront_default_certificate = false
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.1_2016"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.apex_bucket.bucket_regional_domain_name
    compress         = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
}



resource "aws_route53_record" "www_domain" {
  name    = "www.${var.domain}"
  type    = "A"
  zone_id = aws_route53_zone.hosted_zone.zone_id

  alias {
    name                   = aws_cloudfront_distribution.www_cloudfront.domain_name
    zone_id                = aws_cloudfront_distribution.www_cloudfront.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "apex_domain" {
  name    = var.domain
  type    = "A"
  zone_id = aws_route53_zone.hosted_zone.zone_id

  alias {
    name                   = aws_cloudfront_distribution.apex_cloudfront.domain_name
    zone_id                = aws_cloudfront_distribution.apex_cloudfront.hosted_zone_id
    evaluate_target_health = false
  }
}