
# Lookup image to get id
data "digitalocean_image" "official" {
  count = var.custom_image == true ? 0 : 1
  slug  = var.image_name
}

#Module      : Droplet
#Description : Provides a DigitalOcean Droplet resource. This can be used to create, modify, and delete Droplets.
resource "digitalocean_droplet" "main" {
  count = var.droplet_enabled == true ? var.droplet_count : 0

  image              = join("", data.digitalocean_image.official.*.id)
  name               = var.name
  region             = var.region
  size               = var.droplet_size
  backups            = var.backups
  monitoring         = var.monitoring
  ipv6               = var.ipv6
  private_networking = var.private_networking
  ssh_keys           = var.ssh_keys
  resize_disk        = var.resize_disk
  user_data          = var.user_data
  vpc_uuid           = var.vpc_uuid
}

#Module      : Volume
#Description : Provides a DigitalOcean Block Storage volume which can be attached to a Droplet in order to provide expanded storage.
resource "digitalocean_volume" "main" {
  count = var.droplet_enabled == true ? var.droplet_count : 0

  region                   = var.region
  name                     = var.name
  size                     = var.block_storage_size
  description              = "Block storage for ${element(digitalocean_droplet.main.*.name, count.index)}"
  initial_filesystem_label = var.block_storage_filesystem_label
  initial_filesystem_type  = var.block_storage_filesystem_type
}

#Module      : Volume Attachment
#Description : Manages attaching a Volume to a Droplet.
resource "digitalocean_volume_attachment" "main" {
  count = var.droplet_enabled == true ? var.droplet_count : 0

  droplet_id = element(digitalocean_droplet.main.*.id, count.index)
  volume_id  = element(digitalocean_volume.main.*.id, count.index)
}

#Module      : Floating Ip
#Description : Provides a DigitalOcean Floating IP to represent a publicly-accessible static IP addresses that can be mapped to one of your Droplets.
resource "digitalocean_floating_ip" "main" {
  count  = var.floating_ip == true && var.droplet_enabled == true ? var.droplet_count : 0
  region = var.region
}

#Module      : Floating Ip Assignment
#Description : Provides a DigitalOcean Floating IP to represent a publicly-accessible static IP addresses that can be mapped to one of your Droplets.
resource "digitalocean_floating_ip_assignment" "main" {
  count = var.floating_ip == true && var.droplet_enabled == true ? var.droplet_count : 0

  ip_address = element(digitalocean_floating_ip.main.*.id, count.index)
  droplet_id = element(digitalocean_droplet.main.*.id, count.index)
  depends_on = [digitalocean_droplet.main]
}
