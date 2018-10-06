provider "digitalocean" {}
variable "ssh_pub_key" {}

resource "digitalocean_ssh_key" "tfsshkey" {
    name = "tfkey"
    public_key = "${file("${var.ssh_pub_key}")}"
}

resource "digitalocean_droplet" "controller" {
    image = "ubuntu-16-04-x64"
    name = "controller"
    region = "blr1"
    ssh_keys = ["${digitalocean_ssh_key.tfsshkey.id}"]
    size = "4gb"
    private_networking = "true"
}
resource "digitalocean_droplet" "nodes" {
    count = 2
    image = "ubuntu-16-04-x64"
    name = "node-0${count.index+1}"
    region = "blr1"
    ssh_keys = ["${digitalocean_ssh_key.tfsshkey.id}"]
    size = "2gb"
    private_networking = "true"
}


resource "null_resource" "controller-certs" {
    triggers {
        controller_ip = "${digitalocean_droplet.controller.ipv4_address}"
    }
    provisioner "local-exec" {
        command = "../scripts/gen-certs.sh && ../scripts/gen-api-cert.sh"
        working_dir = "../scripts"
        environment {
            instance = "controller"
            publicip = "${digitalocean_droplet.controller.ipv4_address}"
            privateip = "${digitalocean_droplet.controller.ipv4_address_private}"
        }
    }
}

resource "null_resource" "kubelet-certs" {
    count = 2
    triggers {
        node_ips = "${join(",","${digitalocean_droplet.nodes.*.ipv4_address}")}"
    }
    provisioner "local-exec" {
        command = "../scripts/gen-certs.sh && ../scripts/gen-kubelet-cert.sh"
        working_dir = "../scripts"
        environment {
            instance = "node-0${count.index+1}"
            publicip = "${element("${digitalocean_droplet.nodes.*.ipv4_address}", "${count.index}")}"
            privateip = "${element("${digitalocean_droplet.nodes.*.ipv4_address_private}", "${count.index}")}"
        }
    }

}
output "controller_ip_address" {
    value = "${digitalocean_droplet.controller.ipv4_address}"
}
output "controller_private_ip_address" {
    value = "${digitalocean_droplet.controller.ipv4_address_private}"
}

output "node_ip_address" {
    value = "${digitalocean_droplet.nodes.*.ipv4_address}"
}

output "node_private_ip_address" {
    value = "${digitalocean_droplet.nodes.*.ipv4_address_private}"
}

# create certs after controller and nodes are up, create inventory
# once certs is created run ansible script on all nodes

terraform {
    backend "s3" {
        bucket = "tf-state-store"
        region = "us-east-1" # required but totally ignored
        endpoint = "https://sgp1.digitaloceanspaces.com"
        key = "state-store/tf.tfstate"

        # Hey DO is only S3 compatible not exactly S3
        skip_credentials_validation = true
        skip_get_ec2_platforms = true
        skip_requesting_account_id = true
        skip_metadata_api_check = true
    }
}