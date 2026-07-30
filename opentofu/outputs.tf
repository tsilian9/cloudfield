output "farm_secrets_name" {
  description = "Kubernetes Secret name"
  value       = kubernetes_secret.farm_secrets.metadata[0].name
}

output "farm_settings_name" {
  description = "Kubernetes ConfigMap name"
  value       = kubernetes_config_map.farm_settings.metadata[0].name
}

output "minio_bucket_farm_images" {
  description = "MinIO bucket for farm images"
  value       = minio_s3_bucket.farm_images.bucket
}

output "minio_bucket_farm_data" {
  description = "MinIO bucket for farm data"
  value       = minio_s3_bucket.farm_data.bucket
}

output "keycloak_realm" {
  description = "Keycloak realm name"
  value       = keycloak_realm.cloudfield.realm
}

output "keycloak_thingsboard_client_id" {
  description = "Keycloak client ID for ThingsBoard"
  value       = keycloak_openid_client.thingsboard.client_id
}

output "keycloak_minio_client_id" {
  description = "Keycloak client ID for MinIO"
  value       = keycloak_openid_client.minio.client_id
}

output "farm_admin_username" {
  description = "Farm admin username in Keycloak"
  value       = keycloak_user.farm_admin.username
}

output "farm_operator_username" {
  description = "Farm operator username in Keycloak"
  value       = keycloak_user.farm_operator.username
}
