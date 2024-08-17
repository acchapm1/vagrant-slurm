#########################
### Example overrides ###
#########################

# This configuration as-is will take 10 threads/cores and 10 GB of RAM assuming
# that .settings.yml isn't overriding the defaults. Make sure you have enough
# resources before running something like this.

# Set SLURM_NODES in .settings and update the slurm.conf if you run more/less than 4 nodes
# NOTE: The primes.sh script was only designed to run an array across two nodes.

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
