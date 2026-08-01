# ═══════════════════════════════════════════════════════════════
#  Kubernetes Secret: farm-secrets
# ═══════════════════════════════════════════════════════════════
resource "kubernetes_secret" "farm_secrets" {
  metadata {
    name      = "farm-secrets"
    namespace = "default"
  }

  data = {
    RABBITMQ_USER              = var.rabbitmq_user
    RABBITMQ_PASS              = var.rabbitmq_pass
    MINIO_ROOT_USER            = var.minio_root_user
    MINIO_ROOT_PASSWORD        = var.minio_root_password
    KEYCLOAK_ADMIN             = var.keycloak_admin
    KEYCLOAK_ADMIN_PASSWORD    = var.keycloak_admin_password_secret
    KEYCLOAK_CLIENT_SECRET     = var.keycloak_client_secret_thingsboard
    KEYCLOAK_CLIENT_SECRET_MINIO = var.keycloak_client_secret_minio
    TB_ACCESS_TOKEN            = var.tb_access_token
  }

  type = "Opaque"
}

# ═══════════════════════════════════════════════════════════════
#  Kubernetes ConfigMap: farm-settings
# ═══════════════════════════════════════════════════════════════
resource "kubernetes_config_map" "farm_settings" {
  metadata {
    name      = "farm-settings"
    namespace = "default"
  }

  data = {
    RABBITMQ_HOST = var.rabbitmq_host
    RABBITMQ_PORT = var.rabbitmq_port
    KEYCLOAK_HOST = var.keycloak_host
    KEYCLOAK_PORT = var.keycloak_port
  }
}

# ═══════════════════════════════════════════════════════════════
# MinIO Buckets: farm-images + farm-data
# ═══════════════════════════════════════════════════════════════
resource "minio_s3_bucket" "farm_images" {
  bucket = "farm-images"
  acl    = "private"
}

resource "minio_s3_bucket" "farm_data" {
  bucket = "farm-data"
  acl    = "private"
}

# ═══════════════════════════════════════════════════════════════
# MinIO Lifecycle Policy: 90 days
# Note: Lifecycle is configured via mc CLI (standalone mode)
# Command: mc ilm add --expiry-days 90 local/farm-images
# Command: mc ilm add --expiry-days 90 local/farm-data
# ═══════════════════════════════════════════════════════════════
# (The minio_ilm_policy resource is not supported in standalone MinIO)
# We use null_resource to execute mc CLI
resource "null_resource" "farm_images_lifecycle" {
  depends_on = [minio_s3_bucket.farm_images]

  provisioner "local-exec" {
    command = "mc alias set cloudfield http://minio-api.172.31.76.79.nip.io admin admin123 && mc ilm rule add --expire-days 90 cloudfield/farm-images"
  }
}

resource "null_resource" "farm_data_lifecycle" {
  depends_on = [minio_s3_bucket.farm_data]

  provisioner "local-exec" {
    command = "mc alias set cloudfield http://minio-api.172.31.76.79.nip.io admin admin123 && mc ilm rule add --expire-days 90 cloudfield/farm-data"
  }
}

# ═══════════════════════════════════════════════════════════════
# Keycloak: Realm cloudfield
# ═══════════════════════════════════════════════════════════════
resource "keycloak_realm" "cloudfield" {
  realm   = "cloudfield"
  enabled = true

  display_name = "CloudField Smart Agriculture"

  login_theme = "keycloak"

  access_token_lifespan = "5m"
}

# ─── Keycloak Client: ThingsBoard ─────────────────────────────
resource "keycloak_openid_client" "thingsboard" {
  realm_id  = keycloak_realm.cloudfield.id
  client_id = "thingsboard"
  name      = "ThingsBoard"
  enabled   = true

  access_type              = "CONFIDENTIAL"
  standard_flow_enabled    = true
  implicit_flow_enabled    = false
  direct_access_grants_enabled = true

  valid_redirect_uris = [
    "http://thingsboard.172.31.76.79.nip.io/*"
  ]

  web_origins = [
    "http://thingsboard.172.31.76.79.nip.io"
  ]
}

# ─── Keycloak Client: MinIO ───────────────────────────────────
resource "keycloak_openid_client" "minio" {
  realm_id  = keycloak_realm.cloudfield.id
  client_id = "minio"
  name      = "MinIO"
  enabled   = true

  access_type              = "CONFIDENTIAL"
  standard_flow_enabled    = true
  implicit_flow_enabled    = false
  direct_access_grants_enabled = true

  valid_redirect_uris = [
    "http://minio.172.31.76.79.nip.io/*"
  ]

  web_origins = [
    "http://minio.172.31.76.79.nip.io"
  ]
}

# ─── Keycloak User: farm-admin ────────────────────────────────
resource "keycloak_user" "farm_admin" {
  realm_id = keycloak_realm.cloudfield.id
  username = "farm-admin"
  enabled  = true

  email      = "admin@cloudfield.io"
  first_name = "Farm"
  last_name  = "Admin"

  initial_password {
    value     = "admin123"
    temporary = false
  }
}

# ─── Keycloak User: farm-operator ─────────────────────────────
resource "keycloak_user" "farm_operator" {
  realm_id = keycloak_realm.cloudfield.id
  username = "farm-operator"
  enabled  = true

  email      = "operator@cloudfield.io"
  first_name = "Farm"
  last_name  = "Operator"

  initial_password {
    value     = "operator123"
    temporary = false
  }
}
