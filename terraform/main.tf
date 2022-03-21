# Randoms
resource "random_string" "deploy_id" {
  length  = 4
  special = false
}

resource "kubernetes_namespace" "acme_namespace" {
  metadata {
    name = "acme"
  }
  depends_on = [oci_containerengine_node_pool.oke_node_pool]
}
