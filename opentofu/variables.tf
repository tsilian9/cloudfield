# ─── Kubernetes ───────────────────────────────────────────────
variable "rabbitmq_user" {
  description = "RabbitMQ username"
  type        = string
  default     = "admin"
}

variable "rabbitmq_pass" {
  description = "RabbitMQ password"
  type        = string
  sensitive   = true
}

variable "minio_root_user" {
  description = "MinIO root username (for Kubernetes secret)"
  type        = string
  default     = "admin"
}

variable "minio_root_password" {
  description = "MinIO root password (for Kubernetes secret)"
  type        = string
  sensitive   = true
}

variable "keycloak_admin" {
  description = "Keycloak admin username (for Kubernetes secret)"
  type        = string
  default     = "admin"
}

variable "keycloak_admin_password_secret" {
  description = "Keycloak admin password (for Kubernetes secret)"
  type        = string
  sensitive   = true
}

variable "keycloak_client_secret_thingsboard" {
  description = "Keycloak client secret for ThingsBoard"
  type        = string
  sensitive   = true
}

variable "keycloak_client_secret_minio" {
  description = "Keycloak client secret for MinIO"
  type        = string
  sensitive   = true
}

variable "tb_access_token" {
  description = "ThingsBoard device access token"
  type        = string
  sensitive   = true
}

# ─── MinIO Provider ───────────────────────────────────────────
variable "minio_endpoint" {
  description = "MinIO S3 API endpoint (without http://)"
  type        = string
  default     = "minio-api.172.31.76.79.nip.io"
}

variable "minio_user" {
  description = "MinIO admin username"
  type        = string
  default     = "admin"
}

variable "minio_password" {
  description = "MinIO admin password"
  type        = string
  sensitive   = true
}

# ─── Keycloak Provider ────────────────────────────────────────
variable "keycloak_url" {
  description = "Keycloak base URL"
  type        = string
  default     = "http://keycloak.172.31.76.79.nip.io"
}

variable "keycloak_admin_user" {
  description = "Keycloak admin username"
  type        = string
  default     = "admin"
}

variable "keycloak_admin_password" {
  description = "Keycloak admin password"
  type        = string
  sensitive   = true
}

# ─── ConfigMap settings ───────────────────────────────────────
variable "rabbitmq_host" {
  description = "RabbitMQ Kubernetes service hostname"
  type        = string
  default     = "rabbitmq"
}

variable "rabbitmq_port" {
  description = "RabbitMQ AMQP port"
  type        = string
  default     = "5672"
}

variable "keycloak_host" {
  description = "Keycloak Kubernetes service hostname"
  type        = string
  default     = "keycloak"
}

variable "keycloak_port" {
  description = "Keycloak HTTP port"
  type        = string
  default     = "8080"
}
