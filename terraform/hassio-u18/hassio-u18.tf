# variables that can be overriden
variable "hostname" { default = "datadisks" }
variable "domain" { default = "example.com" }
variable "ip_type" { default = "static" } # dhcp is other valid type
variable "memoryMB" { default = 1024 * 1 }
variable "cpu" { default = 1 }
variable "prefixIP" { default = "192.168.122" }
variable "octetIP" { default = "32" }
variable "libvirt_pool" { default = "default" }
variable "libvirt_uri" { default = "qemu:///system" }

# 161.79 gigabytes for each additional data disk
variable "diskBytes" { default = 160 * 1024 * 1024 * 1024 }



# instance the provider
provider "libvirt" {
  uri = var.libvirt_uri
}

# fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "cloudimg" {
  name   = "${var.hostname}-bionic-server-cloudimg-amd64.img"
  pool   = var.libvirt_pool
  format = "raw" # .img
  source = "https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img"
}

resource "libvirt_volume" "os_image" {
  name   = "${var.hostname}-os.qcow2"
  pool   = var.libvirt_pool
  size   = var.diskBytes
  format = "qcow2"

  # Uses the cloudimg as backing_disk/base_volume.
  base_volume_name = "${var.hostname}-bionic-server-cloudimg-amd64.img"
}

# extra data disk for xfs
resource "libvirt_volume" "disk_data1" {
  name   = "${var.hostname}-disk-data1-xfs.qcow2"
  pool   = var.libvirt_pool
  size   = var.diskBytes
  format = "qcow2"
}
# extra data disk for ext4
resource "libvirt_volume" "disk_data2" {
  name   = "${var.hostname}-disk-data2-ext4.qcow2"
  pool   = var.libvirt_pool
  size   = var.diskBytes
  format = "qcow2"
}

# Use CloudInit ISO to add ssh-key to the instance
resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "${var.hostname}-commoninit.iso"
  pool           = var.libvirt_pool
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
}

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
  vars = {
    hostname = var.hostname
    fqdn     = "${var.hostname}.${var.domain}"
  }
}

data "template_file" "network_config" {
  template = file("${path.module}/network_config_${var.ip_type}.cfg")
  vars = {
    domain   = var.domain
    prefixIP = var.prefixIP
    octetIP  = var.octetIP
  }
}


# Create the machine
resource "libvirt_domain" "domain-ubuntu" {
  name   = "${var.hostname}-${var.prefixIP}.${var.octetIP}"
  memory = var.memoryMB
  vcpu   = var.cpu

  network_interface {
    network_name = "default"
  }

  disk { volume_id = libvirt_volume.os_image.id }
  disk { volume_id = libvirt_volume.disk_data1.id }
  disk { volume_id = libvirt_volume.disk_data2.id }

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  # IMPORTANT
  # Ubuntu can hang is a isa-serial is not present at boot time.
  # If you find your CPU 100% and never is available this is why
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = "true"
  }

  provisioner "file" {
    source      = "file/supervised-installer-safer.sh"
    destination = "/root/supervised-installer-safer.sh"
  }
}

terraform {
  required_version = ">= 0.12"
}

output "metadata" {
  value = libvirt_domain.domain-ubuntu
}
