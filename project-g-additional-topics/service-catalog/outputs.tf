output "portfolio_id" {
  description = "ID of the Service Catalog portfolio"
  value       = aws_servicecatalog_portfolio.main.id
}

output "product_id" {
  description = "ID of the S3 bucket product"
  value       = aws_servicecatalog_product.s3_bucket.id
}
