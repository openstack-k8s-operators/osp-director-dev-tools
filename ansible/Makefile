# make openstack OSP_RELEASE=17.0
ifndef OSP_RELEASE
OSP_RELEASE = 16.2
endif

default: \
  ocp_install \
  cnv_install \
  sriov_install \
  olm \
  openstack

all: default

hosts:
	echo -e "localhost ansible_connection=local\n\n[convergence_base]\nlocalhost" > $@

local-defaults.yaml:
	echo -e "vars:" > $@

local-deps:
	# This should work for both roles and collections, but does not:
	# ansible-galaxy install -r requirements.yml
	# ...so we install requirements twice, once for roles and once for collections
	chmod 755 ./local_deps.sh
	./local_deps.sh

download_tools: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-v -i hosts -e @vars/${OSP_RELEASE}.yaml \
	-e @vars/kuttl_tests.yaml \
	-e @local-defaults.yaml \
	download_tools.yaml

ocp_install:
	$(MAKE) host_prep
	$(MAKE) ocp_installer_prep
	$(MAKE) ocp_installer
	$(MAKE) post_install

host_prep: hosts local-deps local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook -i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	host_prep.yaml

ocp_installer_prep: hosts local-deps local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook -i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	ocp_installer_prep.yaml

ocp_installer: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook -i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	ocp_installer.yaml

post_install: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	local_oc_client.yaml \
	ocp_ai_post_install.yaml \
	ocp_default_storageclass.yaml \
	ocp_image_registry.yaml
	$(MAKE) custom_registries
	$(MAKE) nics
	$(MAKE) freeipa

custom_registries: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	ocp_custom_registries.yaml

nics: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	ocp_vm_setup_extra_nics.yaml

freeipa: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	freeipa.yaml

freeipa_cleanup: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	freeipa_cleanup.yaml

cnv_install: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	ocp_cnv.yaml

sriov_install: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	ocp_sriov.yaml \
	virt_sriov.yaml

perf_install: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	ocp_performance.yaml

git: hosts local-deps local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook -v -i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	git.yaml

openstack:
	$(MAKE) datavolume
	$(MAKE) networks
	$(MAKE) git
	$(MAKE) ctlplane
	$(MAKE) computes
	$(MAKE) patch_csv
	$(MAKE) osp_deploy
	$(MAKE) must_gather

openstack_update:
	$(MAKE) patch_csv
	$(MAKE) osp_update
	$(MAKE) must_gather

osp_update:
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	osp_update.yaml

patch_csv: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
        -e @vars/${OSP_RELEASE}.yaml \
        -e @local-defaults.yaml \
        patch_csv.yaml

osp_deploy: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	osp_deploy.yaml

register_overcloud_nodes: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	osp_register_overcloud_nodes.yaml
	$(MAKE) fencing_prep

fencing_prep: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	osp_tripleo_fencing_overrides.yaml

openstack_cleanup: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	openstack_cleanup.yaml

director_image_cleanup: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	director_image_cleanup.yaml

networks: hosts local-defaults.yaml
	# NOTE: requires 'make olm'
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	install_networks.yaml

ctlplane: hosts local-defaults.yaml
	# NOTE: requires 'make olm'
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	install_ctlplane.yaml

computes: hosts local-defaults.yaml
	# NOTE: requires 'make olm'
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	install_computes.yaml

config_generator: hosts local-defaults.yaml
	# NOTE: requires 'make olm'
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	config_generator.yaml

datavolume: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	datavolume.yaml

datavolume_cleanup: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	datavolume_cleanup.yaml

osp_custom_config: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	osp_custom_config.yaml

osp_content: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	osp_content.yaml

osp_tempest: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	osp_tempest.yaml

kuttl_tests: hosts local-defaults.yaml
	$(MAKE) download_tools
	ANSIBLE_FORCE_COLOR=true ansible-playbook -i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @vars/kuttl_tests.yaml \
	-e @local-defaults.yaml \
	osp_kuttl.yaml

osp_sts: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	osp_sts.yaml

olm: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-v -i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	install_namespace.yaml \
	olm.yaml \
	patch_csv.yaml

olm_cleanup: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-v -i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	olm_cleanup.yaml

local_storage: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-v -i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	local_storage.yaml

local_storage_cleanup: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-v -i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	local_storage_cleanup.yaml

nfs_cleanup: hosts
	ANSIBLE_FORCE_COLOR=true ansible -i hosts convergence_base \
	--become -m shell -a \
	"set -x; \
	 rm -f /etc/exports.d/host-nfs-storageclass.exports; \
	 rm -f /etc/exports.d/glance.exports; \
	 rm -f /etc/exports.d/cinder*.exports; \
	 exportfs -ra; \
	 umount -d /home/nfs/pv-*; \
	 rm -rf /home/nfs; \
	 temp=$$(mktemp); \
	 grep -v "^/home/nfs/data/pv-" /etc/fstab > \$$temp; \
	 cat \$$temp > /etc/fstab; \
	 rm \$$temp"

destroy_ocp: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook -i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	ocp_installer_destroy.yaml
	$(MAKE) openstack_cleanup nfs_cleanup

must_gather: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook -i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	must_gather.yaml

demo: hosts
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	demo.yaml

cnosp:
	$(MAKE) cnosp_install
	$(MAKE) cnosp_ctlplane_deploy

cnosp_install: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook -i hosts \
        -e @vars/${OSP_RELEASE}.yaml \
        -e @local-defaults.yaml \
	install_namespace.yaml \
        cnosp_olm.yaml

cnosp_cleanup: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook -i hosts \
        -e @vars/${OSP_RELEASE}.yaml \
        -e @local-defaults.yaml \
        cnosp_olm_cleanup.yaml

cnosp_ctlplane_deploy: hosts local-defaults.yaml
	# NOTE: requires 'make cnosp_install'
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts -e @local-defaults.yaml \
	cnosp_ctlplane_deploy.yaml

cnosp_ctlplane_cleanup: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts -e @local-defaults.yaml \
	cnosp_ctlplane_cleanup.yaml
