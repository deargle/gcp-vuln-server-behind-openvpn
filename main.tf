locals {
    gcp_regions = ["us-central1","us-east1","us-east4","us-west1","us-west2"]
    
    team_number_split = split("-",terraform.workspace)
    team_number = length(local.team_number_split) > 1 ? local.team_number_split[1] : 1
    google_region = local.gcp_regions[(local.team_number - 1) % length(local.gcp_regions)]
}

provider "google" {
  credentials = file("${var.gcp_service_account_credentials}")

  project = "midterm-vuln"
  region  = "${local.google_region}"
  zone    = "${local.google_region}-c"
}

resource "google_compute_network" "vpc_network" {
  name = "midterm-vuln-network-${terraform.workspace}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "humbleify_subnet" {
    name = "humbleify-subnet-${terraform.workspace}"
    ip_cidr_range = "192.168.10.0/24"
    region = "${local.google_region}"
    network = "${google_compute_network.vpc_network.name}"
}

resource "google_compute_firewall" "allow-ssh" {
    name = "allow-ssh-${terraform.workspace}"
    network = "${google_compute_network.vpc_network.name}"
    direction = "INGRESS"
    
    allow {
        protocol = "tcp"
        ports = ["22"]
    }
}

resource "google_compute_firewall" "allow-icmp" {
    name = "allow-icmp-${terraform.workspace}"
    network = "${google_compute_network.vpc_network.name}"
    direction = "INGRESS"
    allow {
        protocol = "icmp"
    }
}

resource "google_compute_firewall" "allow-all-internal" {
    name = "allow-all-internal-${terraform.workspace}"
    network = "${google_compute_network.vpc_network.name}"
    direction = "INGRESS"
    source_ranges = ["${google_compute_subnetwork.humbleify_subnet.ip_cidr_range}"]
    
    allow {
        protocol = "tcp"
    }
    allow {
        protocol = "udp"
    }
    allow {
        protocol = "icmp"
    }
}

resource "google_compute_firewall" "allow-all-egress" {
    name = "allow-all-egress-${terraform.workspace}"
    network = "${google_compute_network.vpc_network.name}"
    direction = "EGRESS"
    
    allow {
        protocol = "tcp"
    }
    allow {
        protocol = "udp"
    }
    allow {
        protocol = "icmp"
    }
}

resource "google_compute_firewall" "allow-vpn-ingress" {
    name = "allow-vpn-ingress-${terraform.workspace}"
    network = "${google_compute_network.vpc_network.name}"
    direction = "INGRESS"
    
    allow {
        protocol = "udp"
        ports = ["1194"]
    }
    
    target_tags = ["openvpn"]
}

data "google_compute_image" "midterm-vuln" {
    family = "midterm-vuln"
}

resource "google_compute_instance" "midterm-vuln" {
    name    = "humbleify-${terraform.workspace}"
    machine_type = "g1-small"
    allow_stopping_for_update = true
    
    tags = [terraform.workspace]
    boot_disk {
        initialize_params {
            image = "${data.google_compute_image.midterm-vuln.self_link}"
        }
    }

    network_interface {
        network = google_compute_network.vpc_network.name
        subnetwork = google_compute_subnetwork.humbleify_subnet.name
        network_ip = "192.168.10.107"
        access_config {}
    }
}

resource "google_compute_instance" "openvpn" {
    name = "openvpn-${terraform.workspace}"
    machine_type = "f1-micro"
    tags = ["openvpn", terraform.workspace]
    
    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-9"
        }
    }
    
    network_interface {
        network = google_compute_network.vpc_network.name
        subnetwork = google_compute_subnetwork.humbleify_subnet.name
        network_ip = "192.168.10.100"
        access_config {}
    }
}

locals {
  openvpn_public_ip = "${google_compute_instance.openvpn.network_interface.0.access_config.0.nat_ip}"
  midterm_vuln_ip = "${google_compute_instance.midterm-vuln.network_interface.0.access_config.0.nat_ip}"
  vpnconfig_user_filename = "client-${terraform.workspace}.conf"
  vpnconfig_vulnserver_filename =  "vulnserver-${terraform.workspace}.conf"
}

resource "null_resource" "openvpn_bootstrap" {
  connection {
    type        = "ssh"
    host        = local.openvpn_public_ip
    user        = "${var.ssh_username}"
    port        = "22"
    private_key = "${file("${path.module}/${var.ssh_private_key_file}")}"
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "curl -O ${var.openvpn_install_script_location}",
      "chmod +x openvpn-install.sh",
      "sudo AUTO_INSTALL=y DNS=13 ./openvpn-install.sh",
    ]
  }
  provisioner "remote-exec" {
    script = "${path.module}/scripts/bootstrap-openvpn.sh"
  }
  
  provisioner "local-exec" {
    command = <<EOT
      mkdir -p ${var.vpn_config_dir};
      
      scp -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      -i ${path.root}/${var.ssh_private_key_file} \
      ${var.ssh_username}@${local.openvpn_public_ip}:/home/${var.ssh_username}/client.ovpn ${path.module}/${var.vpn_config_dir}/${local.vpnconfig_user_filename};
      
      cd ${var.vpn_config_dir};
      cp ${local.vpnconfig_user_filename} ${local.vpnconfig_vulnserver_filename};
      echo route-nopull >> ${local.vpnconfig_vulnserver_filename};
      echo "route 10.8.0.0 255.255.255.0" >> ${local.vpnconfig_vulnserver_filename};
      cd -;
    EOT
  }
  
}

resource "null_resource" "openvpn_upload_midtermvuln_vpn_config" {
  depends_on = ["null_resource.openvpn_bootstrap"]
  
  triggers = {
    # always_run = "${timestamp()}"
    midterm_box = google_compute_instance.midterm-vuln.id
  }
  
  connection {
    type        = "ssh"
    host        =  local.midterm_vuln_ip
    user        = "${var.ssh_username}"
    port        = "22"
    private_key = "${file("${path.module}/${var.ssh_private_key_file}")}"
    agent       = false
  }
  
  provisioner "file" {
    source = "${var.vpn_config_dir}/${local.vpnconfig_vulnserver_filename}"
    destination = "~/${local.vpnconfig_vulnserver_filename}"
  }
  
  provisioner "remote-exec" {
    inline = [
        "sudo mv ~/${local.vpnconfig_vulnserver_filename} /etc/openvpn/",
        "sudo service openvpn restart"
    ]
  }
}

output "midterm_vuln_ip" {
    value = local.midterm_vuln_ip
}

output "team-name" {
    value = terraform.workspace
}
