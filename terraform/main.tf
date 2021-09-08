provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
  credentials = file("${var.credentials}")
}

resource "google_compute_firewall" "firewall" {
  name    = "firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["6443", "2379", "2380", "9099", "10250", "10254", "80", "443"]
  }
  allow {
    protocol = "udp"
    ports    = ["8472"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "master-node" {
  name         = "master-node"
  machine_type = "e2-standard-2"

  boot_disk {
    initialize_params {
    image = "ubuntu-os-cloud/ubuntu-2004-lts"
    size  = 10
    }
  }

  metadata = {
    ssh-keys = "${var.user}:${file("${var.ssh_pub_key}")}"
  }

  network_interface {
    network = "default"
    access_config {}
  }

  depends_on = [google_compute_firewall.firewall]

}

resource "google_compute_instance" "work-node" {
  count        = var.numnodes
  name         = "work-node-${count.index}"
  machine_type = "e2-standard-2"

  boot_disk {
    initialize_params {
    image = "ubuntu-os-cloud/ubuntu-2004-lts"
    size  = 10
    }
  }

  metadata = {
    ssh-keys = "${var.user}:${file("${var.ssh_pub_key}")}"
  }

  network_interface {
    network = "default"
    access_config {}
  }

  # Ensure firewall rule is provisioned before server, so that SSH doesn't fail.
  depends_on = [google_compute_firewall.firewall]

}

# generate hosts file for Ansible
resource "local_file" "hosts" {
  content = templatefile("./templates/ansible-hosts.tpl",
    {
      master_ip  = google_compute_instance.master-node.network_interface.0.access_config.0.nat_ip
      workers_ip = google_compute_instance.work-node.*.network_interface.0.access_config.0.nat_ip
      user       = "${var.user}"
      ssh_secret_key = "${var.ssh_secret_key}"
    }
  )
  filename = "../ansible/hosts"

  depends_on = [google_compute_instance.work-node, google_compute_instance.master-node]
}

# generate cluster.yml
resource "local_file" "cluster" {
  content = templatefile("./templates/k8s-cluster.tpl",
    {
      master_ip  = google_compute_instance.master-node.network_interface.0.access_config.0.nat_ip
      workers_ip = google_compute_instance.work-node.*.network_interface.0.access_config.0.nat_ip
      user       = "${var.user}"
      ssh_secret_key = "${var.ssh_secret_key}"
    }
  )
  filename = "../k8s/cluster.yml"

  provisioner "local-exec" {
    command = "rm ../k8s/kube_config_cluster.yml && rm ../k8s/cluster.rkestate"
  }

  depends_on = [google_compute_instance.work-node, google_compute_instance.master-node]
}