#!/bin/bash

#######################################
### Install and setup Slurm cluster ###
#######################################

# Print commands and exit on error
set -xe

# Prevents interactive prompts during package installation
export DEBIAN_FRONTEND=noninteractive

# Keep system clocks in sync
apt-get update
apt-get install -y chrony
systemctl start chrony
systemctl enable chrony

# Create MUNGE user
getent group munge > /dev/null || groupadd -r -g 900 munge
id -u munge &>/dev/null || \
  useradd -r -u 900 -g munge -d /var/lib/munge -s /usr/sbin/nologin munge

# Create slurm user
getent group slurm > /dev/null || groupadd -g 1001 slurm
id -u slurm &>/dev/null || \
  useradd -m -u 1001 -g slurm -s /bin/bash slurm

# Create submit user
getent group submit > /dev/null || groupadd -g 1002 submit
id -u submit &>/dev/null || \
  useradd -M -u 1002 -g submit -s /bin/bash -d /vagrant/scratch/submit submit
mkdir -p /vagrant/scratch/submit

# Update APT cache
apt-get update

# Install MUNGE, remove any default key, and stop to place another key later
if ! dpkg -s munge &>/dev/null; then
  apt-get install -y munge
  systemctl stop munge
  rm -f /etc/munge/munge.key
fi

# Install slurm client tools
dpkg -s slurm-client &>/dev/null || apt-get install -y slurm-client

# Create directories for Slurm
mkdir -p /var/spool/slurm /var/log/slurm /etc/slurm
chown slurm:slurm /var/spool/slurm /var/log/slurm /etc/slurm

# Copy slurm.conf and cgroup.conf
cp -u /vagrant/slurm.conf /etc/slurm/slurm.conf
cp -u /vagrant/cgroup.conf /etc/slurm/cgroup.conf
chown slurm:slurm /etc/slurm/slurm.conf /etc/slurm/cgroup.conf
chmod 644 /etc/slurm/slurm.conf /etc/slurm/cgroup.conf

# node1 = manager
if [ "$(hostname)" == "node1" ]; then
  # Create common MUNGE key on the manager node
  if [ ! -f /etc/munge/munge.key ]; then
    sudo -u munge /usr/sbin/mungekey --verbose
  fi

  # Copy to shared directory for other nodes
  cp /etc/munge/munge.key /vagrant/munge.key

  # Enable/start/test munge service
  chmod 400 /etc/munge/munge.key
  systemctl enable munge
  systemctl start munge

  # Install Slurm Workload Manager and doc package for the Slurm config tool
  if ! dpkg -s slurm-wlm &>/dev/null; then
    apt-get install -y slurm-wlm slurm-wlm-doc

    # Create directories for slurmctld
    systemctl stop slurmctld
    mkdir -p /var/spool/slurmctld
    chown slurm:slurm /var/spool/slurmctld
    chmod 755 /var/spool/slurmctld

    # Start Slurm controller
    systemctl enable slurmctld
    systemctl start slurmctld
  fi
else
  # Initial delay
  sleep 5

  # Waits JOIN_TIMEOUT of seconds to find the munge.key file before giving up
  START_TIME="$(date +%s)"

  # Wait until the munge.key can be found via Vagrant provider file sharing
  while [ ! -f /vagrant/munge.key ]; do
    CURRENT_TIME="$(date +%s)"
    DIFF_TIME="$((CURRENT_TIME - START_TIME))"

    # Timeout
    if [ "$DIFF_TIME" -ge "$JOIN_TIMEOUT" ]; then
      echo "[ERROR]: $(hostname) waited $DIFF_TIME/$JOIN_TIMEOUT seconds"
      exit 1
    fi

    # Waiting
    echo "Waiting ($DIFF_TIME/$JOIN_TIMEOUT seconds) for /vagrant/munge.key file"
    sleep 10
  done

  # Enable/start/test munge service
  cp -f /vagrant/munge.key /etc/munge/munge.key
  chown munge:munge /etc/munge/munge.key
  chmod 400 /etc/munge/munge.key
  systemctl enable munge
  systemctl start munge

  # Install SLURM compute node daemon on node[3-4]
  if [[ $(hostname) == node[3-4] ]]; then
    mkdir -p /var/spool/slurmd
    chown slurm:slurm /var/spool/slurmd
    apt-get install -y slurmd
    systemctl enable slurmd
    systemctl start slurmd
  fi
fi
