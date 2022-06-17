#!/bin/sh
ansible-galaxy collection install -r requirements.yml
colRet=$?
set -e
if [ $colRet -ne 0 ]; then
  ANSIBLE_DIR="$HOME/.ansible/collections/ansible_collections"
  PODMAN_GIT_DIR="$ANSIBLE_DIR/containers/podman"
  COMMUNITY_GENERAL_GIT_DIR="$ANSIBLE_DIR/community/general"
  echo "Installing Ansible Podman Collections using git"
  mkdir -p "$ANSIBLE_DIR/containers"
  rm -rf "$PODMAN_GIT_DIR"
  git clone https://github.com/containers/ansible-podman-collections.git "$PODMAN_GIT_DIR" 

  echo "Installing Ansible Community General Collections using git"
  mkdir -p "$ANSIBLE_DIR/community"
  rm -rf "$COMMUNITY_GENERAL_GIT_DIR"
  git clone https://github.com/ansible-collections/community.general.git "$COMMUNITY_GENERAL_GIT_DIR" 

fi

echo "Installing roles using ansible-galaxy"
ansible-galaxy role install -r requirements.yml

