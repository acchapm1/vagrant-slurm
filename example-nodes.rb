#########################
### Example overrides ###
#########################

# This configuration as-is will take 10 threads/cores and 10 GB of RAM,
# assuming that .settings.yml isn't overriding the defaults. Make sure you have
# enough resources to run something like this.

# Set SLURM_NODES in .settings.yml and update the slurm.conf if you run
# more/less than 4 total nodes (with 2 compute nodes). If the number of
# compute nodes changes, this must be reflected in the slurm.conf file.
#
# Additionally, if the number of CPUs for the compute nodes changes, such as in
# this example, this would also need to be reflected in the slurm.conf file.
#
# NOTE: The primes.sh script was only designed to run an array across two nodes


NODES = {
  # Head node
  'node1' => {
    #'BOX' => 'debian/bookworm64',
    'CPU' => 1,
    'MEM' => 1024,
    #'SSH' => true
  },
  # Submit node
  'node2' => {
    #'BOX' => 'debian/bookworm64',
    'CPU' => 1,
    'MEM' => 1024,
    #'SSH' => true
  },
  # Compute node3
  'node3' => {
    #'BOX' => 'debian/bookworm64',
    'CPU' => 4,
    'MEM' => 4096,
    #'SSH' => true
  }
  # Compute node4
  'node4' => {
    #'BOX' => 'debian/bookworm64',
    'CPU' => 4,
    'MEM' => 4096,
    #'SSH' => true
  }
}
