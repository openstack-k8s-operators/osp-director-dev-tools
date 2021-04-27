default: \
  ocp_install \
  cnv_install \
  sriov_install \
  olm \
  openstack
  #osp_tests_run

all: default

hosts:
	echo -e "localhost ansible_connection=local\n\n[convergence_base]\nlocalhost" > $@

local-defaults.yaml:
	echo -e "vars:" > $@

local-deps:
	# This should work for both roles and collections, but does not:
	# ansible-galaxy install -r requirements.yml
	# ...so we install requirements twice, once for roles and once for collections
	ansible-galaxy role install -r requirements.yml && ansible-galaxy collection install -r requirements.yml

download_tools: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-v -i hosts -e @local-defaults.yaml \
	download_tools.yaml

ocp_install:
	$(MAKE) host_prep
	$(MAKE) ocp_installer
	$(MAKE) post_install

host_prep: hosts local-deps local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook -i hosts -e @local-defaults.yaml \
	host_prep.yaml \
	ocp_installer_prep.yaml

ocp_installer: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook -i hosts -e @local-defaults.yaml \
	ocp_installer.yaml

post_install: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts -e @local-defaults.yaml \
	local_oc_client.yaml \
	ocp_ai_post_install.yaml \
	ocp_default_storageclass.yaml \
	ocp_image_registry.yaml \
	ocp_vm_setup_extra_nics.yaml

cnv_install: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts -e @local-defaults.yaml \
	ocp_cnv.yaml

sriov_install: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts -e @local-defaults.yaml \
	ocp_sriov.yaml \
	virt_sriov.yaml

perf_install: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts -e @local-defaults.yaml \
	ocp_performance.yaml

openstack:
	$(MAKE) datavolume
	$(MAKE) networks
	$(MAKE) osp_custom_config
	$(MAKE) ctlplane
	$(MAKE) computes
	# $(MAKE) overcloud

openstack_cleanup: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts -e @local-defaults.yaml \
	openstack_cleanup.yaml

networks: hosts local-defaults.yaml
	# NOTE: requires 'make olm'
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts -e @local-defaults.yaml \
	install_networks.yaml

ctlplane: hosts local-defaults.yaml
	# NOTE: requires 'make olm'
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts -e @local-defaults.yaml \
	install_ctlplane.yaml

computes: hosts local-defaults.yaml
	# NOTE: requires 'make olm'
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts -e @local-defaults.yaml \
	install_computes.yaml

datavolume: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts -e @local-defaults.yaml \
	datavolume.yaml

osp_custom_config: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts -e @local-defaults.yaml \
	osp_tripleo_deploy.yaml

osp_content: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts -e @local-defaults.yaml \
	osp_content.yaml

osp_tests_run: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts -e @local-defaults.yaml \
	osp_tempest_ocp.yaml

olm: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-v -i hosts -e @local-defaults.yaml \
	install_namespace.yaml \
	olm.yaml

olm_cleanup: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-v -i hosts -e @local-defaults.yaml \
	olm_cleanup.yaml

local_storage: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-v -i hosts -e @local-defaults.yaml \
	local_storage.yaml

local_storage_cleanup: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-v -i hosts -e @local-defaults.yaml \
	local_storage_cleanup.yaml

nfs_cleanup: hosts
	ANSIBLE_FORCE_COLOR=true ansible -i hosts convergence_base \
	--become -m shell -a \
	"set -x; \
	 rm -f /etc/exports.d/host-nfs-storageclass.exports; \
	 rm -f /etc/exports.d/glance.exports; \
	 exportfs -ra; \
	 umount -d /home/nfs/pv-*; \
	 rm -rf /home/nfs; \
	 temp=$$(mktemp); \
	 grep -v "^/home/nfs/data/pv-" /etc/fstab > \$$temp; \
	 cat \$$temp > /etc/fstab; \
	 rm \$$temp"

destroy_ocp: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook -i hosts -e @local-defaults.yaml \
	ocp_installer_destroy.yaml
	$(MAKE) nfs_cleanup

demo: hosts
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts -e @local-defaults.yaml \
	demo.yaml
