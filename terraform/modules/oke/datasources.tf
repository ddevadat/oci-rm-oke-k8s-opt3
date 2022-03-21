data "oci_containerengine_cluster_option" "oke" {
  cluster_option_id = "all"
}

data "oci_containerengine_node_pool_option" "oke" {
  node_pool_option_id = "all"
}

data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.tenancy_ocid
}


data "oci_containerengine_cluster_kube_config" "oke" {
  cluster_id = oci_containerengine_cluster.oke_cluster.id
  depends_on = [oci_containerengine_node_pool.oke_node_pool]
}
