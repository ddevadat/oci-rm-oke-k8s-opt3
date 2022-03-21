# Randoms
resource "random_string" "deploy_id" {
  length  = 4
  special = false
}


# module "oke" {
#   source = "./modules/oke"
#   # general oci parameters
#   compartment_id                            = var.compartment_ocid
#   deploy_id                                 = local.deploy_id
#   oke_vcn_id                                = oci_core_virtual_network.oke_vcn.id
#   oke_k8s_endpoint_subnet_id                = oci_core_subnet.oke_k8s_endpoint_subnet.id
#   oke_k8s_lb_subnet_id                      = oci_core_subnet.oke_lb_subnet.id
#   k8s_nodes_subnet_id                       = oci_core_subnet.oke_nodes_subnet.id
#   k8s_version                               = (var.k8s_version == "Latest") ? local.cluster_k8s_latest_version : var.k8s_version
#   cluster_endpoint_visibility               = var.cluster_endpoint_visibility
#   cluster_workers_visibility                = var.cluster_workers_visibility
#   k8s_service_cidr                          = local.k8s_service_cidr
#   k8s_pods_cidr                             = local.k8s_pods_cidr
#   tenancy_ocid                              = var.tenancy_ocid
#   image_id                                  = local.image_id
#   num_pool_workers                          = var.num_pool_workers
#   node_pool_node_shape_config_ocpus         = var.node_pool_node_shape_config_ocpus
#   node_pool_node_shape_config_memory_in_gbs = var.node_pool_node_shape_config_memory_in_gbs
#   node_pool_name                            = var.node_pool_name
#   generate_public_ssh_key                   = var.generate_public_ssh_key
#   public_ssh_key                            = var.public_ssh_key

# }

resource "kubernetes_namespace" "acme_namespace" {
  metadata {
    name = "acme"
  }
  depends_on = [oci_containerengine_node_pool.oke_node_pool]
}
