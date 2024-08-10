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

# Install MUNGE
apt-get update
apt-get install -y munge

# Create a dedicated non-privileged user account for MUNGE
getent group munge > /dev/null || groupadd -r -g 900 munge
id -u munge &>/dev/null || \
  useradd -r -u 900 -g munge -d /var/lib/munge -s /usr/sbin/nologin munge

# node1 = manager
if [ "$(hostname)" == "node1" ]; then
  # Create common MUNGE key on the manager node
  if [ ! -f /etc/munge/munge.key ]; then
    sudo -u munge /usr/sbin/mungekey --verbose
  fi

  # Set MUNGE key perms
  chmod 600 /etc/munge/munge.key

  # Copy to shared directory for other nodes
  cp /etc/munge/munge.key /vagrant/munge.key

  # Enable/start/test munge service
  systemctl enable munge.service
  systemctl start munge.service
  munge -n | unmunge
else
  # Initial delay
  sleep 5

  # Waits JOIN_TIMEOUT of seconds to find the munge.key file before giving up
  START_TIME="$(date +%s)"
  # Wait until the munge.key can be found via Vagrant provider file sharing /vagrant
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
  cp /vagrant/munge.key /etc/munge/munge.key
  systemctl enable munge.service
  systemctl start munge.service
  munge -n | unmunge
fi
