# Pentest lab on GCP using Terraform, Chef, Ansible, and Vagrant

_Because why not use all the things?_

This repo is a general stash of my setup for how I provisioned and managed a vpn private network, including a
to-be-assessed ultra-vulnerable server, for each of twenty teams in my information security management class, Fall 2019.

I wanted to be able to borrow from and contribute back to [metasploitable3's ub1404 project](https://github.com/rapid7/metasploitable3), so I used chef for provisioning
the vulnerable server. I used vagrant to play the chef recipe provisioning on top of a `ubuntu-1404-lts` gcp box. When the midterm
server was mostly complete, I manually created a gcp image of it. I could have used [packer to create the image via chef-solo](https://www.packer.io/docs/provisioners/chef-solo.html).

I used terraform to create a workspace for each team. Each workspace has:

* an isolated vpc
* firewall rules allowing only ssh from the outside world, but allowing all traffic on the private network
* an openvpn server provisioned via a customized easy-openvpn script
* a copy of a vulnerable server based on the most recent image from my image family for the vuln server.

I used a few bash scripts for automating the process of managing all 20 workspaces -- for `terraform apply`ing, etc. Naturally, I had to do
some hot fixes to the vulnerable servers in the middle of the assignment timeframe. While I could have updated the base vuln server image and
had terraform tear down and recreate each of the vuln servers for each workspace, this led to too much downtime for the students, and was too
tedious for me. So, I initially looked to using a Chef Server for managing each vuln server. But I gave up on this when I hit some gotchas with
trying to automate the `knife` provisioning of each vuln server with the Chef Server. I switched to ansible instead, dynamically creating
the ansible inventory file from a script iterating over `terraform output` which spit out each workspace's vuln server ip. The ansible
playbook uploads a zip of the within-project chef recipes, runs them on the server, and then deletes the zip. I'm sure there's a cleaner
way to do that, but hey, it's fast and easy, and it works.

I'm removing most of my chef recipes from this public repo -- except for the basic functionality ones -- just to make it harder for nosy students to complete the midterm task. On the other hand,
heh, they're business school students, they probably can't read ruby anyhow.



## GCP

I created a gcp project specifically for this midterm assignment. 
I also `ssh-keygen` created a private-public keypair specifically for provisioning for this project, 
and I added this public key to the gcp project metadata, with username `_provisioner`. In the files in this
repo, I also added this private-public keypair as user `tyler`'s. That's what the reference to `tyler-midterm-vuln` is
in some of the config files. It's used to connect as the `_provisioner`.

I also created a gcp service account for this project (can't remember what permissions I gave it), and I downloaded it as json 
and called it `midterm-vuln-gcp-private-key.json`.


## Vagrant and Chef

Run these: 

    vagrant plugin install vagrant-vbguest
    vagrant plugin install vagrant-google

The chef-solo runlist is read from a file `chef_runlist`, because the ansible playbook also needs it.

Do your initial vuln midterm server creation using `vagrant up`, `vagrant provision`, etc. When you're satisfied, create a gcp image
from your instance. For compatibility with this repo's terraform config (`main.tf`), call your image family `midterm-vuln`.

I managed external chef cookbook dependencies using `berks`, which is provided by the `ChefDK`. Running `berks vendor` puts the berks cookbooks in a separate directory (IIRC).



## Terraform

I named my teams like this: `team-<team_number`. A convenience script in `scripts/create_all.sh` helps with the creation of all workspaces.

Terraform round-robin creates the workspaces in one of five regions. This is because I hit gcp quota limits for public ips -- max 8 per region by default, and surprise, they didn't
want to allow me to jump up to 40 ips for one region without me going through sales first. That's this part:

    locals {
        vpn_config_dir = "vpn_configs"
        gcp_regions = ["us-central1","us-east1","us-east4","us-west1","us-west2"]
        
        team_number_split = split("-",terraform.workspace)
        team_number = length(local.team_number_split) > 1 ? local.team_number_split[1] : 1
        google_region = local.gcp_regions[(local.team_number - 1) % length(local.gcp_regions)]
    }
    
    
My vuln midterm server "company" was called `humbleify` (`resource "google_compute_instance" "midterm-vuln"`). The humbleify server was given an ip address of `192.168.10.107`.

The vpn server was provisioned via (`resource "google_compute_instance" "openvpn"`). It is based on gcp image debian-9. It is provisioned (`resource "null_resource" "openvpn_bootstrap"`) via `openvpn-install.sh`,
which is a fork of `https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh`. This vpn server has some crucial key differences from one used solely as a tunnel for an 
individual computer's traffic:

* It allows clients on the vpn network to see and talk to one another
* It allows multiple clients to simultaneously use the same config file.

After the vpn server is bootstrapped, the `client.conf` config file is `scp`'ed down to `vpn_configs/`, and then uploaded to the vuln midterm server (`resource "null_resource" "openvpn_upload_midtermvuln_vpn_config").
I had already installed the openvpn package on the midterm servers in my base image.


## Ansible hot-patching

I dynamically managed the inventory by running `scripts/get_all_ips.sh`, which relies on `output "midterm_vuln_ip"` and `output "team-name"` being provided by the terraform workspaces.

I created a `team-999` workspace that I used for testing my chef recipe live provision hot-fixes. `scripts/ansible-playbook-999.sh` runs the ansible playbook for just `team-999`. 
After the success of the hot-patch was confirmed, I ran `scripts/ansible-playbook.sh`.

    
