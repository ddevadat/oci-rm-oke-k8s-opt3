resource "oci_core_virtual_network" "oke_vcn" {
  cidr_block     = local.cidr_block
  compartment_id = var.compartment_ocid
  display_name   = "OKE TEST VCN - ${local.deploy_id}"
  dns_label      = "oke${local.deploy_id}"

}

resource "oci_core_internet_gateway" "oke_internet_gateway" {
  compartment_id = var.compartment_ocid
  display_name   = "oke-internet-gateway-${local.deploy_id}"
  enabled        = true
  vcn_id         = oci_core_virtual_network.oke_vcn.id
}

resource "oci_core_route_table" "oke_public_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.oke_vcn.id
  display_name   = "oke-public-route-table-${local.deploy_id}"

  route_rules {
    description       = "Traffic to/from internet"
    destination       = local.all_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.oke_internet_gateway.id
  }
}


resource "oci_core_nat_gateway" "oke_nat_gateway" {
  block_traffic  = "false"
  compartment_id = var.compartment_ocid
  display_name   = "oke-nat-gateway-${local.deploy_id}"
  vcn_id         = oci_core_virtual_network.oke_vcn.id

}

resource "oci_core_service_gateway" "oke_service_gateway" {
  compartment_id = var.compartment_ocid
  display_name   = "oke-service-gateway-${local.deploy_id}"
  vcn_id         = oci_core_virtual_network.oke_vcn.id
  services {
    service_id = local.service_id
  }

}

resource "oci_core_route_table" "oke_private_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.oke_vcn.id
  display_name   = "oke-private-route-table-${local.deploy_id}"

  route_rules {
    description       = "Traffic to the internet"
    destination       = local.all_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.oke_nat_gateway.id
  }
  route_rules {
    description       = "Traffic to OCI services"
    destination       = local.service_cidr
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.oke_service_gateway.id
  }

}

resource "oci_core_subnet" "oke_k8s_endpoint_subnet" {
  cidr_block                 = local.k8s_endpoint_subnet_cidr
  compartment_id             = var.compartment_ocid
  display_name               = "oke-k8s-endpoint-subnet-${local.deploy_id}"
  dns_label                  = "okek8sn${local.deploy_id}"
  vcn_id                     = oci_core_virtual_network.oke_vcn.id
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.oke_public_route_table.id
  dhcp_options_id            = oci_core_virtual_network.oke_vcn.default_dhcp_options_id
  security_list_ids          = [oci_core_security_list.oke_endpoint_security_list.id]
}


resource "oci_core_subnet" "oke_nodes_subnet" {
  cidr_block     = local.subnet_regional_cidr
  compartment_id = var.compartment_ocid
  display_name   = "oke-nodes-subnet-${local.deploy_id}"
  dns_label      = "okenodesn${local.deploy_id}"
  vcn_id         = oci_core_virtual_network.oke_vcn.id
  #prohibit_public_ip_on_vnic = true
  prohibit_public_ip_on_vnic = (var.cluster_workers_visibility == "Private") ? true : false
  #route_table_id             = oci_core_route_table.oke_private_route_table.id
  route_table_id    = (var.cluster_workers_visibility == "Private") ? oci_core_route_table.oke_private_route_table.id : oci_core_route_table.oke_public_route_table.id
  dhcp_options_id   = oci_core_virtual_network.oke_vcn.default_dhcp_options_id
  security_list_ids = [oci_core_security_list.oke_nodes_security_list.id]
}




resource "oci_core_subnet" "oke_lb_subnet" {
  cidr_block                 = local.lb_subnet_regional_cidr
  compartment_id             = var.compartment_ocid
  display_name               = "oke-lb-subnet-${local.deploy_id}"
  dns_label                  = "okelbsn${local.deploy_id}"
  vcn_id                     = oci_core_virtual_network.oke_vcn.id
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.oke_public_route_table.id
  dhcp_options_id            = oci_core_virtual_network.oke_vcn.default_dhcp_options_id
  security_list_ids          = [oci_core_security_list.oke_lb_security_list.id]

}




