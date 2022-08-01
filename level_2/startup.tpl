terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.35.0"
    }
  }
}

# Configure the OpenStack Provider
provider "openstack" {
  user_name   = "utkin@posteo.net"
  tenant_name = "utkin@posteo.net"
  password    = "Hu0menTa"
  auth_url    = "https://infra.mail.ru:35357/v3/"
  region      = "RegionOne"
  use_octavia  = true
}

resource "openstack_networking_network_v2" "network_1" {
  name           = "network_1"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet_1" {
  name       = "subnet_1"
  network_id = openstack_networking_network_v2.network_1.id
  cidr       = "192.168.199.0/24"
  ip_version = 4
}

resource "openstack_compute_secgroup_v2" "secgroup_1" {
  name        = "secgroup_1"
  description = "Rules for secgroup_1"

  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_instance_v2" "web-server-1" {
  name            = "web-server-1"
  image_id        = "785bd3c3-6d63-44f8-b2ad-4e37afc38a38"
  flavor_id       = "df3c499a-044f-41d2-8612-d303adc613cc"
  key_pair        = "my_key_pair"
  security_groups = ["default", "${openstack_compute_secgroup_v2.secgroup_1.name}"]
  user_data       = "${file("start.sh")}"

  network {
    name = openstack_networking_network_v2.network_1.name
  }
}

resource "openstack_compute_instance_v2" "web-server-2" {
  name            = "web-server-1"
  image_id        = "785bd3c3-6d63-44f8-b2ad-4e37afc38a38"
  flavor_id       = "df3c499a-044f-41d2-8612-d303adc613cc"
  key_pair        = "my_key_pair"
  security_groups = ["default", "${openstack_compute_secgroup_v2.secgroup_1.name}"]
  #user_data       = "#cloud-config\nhostname: instance_1.example.com\nfqdn: instance_1.example.com"

  network {
    name = openstack_networking_network_v2.network_1.name
  }
}

resource "openstack_lb_monitor_v1" "monitor_1" {
  type           = "TCP"
  delay          = 30
  timeout        = 5
  max_retries    = 3
  admin_state_up = "true"
}

resource "openstack_lb_pool_v1" "pool_1" {
  name        = "pool_1"
  protocol    = "TCP"
  subnet_id   = openstack_networking_subnet_v2.subnet_1.id
  lb_method   = "ROUND_ROBIN"
  monitor_ids = ["${openstack_lb_monitor_v1.monitor_1.id}"]
}

resource "openstack_lb_member_v1" "member_1" {
  pool_id = openstack_lb_pool_v1.pool_1.id
  address = openstack_compute_instance_v2.web-server-1.access_ip_v4
  port    = 80
}

resource "openstack_lb_member_v1" "member_2" {
  pool_id = openstack_lb_pool_v1.pool_1.id
  address = openstack_compute_instance_v2.web-server-2.access_ip_v4
  port    = 80
}

resource "openstack_lb_vip_v1" "vip_1" {
  name      = "vip_1"
  subnet_id = openstack_networking_subnet_v2.subnet_1.id
  protocol  = "TCP"
  port      = 80
  pool_id   = openstack_lb_pool_v1.pool_1.id
}
