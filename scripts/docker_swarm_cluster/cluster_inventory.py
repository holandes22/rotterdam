#!/usr/bin/env python

import os
import argparse
import subprocess

import simplejson


# Based on https://gist.github.com/nathanleclaire/1bbf18de7c73f89aa36c


def dm(*args):
    return subprocess.check_output(["docker-machine"] + list(args)).strip()


def dminspect(fmt, machine):
    return dm("inspect", "-f", fmt, machine)


def get_vars(machine, cluster_id=1):
    ssh_vars = {
        "cluster_id": cluster_id,
        "is_manager": "node1" in machine,
        "ip_address": dminspect("{{.Driver.IPAddress}}", machine),
        "manager_ip_address": dminspect("{{.Driver.IPAddress}}", "cluster{}-node1".format(cluster_id)),
        "ansible_host": "localhost",
        "ansible_ssh_user": dminspect("{{.Driver.SSHUser}}", machine),
        "ansible_ssh_port": dminspect("{{.Driver.SSHPort}}", machine),
        "ansible_ssh_private_key_file": dminspect("{{.Driver.SSHKeyPath}}", machine)
    }
    return ssh_vars


def get_hosts(machine):
    return [dm("ip", machine)]


class DockerMachineInventory(object):

    def __init__(self):
        self.inventory = {} # Ansible Inventory

        parser = argparse.ArgumentParser(
            description='Produce an Ansible Inventory file based on Docker Machine status')
        parser.add_argument('--list', action='store_true')
        self.args = parser.parse_args()
        cluster_id = os.getenv("DM_CLUSTER_ID", "1")

        name = "name=cluster{}-node".format(cluster_id)
        machines = dm("ls", "--filter", name, "--filter", "state=running", "--format={{.Name}}").splitlines()

        json_data = {
            machine: {
                "hosts": get_hosts(machine),
                "vars": get_vars(machine, cluster_id)
            } for machine in machines
        }

        print(simplejson.dumps(json_data))


DockerMachineInventory()
