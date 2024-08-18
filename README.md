# Vagrant Slurm

**Warning: For demonstration/testing purposes only, not suitable for use in production**

This repository contains a `Vagrantfile` and the necessary configuration for
automating the setup of a Slurm cluster using Vagrant's shell provisioning on
Debian 12 x86_64 VMs.

## Prerequisites

This setup was developed using vagrant-libvirt with NFS for file sharing.

- [Vagrant](https://wiki.debian.org/Vagrant)
(tested with 2.3.4 packaged by Debian 12)
- [Vagrant-libvirt provider](https://vagrant-libvirt.github.io/vagrant-libvirt/)
(tested with 0.11.2 packaged by Debian 12)
- Working Vagrant
[Synced Folders using NFS](https://developer.hashicorp.com/vagrant/docs/v2.3.4/synced-folders/nfs)
- (Optional) Make (for convenience commands)

### VirtualBox Incompatibility

While efforts were made to support VirtualBox, several challenges prevent its
use in the current state.

1. **Hostname Resolution**: Unlike libvirt, VirtualBox doesn't provide
automatic hostname resolution between VMs. This requires an additional private
network and potentially custom scripting or plugins to enable inter-VM
communication by hostname.

2. **Sequential Provisioning**: VirtualBox provisions VMs sequentially, which,
while preventing a now exceedingly rare race condition with the munge.key
generation and distribution, significantly increases the overall setup time
compared to vagrant-libvirt's parallel provisioning and complicates potential
scripted solutions for hostname resolution.

3. **Shared Folder Permissions**: VirtualBox's shared folder mechanism doesn't
preserve Unix permissions from the host system. The `vagrant` user owns all
shared files in the `/vagrant` mount point, complicating the setup of a
non-privileged `submit` user and stripping the execution bit from shared
scripts.

4. **Provider-Specific Options**: Using mount options for VirtualBox shared
folders is incompatible with libvirt, making maintaining a single,
provider-agnostic configuration challenging.

Potential workarounds like assigning static IPs compromise the flexibility of
the current setup. The fundamental differences between VirtualBox and libvirt
in handling shared folders and networking make it challenging to create a truly
provider-agnostic solution without significant compromises or overhead.

For now, this project focuses on the libvirt provider due to its better
compatibility with the requirements of an automated Slurm cluster setup. Future
development could explore creating separate, provider-specific configurations
to support VirtualBox, acknowledging the additional maintenance this would
require.

## Cluster Structure

- `node1`: Head Node (runs `slurmctld`)
- `node2`: Login/Submit Node
- `node3` / `node4`: Compute Nodes (runs `slurmd`)

By default, each node is allocated:
- 2 threads/cores (depending on architecture)
- 2 GB of RAM

**Warning: 8 vCPUs and 8 GB of RAM are used by default in total resources**

## Getting Started

1. To build the cluster, you can use either of these methods

    Using the Makefile (recommended):

       make

    Using Vagrant directly:

       vagrant up

2. Login to the Login Node (node2) as the submit user:

       vagrant ssh node2 -c "sudo -iu submit"


3. Run the example prime number search script:

	   /vagrant/primes.sh

	By default, this script searches for prime numbers from `1-10,000` and
  `10,001-20,000`

   You can adjust the range searched per node by providing an integer argument, e.g.:

	   /vagrant/primes.sh 20000

	The script will then drop you into a `watch -n0.1 squeue` view so you can see
  the job computing on `nodes[3-4]`. You may `CTRL+c` out of this view, and
  the job will continue in the background. The `submit` user's home directory
  is in the NFS shared `/vagrant` directory, so the results from each node
  are shared with the login node.

4. View the resulting prime numbers found (check `ls` for exact filenames)

       less slurm-1_0.out
       less slurm-1_1.out

## Configuration Tool

On the Head Node (`node1`), you can access the configuration tools specific to
the version distributed with Debian. Since this may not be the latest Slurm
release, using the configuration tool that matches the installed version is
important. To access these tools, you can use Python to run a simple web server

	python3 -m http.server 8080 --directory /usr/share/doc/slurm-wlm/html/

You can then access the HTML documentation via the VM's IP address at port 8080
in your web browser on the host machine.

## Cleanup
To clean up files placed on the host through Vagrant file sharing:

	make clean

This command is useful to remove all generated files and return to a clean
state. The Makefile is quite simple, so you can refer to it directly to see
what's being cleaned up.

If you have included override settings that you want to remove as well, run:

	git clean -fdx

This command will remove all untracked files and directories, including those
ignored by .gitignore. Be cautious when using this command, as it will delete
files that Git does not track. Use the `-n` flag to dry-run first.

## Overrides

### Global Overrides

**WARNING:** Always update `slurm.conf` to match any CPU overrides on compute
nodes to prevent resource allocation conflicts.

If you wish to override the default settings on a global level,
you can do so by creating a `.settings.yml` file based on the provided
`example-.settings.yml` file:

	cp example-.settings.yml .settings.yml

Once you have copied the `example-.settings.yml` to `.settings.yml`, you can
edit it to override the default settings. Below are the available settings:

#### Vagrant Settings Overrides
- `VAGRANT_BOX`
  - Default: `debian/bookworm64`
  - Tested most around Debian Stable x86_64 (currently Bookworm)
- `VAGRANT_CPU`
  - Default: `2`
  - Two threads or cores per node, depending on CPU architecture
- `VAGRANT_MEM`
  - Default: `2048`
  - Two GB of RAM per node
- `SSH_FORWARD`
  - Default: `false`
  - Enable this if you need to forward SSH agents to the Vagrant machines

#### Slurm Settings Overrides
- `SLURM_NODES`
  - Default: `4`
  - The _total_ number of nodes in your Slurm cluster
- `JOIN_TIMEOUT`
  - Default: `120`
  - Timeout in seconds for nodes to obtain the shared munge.key

#### Minimal Resource Setup
Resource-conscious users can copy and use the provided `example-.settings.yml`
file without modifications. This results in a cluster configuration using only
1 vCPU and 1 GB RAM per node (totaling 4 threads/cores and 4 GB RAM), allowing
basic operation on modest hardware.

When using this minimal setup with 1 vCPU, you'll need to update the
`slurm.conf` file. Apply the following change to the default `slurm.conf`:

	sed -i 's/CPUs=2/CPUs=1/g' slurm.conf

### Per-Node Overrides

**WARNING:** Remember to update `slurm.conf` to match any CPU overrides on
compute nodes to prevent resource allocation conflicts.

The naming convention for nodes follows a specific pattern: `nodeX`, where `X`
is a number corresponding to the node's position within the cluster. This
convention is strictly adhered to due to the iteration logic within the
`Vagrantfile`, which utilizes a loop iterating over an array range defined by
the number of slurm nodes (`Array(1..SLURM_NODES)`). Each iteration of the loop
corresponds to a node, and the loop counter is in the node name (`nodeX`).

The overrides, if specified in `nodes.rb`, take the highest precedence,
followed by the overrides in `.settings.yml`, and lastly, the defaults hard
coded in the `Vagrantfile` itself. This hierarchy allows for a flexible
configuration where global overrides can be specified in `.settings.yml`, and
more granular, per-node overrides can be defined in `nodes.rb`. If a particular
setting is not overridden in either `.settings.yml` or `nodes.rb`, the default
value from the `Vagrantfile` is used.

If you wish to override the default settings on a per-node level, you can do so
by creating a `nodes.rb` file based on the provided `example-nodes.rb` file:

	cp example-nodes.rb nodes.rb

Once you have copied the `example-nodes.rb` to `nodes.rb`, you can edit it to
override the default settings. Below are the available settings available
per-node:

- `BOX`
  - Default: `debian/bookworm64` (or as overridden in `.settings.yml`)
  - Vagrant box or image to be used for the node.
- `CPU`
  - Default: `2` (or as overridden in `.settings.yml`)
  - Defines the number of CPU cores or threads (depending on architecture).
- `MEM`
  - Default: `2048` (2 GB) (or as overridden in `.settings.yml`)
  - Specifies the amount of memory (in MB) allocated to the node.
- `SSH`
  - Default: `false` (or as overridden in `.settings.yml`)
  - Enable this if you need to forward SSH agents to the Vagrant machine

All settings are optional, and as many or as few options can be overridden on
any arbitrary node.
