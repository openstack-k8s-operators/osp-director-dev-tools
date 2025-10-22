# make openstack OSP_RELEASE=17.0
ifndef OSP_RELEASE
OSP_RELEASE = 16.2
endif

# make openstack OSP_SCENARIO=dcn
ifndef OSP_SCENARIO
OSP_SCENARIO = default
endif

##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: default
default: \
  ocp_install \
  nmstate_install \
  cnv_install \
  sriov_install \
  olm \
  openstack

.PHONY: all
all: default

hosts:
	echo -e "localhost ansible_connection=local\n\n[convergence_base]\nlocalhost" > $@

local-defaults.yaml:
	echo -e "---" > $@

.PHONY: local-deps
local-deps:
	# This should work for both roles and collections, but does not:
	# ansible-galaxy install -r requirements.yml
	# ...so we install requirements twice, once for roles and once for collections
	chmod 755 ./local_deps.sh
	./local_deps.sh

.PHONY: download_tools
download_tools: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-v -i hosts -e @vars/${OSP_RELEASE}.yaml \
	-e @vars/kuttl_tests.yaml \
	-e @local-defaults.yaml \
	download_tools.yaml

##@ OCP

.PHONY: ocp_install
ocp_install: ## Deploy OpenShift env and run post targets which adds NICs for OSP and deploys FreeIPA (if enabled)
	$(MAKE) host_prep
	$(MAKE) ocp_installer_prep
	$(MAKE) ocp_installer
	$(MAKE) post_install
	$(MAKE) nmstate_install

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
	$(MAKE) update_pullsecret
	$(MAKE) nics
	$(MAKE) freeipa

custom_registries: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	ocp_custom_registries.yaml

.PHONY: update_pullsecret
update_pullsecret: hosts local-defaults.yaml ## update OpenShift pull secret with additional registry credentials
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	ocp_pullsecret_update.yaml

nics: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	ocp_vm_setup_extra_nics.yaml

.PHONY: destroy_ocp
destroy_ocp: hosts local-defaults.yaml ## destroy the OCP env and cleanup the host (nfs, git, ...)
	ANSIBLE_FORCE_COLOR=true ansible-playbook -i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	ocp_installer_destroy.yaml
	$(MAKE) openstack_cleanup nfs_cleanup

##@ FreeIPA

.PHONY: freeipa
freeipa: hosts local-defaults.yaml ## install freeipa
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	freeipa.yaml

.PHONY: freeipa_cleanup
freeipa_cleanup: hosts local-defaults.yaml ## cleanup freeipa deployment
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	freeipa_cleanup.yaml

##@ Operators

.PHONY: nmstate_install
nmstate_install: hosts local-defaults.yaml ## install nmstate operator
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	ocp_nmstate.yaml

.PHONY: cnv_install
cnv_install: hosts local-defaults.yaml ## install cnv operator
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	ocp_cnv.yaml

.PHONY: sriov_install
sriov_install: hosts local-defaults.yaml ## install sriov operator
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	ocp_sriov.yaml \
	virt_sriov.yaml

.PHONY: perf_install
perf_install: hosts local-defaults.yaml ## install performance operator
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	ocp_performance.yaml

##@ OSP Director Operator

.PHONY: olm
olm: hosts local-defaults.yaml ## deploy osp director operator
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-v -i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	install_namespace.yaml \
	olm.yaml \
	patch_csv.yaml

.PHONY: olm_cleanup
olm_cleanup: hosts local-defaults.yaml ## uninstall osp director operator
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-v -i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	olm_cleanup.yaml

.PHONY: git
git: hosts local-deps local-defaults.yaml ## prepare git repo on host
	ANSIBLE_FORCE_COLOR=true ansible-playbook -v -i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	git.yaml

.PHONY: openstack
openstack: ## deploy openstack. Set OSP_SCENARIO=dcn to deploy dcn env
	$(MAKE) openstack_scenario_${OSP_SCENARIO}

openstack_scenario_default:
	$(MAKE) patch_csv
	$(MAKE) datavolume
	$(MAKE) networks
	$(MAKE) git
	$(MAKE) ctlplane
	$(MAKE) computes
	$(MAKE) osp_deploy
	$(MAKE) must_gather
	$(MAKE) get_logs

openstack_scenario_dcn:
	$(MAKE) patch_csv
	$(MAKE) datavolume
	$(MAKE) networks
	$(MAKE) git
	$(MAKE) ctlplane
	$(MAKE) computes
	$(MAKE) osp_deploy_dcn_central
	$(MAKE) osp_deploy_dcn_1
	$(MAKE) osp_cell_v2_discover_hosts
	$(MAKE) must_gather
	$(MAKE) get_logs

osp_cell_v2_discover_hosts: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-v -i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	osp_cell_v2_discover_hosts.yaml

openstack_scenario_dmbs:
	$(MAKE) patch_csv
	$(MAKE) datavolume
	$(MAKE) networks
	$(MAKE) git
	$(MAKE) ctlplane
	$(MAKE) computes
	$(MAKE) osp_deploy_dcn_central
	$(MAKE) osp_deploy_dcn_1
	$(MAKE) osp_redeploy_dcn_central
	$(MAKE) osp_cell_v2_discover_hosts
	$(MAKE) must_gather
	$(MAKE) get_logs

osp_redeploy_dcn_central: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	osp_redeploy_dcn_central.yaml

.PHONY: openstack_update
openstack_update: ## perform an overcloud minor update bu patching the csv for the new version and perform the update.
	$(MAKE) patch_csv
	$(MAKE) osp_update
	$(MAKE) must_gather
	$(MAKE) get_logs

osp_update:
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	osp_update.yaml

.PHONY: openstack_upgrade
openstack_upgrade:
	$(MAKE) osp_upgrade
	$(MAKE) must_gather
	$(MAKE) get_logs

osp_upgrade:
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @vars/ffu.yaml \
	-e @local-defaults.yaml \
	osp_upgrade.yaml

.PHONY: openstack_upgrade_multirhel
openstack_upgrade_multirhel:
	$(MAKE) osp_upgrade_multirhel_ctrls_comp1
	$(MAKE) osp_upgrade_multirhel_computes
	$(MAKE) must_gather
	$(MAKE) get_logs

.PHONY: osp_upgrade_multirhel_ctrls_comp1
osp_upgrade_multirhel_ctrls_comp1:
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @vars/ffu.yaml \
	-e @local-defaults.yaml \
	osp_upgrade_multirhel_ctrls_comp1.yaml

.PHONY: osp_upgrade_multirhel_computes
osp_upgrade_multirhel_computes:
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @vars/ffu.yaml \
	-e @local-defaults.yaml \
	osp_upgrade_multirhel_computes.yaml

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

osp_deploy_dcn_central: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	osp_deploy_dcn_central.yaml

osp_deploy_dcn_1: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	osp_deploy_dcn_1.yaml

.PHONY: register_overcloud_nodes
register_overcloud_nodes: hosts local-defaults.yaml ## register overcloud nodes to required repositories
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

.PHONY: openstack_cleanup
openstack_cleanup: hosts local-defaults.yaml ## delete overcloud
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

.PHONY: networks
networks: hosts local-defaults.yaml ## creates osnetcfg and creates required VLANs on the host ospnetwork + applies firewall rules
	# NOTE: requires 'make olm'
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	install_networks.yaml

.PHONY: ctlplane
ctlplane: hosts local-defaults.yaml ## creates the ctlplane VMs
	# NOTE: requires 'make olm'
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	install_ctlplane.yaml

.PHONY: computes
computes: hosts local-defaults.yaml ## provision the compute nodes
	# NOTE: requires 'make olm'
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	install_computes.yaml

.PHONY: config_generator
config_generator: hosts local-defaults.yaml ## render the ansible playbooks using osconfiggenerator
	# NOTE: requires 'make olm'
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	config_generator.yaml

.PHONY: datavolume
datavolume: hosts local-defaults.yaml ## create the datavolume as base for the ctlplane VMs
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	datavolume.yaml

.PHONY: datavolume_cleanup
datavolume_cleanup: hosts local-defaults.yaml ## delete the datavolume, required e.g. when switch between 16.2 and 17.x
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	datavolume_cleanup.yaml

.PHONY: osp_custom_config
osp_custom_config: hosts local-defaults.yaml ## creates heat-env-config-deploy and tripleo-tarball-config-deploy
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

.PHONY: osp_tempest
osp_tempest: hosts local-defaults.yaml ## runs tempest
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	osp_tempest.yaml

.PHONY: kuttl_tests
kuttl_tests: hosts local-defaults.yaml ## runs kuttl tests
	$(MAKE) download_tools
	ANSIBLE_FORCE_COLOR=true ansible-playbook -i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @vars/kuttl_tests.yaml \
	-e @local-defaults.yaml \
	osp_kuttl.yaml

.PHONY: osp_sts
osp_sts: hosts local-defaults.yaml ## deploy sts
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	osp_sts.yaml

osp_nfv_tests: hosts local-defaults.yaml
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-v \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	osp_nfv_tests.yaml

.PHONY: osp_stf_tests
osp_stf_tests: hosts local-defaults.yaml ## run stf tests
	ANSIBLE_FORCE_COLOR=true ansible-playbook \
	-i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	osp_stf_tests.yaml

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
	 rm -f /etc/exports.d/overcloud.exports; \
	 exportfs -ra; \
	 umount -d /home/nfs/pv-*; \
	 rm -rf /home/nfs; \
	 temp=$$(mktemp); \
	 grep -v "^/home/nfs/data/pv-" /etc/fstab > \$$temp; \
	 cat \$$temp > /etc/fstab; \
	 rm \$$temp; \
	 systemctl daemon-reload"

.PHONY: must_gather
must_gather: hosts local-defaults.yaml ## collect data from the env running must-gather
	ANSIBLE_FORCE_COLOR=true ansible-playbook -i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	must_gather.yaml

.PHONY: get_logs
get_logs: hosts local-defaults.yaml ## collect data from overcloud nodes
	ANSIBLE_FORCE_COLOR=true ansible-playbook -i hosts \
	-e @vars/${OSP_RELEASE}.yaml \
	-e @local-defaults.yaml \
	get_logs.yaml

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
