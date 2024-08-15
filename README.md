# Vagrant Slurm

**Warning: For demonstration/testing purposes only, not suitable for use in production**

This repository contains a `Vagrantfile` and the necessary configuration for
automating the setup of a Slurm cluster using Vagrant's shell provisioning on
Debian 12 x86_64 VMs.

### Prerequisites

This setup was developed using vagrant-libvirt with NFS for file sharing,
rather than the more common VirtualBox configuration which typically uses
VirtualBox's Shared Folders. However, VirtualBox should work fine.

The core requirements for this setup are:
- Vagrant (with functioning file sharing)
- (Optional) Make (for convenience commands)

### Cluster Structure
- `node1`: Head Node (runs `slurmctld`)
- `node2`: Login/Submit Node
- `node3` / `node4`: Compute Nodes (runs `slurmd`)

By default, each node is allocated:
- 2 threads/cores (depending on architecture)
- 2 GB of RAM

**Warning: 8 vCPUs and 8 GB of RAM is used in total resources**

## Quick Start

1. To build the cluster, you can use either of these methods

    Using the Makefile (recommended):

       make

    Using Vagrant directly:

       vagrant up

2. Login to the Login Node (node2) as the submit user:

       vagrant ssh node2 -c "sudo -iu submit"


3. Run the example prime number search script:

	   /vagrant/primes.sh

	By default, this script searches for prime numbers from `1-10,000` and `10,001-20,000`

   You can adjust the range searched per node by providing an integer argument, e.g.:

	   /vagrant/primes.sh 20000

	The script will then drop you into a `watch -n0.1 squeue` view so you can see
   the job computing on `nodes[3-4]`. You may `CTRL+c` out of this view, and
   the job will continue in the background. The home directory for the `submit`
   user is in the shared `/vagrant` directory, so the results from each node are
   shared back to the login node.

4. View the resulting prime numbers found, check `ls` for exact filenames

       less slurm-1_0.out
       less slurm-2_1.out

### Configuration Tool

On the Head Node (`node1`), you can access the configuration tools specific to
the version distributed with Debian. Since this may not be the latest Slurm
release, it's important to use the configuration tool that matches the
installed version. To access these tools, you can use Python to run a simple
web server:

	python3 -m http.server 8080 --directory /usr/share/doc/slurm-wlm/html/

You can then access the HTML documentation via the VM's IP address at port 8080
in your web browser on the host machine.

### Cleanup
To clean up files placed on the host through Vagrant file sharing:

	make clean

This command is useful when you want to remove all generated files and return
to a clean state. The Makefile is quite simple, so you can refer to it directly
to see exactly what's being cleaned up.
