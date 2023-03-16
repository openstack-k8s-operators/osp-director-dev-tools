# openstack-k8s/ansible

## Provisioning steps

### Provision the host

Provision a host with RHEL 8.5 or CentOS should also work with at least 128GB of RAM

### Clone the repository to the beaker host

The ansible playbooks can be used as any user, but this user needs to be able to
get root priviledges to the host via passwordless sudo.

```
ssh root@<node>
dnf install -y git
git clone git@github.com:openstack-k8s-operators/osp-director-dev-tools.git
```

### Install Dependencies

If not already installed, install the required dependencies

```
dnf install -y ansible git libvirt-client python3-netaddr python3-lxml make gcc
```

> NOTE: make sure you install ansible >= 2.9.27 otherwise ansible collections will not work correctly

### Generate SSH keys

Generate an SSH key on the host where you're going to be deploying from. The public key is used to access the deployed OpenShift cluster.

```
ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa
```

### Create local-defaults.yaml file with personal information

First create the following files relative to the project root:

`files/pull-secret` which contains your OCP pull-secrets file.

`vars/rhel-subscription.yaml` is optional. File format:

```
rhel_subscription_activation_key: xyz
rhel_subscription_org_id: "123123123"
```

If `vars/rhel-subscription.yaml` is not specified, a subscription must have been configured manually prior to running the ansible. The manual subscription must give access to the following repositories:

```
advanced-virt-for-rhel-8-x86_64-rpms                    Advanced Virtualization for RHEL 8 x86_64 (RPMs)
ansible-2-for-rhel-8-x86_64-rpms                        Red Hat Ansible Engine 2 for RHEL 8 x86_64 (RPMs)
openstack-16-for-rhel-8-x86_64-rpms                     Red Hat OpenStack 16 for RHEL 8 x86_64 (RPMs)
rhel-8-for-x86_64-appstream-rpms                        Red Hat Enterprise Linux 8 for x86_64 - AppStream (RPMs)
rhel-8-for-x86_64-baseos-rpms                           Red Hat Enterprise Linux 8 for x86_64 - BaseOS (RPMs)
```

Any other parameter from `vars/default.yaml` can be customized using
`local-defaults.yaml`. Add parameters to meet your req.

You may and the optionally add a `secrets_repo` setting to your `local-defaults.yaml`.
NOTE: `secrets_repo` is optional, if unset the above files must be manually copied
into place inside this project.

Also follow either the "IPI install" or "Assisted install" instructions below,
depending on which deployment method you prefer to use

#### Installer Provisioned Infrastructure (IPI) install via dev-scripts

Create `local-defaults.yaml` file with a setting for `ci_token`
or export CI_TOKEN shell variable in your environment.

You can get ci_token from https://console-openshift-console.apps.ci.l2s4.p1.openshiftapps.com/
by clicking on your name in the top right corner and coping the login
command (the token is part of the command)

`local-defaults.yaml` has the min format:

```
ci_token: <TOKEN>
```

If using CI_TOKEN as shell variable, which has precedence over
`local-defaults.yaml` use:

```
export CI_TOKEN: <TOKEN>
```

#### Assisted Installer (AI) install via assisted service

Create `local-defaults.yaml` file with settings like so:

```
ocp_ai: true
```

#### 3-master-worker-combo nodes install via AI

We support the ability to deploy a cluster without dedicated workers -- instead using the master nodes as both
masters and workers -- through our assisted installer integration.  To do so, set the following variables in
your `local-defaults.yaml`:

```
ocp_ai: true
ocp_num_workers: 0
ocp_master_memory: 40000
ocp_master_vcpu: 12
ocp_master_disk: 120
```

Note that `ocp_num_extra_workers` still defaults to 2 in `vars/default.yaml`, meaning 2 extra VMs will be created
for use as OSP compute nodes.  You may obviously change this if needed.

#### Baremetal install via AI

*WARNING: Currently experimental and not fully-tested!*

If you wish to install either baremetal OCP master and/or worker nodes, using AI is required:

```
ocp_ai: true
```

In order to establish connectivity with the DHCP/DNS server that this tool configures, an interface
must be chosen on the provisioning host to attach to the OCP SDN bridge created there.  This interface
should be connected to the same layer 2 network to which the baremetal OCP cluster nodes are also
connected.

```
ocp_bm_interface: <some interface>
```

Furthermore, it should be noted that all baremetal node BMC endpoints must be routable from the provisioning
host.  The interface on the provisioning host that is able to reach the baremetal node BMCs must be specified:

```
ocp_bmc_interface: <some interface>
```

Additionally, "extra" baremetal workers (those to be used as OSP computes) must be connected to a layer 2
provisioning network that the OCP masters also can reach, as this is needed for provisioning purposes by Metal3.

Assuming network considerations have been accounted for, one can then set the `ocp_num_(masters|workers|extra_workers)` 
count(s) to `0` for the respective roles that you desire to deploy against baremetal:

```
ocp_num_masters: 0
ocp_num_workers: 0
ocp_num_extra_workers: 0
```

From there you would then provide baremetal details for any role for which you have set the `ocp_num_*` 
count to `0`:

```
ocp_bm_masters:
  master-0:
    vendor: somevendor          # Node's vendor (a general idea of supported vendors can be sussed-out here):
                                # https://github.com/redhat-partner-solutions/crucible/tree/main/roles/boot_iso/tasks
    bm_mac: XX:XX:XX:XX:XX:XX   # Node's MAC for interface on OCP SDN network
    bmc_address: X.X.X.X        # Node's BMC endpoint
    bmc_username: username      # Node's BMC username
    bmc_password: password      # Node's BMC password
    root_device: /dev/sda       # optional, defaults to /dev/sda
  master-1:
    ...
  master-2:
    ...

ocp_bm_workers:
  worker-0:
    vendor: somevendor          # (see vendor note above)
    bm_mac: XX:XX:XX:XX:XX:XX   # Node's MAC for interface on OCP SDN network
    bmc_address: X.X.X.X        # Node's BMC endpoint
    bmc_username: username      # Node's BMC username
    bmc_password: password      # Node's BMC password
    root_device: /dev/sda       # optional, defaults to /dev/sda
  worker-1:
    ...

ocp_bm_extra_workers:
  worker-2:
    vendor: somevendor          # (see vendor note above)
    bm_mac: XX:XX:XX:XX:XX:XX   # optional, if for some reason the OSP compute needs an assigned IP on the OCP network
    prov_mac: XX:XX:XX:XX:XX:XX # extra workers use Metal3 -- node's MAC for interface on OCP provisioning network
    bmc_protocol: someprotocol  # extra workers use Metal3, which need this extra detail (this is related to vendor, 
                                # but is not necessarily deterministic -- thus we require you to explicitly provide it)
    bmc_address: X.X.X.X        # Node's BMC endpoint
    bmc_username: username      # Node's BMC username
    bmc_password: password      # Node's BMC password
    root_device: /dev/sda       # optional, defaults to /dev/sda
  worker-3:
    ...
```

It is possible to mix virtual and baremetal nodes, but not within the same role (masters or workers).  You could,
for instance, set `ocp_num_masters: 3` and then define `ocp_bm_workers` if you wanted a virtual control plane
for OCP but baremetal for any hosted workload.

#### Hybrid install via AI

Hybrid installs involve deploying a virtualized OCP cluster along with baremetal computes ("extra workers")
for use in a deployed OSP cloud.

If you wish to deploy a hybrid environment, using AI is required:

```
ocp_ai: true
```

All "extra worker" baremetal OSP compute nodes must be connected to a layer 2 provisioning network that the OCP
masters also can reach, as this is needed for provisioning purposes by Metal3.  A provisioning host interface must
be provided that allows access to this provisioning network:

```
ocp_bm_prov_interface: <some interface>
```

Furthermore, it should be noted that all baremetal OSP compute BMC endpoints must be routable from the
provisioning host.  The interface on the provisioning host that is able to reach the baremetal node BMCs
must be specified:

```
ocp_bmc_interface: <some interface>
```

The provisioning host must also provide network access to layer 2 network that will serve as the OSP network.
This allows the OSP CNV controllers to connect with the OSP baremetal computes for API, storage, tenant, etc 
traffic:

```
osp_bm_interface: <some interface>
```

Finally, from a networking perspective, an interface on the provisioning host must be provided that allows
connectivity with a routable network that serves as the OSP external network.  OSP CNV controllers running on
the OCP master/workers will use this to connect to the baremetal OSP compute external interfaces (and vice
versa) to allow for OSP floating IP functionality:

```
osp_ext_bm_interface: <some interface>
```

Assuming network considerations have been accounted for, set virtual OCP master/workers as needed:

```
ocp_num_masters: 3
ocp_num_workers: 0..N
```

Make sure to set OSP virtual compute count to `0`:

```
ocp_num_extra_workers: 0
```

Then declare the baremetal OSP computes:

```
ocp_bm_extra_workers:
  worker-<ocp_num_workers+1>:
    vendor: somevendor          # Node's vendor (a general idea of supported vendors can be sussed-out here):
                                # https://github.com/redhat-partner-solutions/crucible/tree/main/roles/boot_iso/tasks
    bm_mac: XX:XX:XX:XX:XX:XX   # optional, if for some reason the OSP compute needs an assigned IP on the OCP network
    prov_mac: XX:XX:XX:XX:XX:XX # extra workers use Metal3 -- node's MAC for interface on OCP provisioning network
    bmc_protocol: someprotocol  # extra workers use Metal3, which need this extra detail (this is related to vendor,
                                # but is not necessarily deterministic -- thus we require you to explicitly provide it)
    bmc_address: X.X.X.X        # Node's BMC endpoint
    bmc_username: username      # Node's BMC username
    bmc_password: password      # Node's BMC password
    root_device: /dev/sda       # optional, defaults to /dev/sda
  worker-<ocp_num_workers+2>:
    ...
```

### Install all steps using the Makefile

There is a Makefile which runs all the steps per default

```
dnf install -y make
cd osp-director-dev-tools/ansible
make
```

**Note**
The default OSP version deployed is 16.2 if you'd like to deploy OSP 17.0 provide the version using OSP_RELEASE, like:

```
make OSP_RELEASE=17.0
```

The version specific defaults are located in vars/X.Y.yaml.


**Note**
prepare_host.yaml will delete the home lvs and grow the root partition to max.
In case there is data stored on /home, make a backup!

### When installation finished

On the local system add the required entries to your local /etc/hosts. The previous used ansible playbook also outputs the information:

```
cat <<EOF >> /etc/hosts
192.168.111.4   console-openshift-console.apps.ostest.test.metalkube.org console openshift-authentication-openshift-authentication.apps.ostest.test.metalkube.org api.ostest.test.metalkube.org prometheus-k8s-openshift-monitoring.apps.ostest.test.metalkube.org alertmanager-main-openshift-monitoring.apps.ostest.test.metalkube.org kubevirt-web-ui.apps.ostest.test.metalkube.org oauth-openshift.apps.ostest.test.metalkube.org grafana-openshift-monitoring.apps.ostest.test.metalkube.org
EOF
```

### Access OCP
**Note**
The cluster name is used in the hostname records, where `ostest` is the default in the OCP installer.
Update the above example to use the cluster name set in the vars file.

To access OCP console

On the local system, enable SSH proxying:
```
# on Fedora
sudo dnf install sshuttle

# on RHEL
sudo pip install sshuttle

sshuttle -r <user>@<virthost> 192.168.111.0/24 172.22.0.0/24
```

Now you can access the OCP console using your local web browser: <https://console-openshift-console.apps.ostest.test.metalkube.org>

| <!-- --> | <!-- --> |
| ------------ | ------------ |
| User | `kubeadmin` |
| Pwd (IPI) | `/home/ocp/dev-scripts/ocp/ostest/auth/kubeadmin-password` |
| Pwd (AI) | `/home/ocp/crucible/kubeadmin-password.ostest` |

You can also access the OCP CLI:

IPI: 
```
su - ocp
export KUBECONFIG=/home/ocp/dev-scripts/ocp/ostest/auth/kubeconfig
oc get pods -n openstack
```

AI: 
```
su - ocp
export KUBECONFIG=/home/ocp/crucible/kubeconfig.ostest
oc get pods -n openstack
```

### Install OSP

If you ran all targets in the makefile (i.e. you invoked `make` without specifying a specific target) then the OSP deployment steps are also executed after the OCP cluster installation is finished. You can find the deployment logs at `/root/ostest-working/logs/osp-deploy.log` (if you changed the name of your cluster from the default `ostest` your local path will be different to reflect the cluster name).

If you need to run the OpenStack installation manually after the OCP cluster is deployed you can run:
```
oc exec -it -n openstack openstackclient /home/cloud-admin/tripleo-deploy.sh
```

### Access OSP
You can also access the OSP console using your local web browser: <http://172.22.0.100>

| <!-- --> | <!-- --> |
| ------------ | ------------ |
| User | `admin` |
| Pwd | The admin password can be found in the `/home/cloud-admin/.config/openstack/clouds.yaml` file on the `openstackclient` pod in the `openstack` namespace. |

```
oc exec -it openstackclient -n openstack -- cat /home/cloud-admin/.config/openstack/clouds.yaml | grep -w password
```

## Cleanup options

### Delete OCP env

NOTE: This destroys the OCP cluster, and thus the OSP-D operator and any deployed overcloud!

```
make destroy_ocp
```

### Delete OSP overcloud only

NOTE: This deletes the overcloud and the OCP resources that are associated with it.  
      It does not remove the OCP cluster nor the OSP-D operator, however.

```
make openstack_cleanup
```

### Delete the operator only

NOTE: This deletes the OSP-D operator, but leaves any resources it deployed intact.  
      However, if those resources later change and would require OCP reconciliation, 
      the OSP-D operator will obviously not be present to act upon them.

```
make olm_cleanup
```

### Tempest to run functional test

Create a tempest pod in OCP to run it. Tempest run is triggerd in an initContainer that we can wait
for the "normal" pod container which just runs a sleep to come up in ready state.

```
make osp_tests_run
```

Tempest can be controlled via vars in default.yaml file to be:
* enabled/disabled (default enabled)
  tempest_enabled: true/false
* tempest timeout in seconds to wait for the pod to come up:
  tempest_timeout: 1200
* tests to run, either empty array, which then triggers smoke test
  or a specified whitelist
  tempest_whitelist: []
  tempest_whitelist:
  - aaa
  - bbb
