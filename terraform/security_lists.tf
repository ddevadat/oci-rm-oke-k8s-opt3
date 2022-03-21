
resource "oci_core_security_list" "oke_endpoint_security_list" {
  compartment_id = var.compartment_ocid
  display_name   = "oke-k8s-api-endpoint-seclist-${local.deploy_id}"
  vcn_id         = oci_core_virtual_network.oke_vcn.id

  # Ingresses

  ingress_security_rules {
    description = "External access to Kubernetes API endpoint"
    source      = local.all_cidr
    source_type = "CIDR_BLOCK"
    protocol    = local.tcp_protocol_number
    stateless   = false

    tcp_options {
      max = local.k8s_api_endpoint_port_number
      min = local.k8s_api_endpoint_port_number
    }
  }
  ingress_security_rules {
    description = "Kubernetes worker to Kubernetes API endpoint communication"
    source      = local.subnet_regional_cidr
    source_type = "CIDR_BLOCK"
    protocol    = local.tcp_protocol_number
    stateless   = false

    tcp_options {
      max = local.k8s_api_endpoint_port_number
      min = local.k8s_api_endpoint_port_number
    }
  }
  ingress_security_rules {
    description = "Kubernetes worker to control plane communication"
    source      = local.subnet_regional_cidr
    source_type = "CIDR_BLOCK"
    protocol    = local.tcp_protocol_number
    stateless   = false

    tcp_options {
      max = local.k8s_worker_to_control_plane_port_number
      min = local.k8s_worker_to_control_plane_port_number
    }
  }
  ingress_security_rules {
    description = "Path discovery"
    source      = local.subnet_regional_cidr
    source_type = "CIDR_BLOCK"
    protocol    = local.icmp_protocol_number
    stateless   = false

    icmp_options {
      type = "3"
      code = "4"
    }
  }

  # Egresses

  egress_security_rules {
    description      = "Allow Kubernetes Control Plane to communicate with OKE"
    destination      = local.service_cidr
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol         = local.tcp_protocol_number
    stateless        = false

    tcp_options {
      max = local.https_port_number
      min = local.https_port_number
    }
  }
  egress_security_rules {
    description      = "All traffic to worker nodes"
    destination      = local.subnet_regional_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = local.tcp_protocol_number
    stateless        = false
  }
  egress_security_rules {
    description      = "Path discovery"
    destination      = local.subnet_regional_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = local.icmp_protocol_number
    stateless        = false

    icmp_options {
      type = "3"
      code = "4"
    }
  }

}

################################################################

resource "oci_core_security_list" "oke_nodes_security_list" {
  compartment_id = var.compartment_ocid
  display_name   = "oke-nodes-wkr-seclist-${local.deploy_id}"
  vcn_id         = oci_core_virtual_network.oke_vcn.id

  # Ingresses
  ingress_security_rules {
    description = "Allow pods on one worker node to communicate with pods on other worker nodes"
    source      = local.subnet_regional_cidr
    source_type = "CIDR_BLOCK"
    protocol    = local.all_protocols
    stateless   = false
  }
  ingress_security_rules {
    description = "Inbound SSH traffic to worker nodes"
    source      = local.all_cidr
    source_type = "CIDR_BLOCK"
    protocol    = local.tcp_protocol_number
    stateless   = false

    tcp_options {
      max = local.ssh_port_number
      min = local.ssh_port_number
    }
  }
  ingress_security_rules {
    description = "TCP access from Kubernetes Control Plane"
    source      = local.k8s_endpoint_subnet_cidr
    source_type = "CIDR_BLOCK"
    protocol    = local.tcp_protocol_number
    stateless   = false
  }
  ingress_security_rules {
    description = "Path discovery"
    source      = local.k8s_endpoint_subnet_cidr
    source_type = "CIDR_BLOCK"
    protocol    = local.icmp_protocol_number
    stateless   = false

    icmp_options {
      type = "3"
      code = "4"
    }
  }

  # Egresses
  egress_security_rules {
    description      = "Allow pods on one worker node to communicate with pods on other worker nodes"
    destination      = local.subnet_regional_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = local.all_protocols
    stateless        = false
  }
  egress_security_rules {
    description      = "Worker Nodes access to Internet"
    destination      = local.all_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = local.all_protocols
    stateless        = false
  }
  egress_security_rules {
    description      = "Allow nodes to communicate with OKE to ensure correct start-up and continued functioning"
    destination      = local.service_cidr
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol         = local.tcp_protocol_number
    stateless        = false

    tcp_options {
      max = local.https_port_number
      min = local.https_port_number
    }
  }
  egress_security_rules {
    description      = "ICMP Access from Kubernetes Control Plane"
    destination      = local.all_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = local.icmp_protocol_number
    stateless        = false

    icmp_options {
      type = "3"
      code = "4"
    }
  }
  egress_security_rules {
    description      = "Access to Kubernetes API Endpoint"
    destination      = local.k8s_endpoint_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = local.tcp_protocol_number
    stateless        = false

    tcp_options {
      max = local.k8s_api_endpoint_port_number
      min = local.k8s_api_endpoint_port_number
    }
  }
  egress_security_rules {
    description      = "Kubernetes worker to control plane communication"
    destination      = local.k8s_endpoint_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = local.tcp_protocol_number
    stateless        = false

    tcp_options {
      max = local.k8s_worker_to_control_plane_port_number
      min = local.k8s_worker_to_control_plane_port_number
    }
  }
  egress_security_rules {
    description      = "Path discovery"
    destination      = local.k8s_endpoint_subnet_cidr
    destination_type = "CIDR_BLOCK"
    protocol         = local.icmp_protocol_number
    stateless        = false

    icmp_options {
      type = "3"
      code = "4"
    }
  }

}

#########################################################################

resource "oci_core_security_list" "oke_lb_security_list" {
  compartment_id = var.compartment_ocid
  display_name   = "oke-lb-seclist-${local.deploy_id}"
  vcn_id         = oci_core_virtual_network.oke_vcn.id

}


