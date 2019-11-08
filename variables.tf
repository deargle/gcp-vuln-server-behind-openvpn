variable "ssh_username" {
  description = "The user to connect to the instances as, typically the provisioner"
  default     = "_provisioner"
}

variable "ssh_private_key_file" {
  description = ""
  default     = "tyler-midterm-vuln"
}

variable "gcp_service_account_credentials" {
  default = "midterm-vuln-gcp-private-key.json"
}

variable "ovpn_config_directory" {
  description = "The name of the directory to eventually download the OVPN configuration files to"
  default     = "vpn_configs"
}

variable "openvpn_install_script_location" {
  description = "The location of an OpenVPN installation script compatible with https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh"
  default     = "https://raw.githubusercontent.com/deargle/openvpn-install/master/openvpn-install.sh"
}

