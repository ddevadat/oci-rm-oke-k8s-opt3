


# OCI Services
##**************************************************************************
##                        Autonomous Database
##**************************************************************************

### creates an ATP database
resource "oci_database_autonomous_database" "acme_autonomous_database" {
  admin_password           = random_string.autonomous_database_admin_password.result
  compartment_id           = var.compartment_ocid
  cpu_core_count           = 1
  data_storage_size_in_tbs = 1
  data_safe_status         = "NOT_REGISTERED"
  db_version               = "19c"
  db_name                  = "atpdb${local.deploy_id}"
  display_name             = "Acme Db (${local.deploy_id})"
  license_model            = "BRING_YOUR_OWN_LICENSE"
  is_auto_scaling_enabled  = false
  is_free_tier             = false

}
### Wallet
resource "oci_database_autonomous_database_wallet" "autonomous_database_wallet" {
  autonomous_database_id = oci_database_autonomous_database.acme_autonomous_database.id
  password               = random_string.autonomous_database_wallet_password.result
  generate_type          = "SINGLE"
  base64_encode_content  = true

}

resource "kubernetes_secret" "oadb-admin" {
  metadata {
    name      = "oadb-admin"
    namespace = kubernetes_namespace.acme_namespace.id
  }
  data = {
    oadb_admin_pw = random_string.autonomous_database_admin_password.result
  }
  type = "Opaque"

}

resource "kubernetes_secret" "oadb-connection" {
  metadata {
    name      = "oadb-connection"
    namespace = kubernetes_namespace.acme_namespace.id
  }
  data = {
    oadb_wallet_pw = random_string.autonomous_database_wallet_password.result
    oadb_service   = "atpdb${random_string.deploy_id.result}_TP"
  }
  type = "Opaque"

}

### OADB Wallet extraction <>
resource "kubernetes_secret" "oadb_wallet_zip" {
  metadata {
    name      = "oadb-wallet-zip"
    namespace = kubernetes_namespace.acme_namespace.id
  }
  data = {
    wallet = oci_database_autonomous_database_wallet.autonomous_database_wallet.content
  }
  type = "Opaque"

}
resource "kubernetes_cluster_role" "secret_creator" {
  metadata {
    name = "secret-creator"
  }
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["create"]
  }

}
resource "kubernetes_cluster_role_binding" "wallet_extractor_crb" {
  metadata {
    name = "wallet-extractor-crb"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.secret_creator.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.wallet_extractor_sa.metadata.0.name
    namespace = kubernetes_namespace.acme_namespace.id
  }

}
resource "kubernetes_service_account" "wallet_extractor_sa" {
  metadata {
    name      = "wallet-extractor-sa"
    namespace = kubernetes_namespace.acme_namespace.id
  }

}
resource "kubernetes_job" "wallet_extractor_job" {
  metadata {
    name      = "wallet-extractor-job"
    namespace = kubernetes_namespace.acme_namespace.id
  }
  spec {
    template {
      metadata {}
      spec {
        init_container {
          name    = "wallet-extractor"
          image   = "busybox"
          command = ["/bin/sh", "-c"]
          args    = ["base64 -d /tmp/zip/wallet > /tmp/wallet.zip && unzip /tmp/wallet.zip -d /wallet"]
          volume_mount {
            mount_path = "/tmp/zip"
            name       = "wallet-zip"
            read_only  = true
          }
          volume_mount {
            mount_path = "/wallet"
            name       = "wallet"
          }
        }
        container {
          name    = "wallet-binding"
          image   = "bitnami/kubectl"
          command = ["/bin/sh", "-c"]
          args    = ["kubectl create secret generic oadb-wallet --from-file=/wallet"]
          volume_mount {
            mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
            name       = kubernetes_service_account.wallet_extractor_sa.default_secret_name
            read_only  = true
          }
          volume_mount {
            mount_path = "/wallet"
            name       = "wallet"
            read_only  = true
          }
        }
        volume {
          name = kubernetes_service_account.wallet_extractor_sa.default_secret_name
          secret {
            secret_name = kubernetes_service_account.wallet_extractor_sa.default_secret_name
          }
        }
        volume {
          name = "wallet-zip"
          secret {
            secret_name = kubernetes_secret.oadb_wallet_zip.metadata.0.name
          }
        }
        volume {
          name = "wallet"
          empty_dir {}
        }
        restart_policy       = "Never"
        service_account_name = "wallet-extractor-sa"
      }
    }
    backoff_limit              = 1
    ttl_seconds_after_finished = 120
  }


}
