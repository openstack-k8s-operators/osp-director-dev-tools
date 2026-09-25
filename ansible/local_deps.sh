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
  # Match containers.podman 1.20.2 from requirements.yml.
  git -C "$PODMAN_GIT_DIR" checkout --detach b657295880ea567441c609aae281ef007df3488c

  echo "Installing Ansible Community General Collections using git"
  mkdir -p "$ANSIBLE_DIR/community"
  rm -rf "$COMMUNITY_GENERAL_GIT_DIR"
  git clone https://github.com/ansible-collections/community.general.git "$COMMUNITY_GENERAL_GIT_DIR"
  # Match community.general 4.8.11 from requirements.yml.
  git -C "$COMMUNITY_GENERAL_GIT_DIR" checkout --detach c12fd2474b513d761900e9d25e26265b170b35ab

fi

echo "Installing roles using ansible-galaxy"
ansible-galaxy role install -r requirements.yml
