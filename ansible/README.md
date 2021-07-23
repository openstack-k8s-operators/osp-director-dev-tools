# openstack-k8s/ansible

DO NOT MERGE

### Provisioning steps

#### Provision the host

Provision a host with RHEL 8.3 or CentOS should also work with at least 128GB of RAM

#### Clone the repository to the beaker host

The ansible playbooks can be used as any user, but this user needs to be able to
get root priviledges to the host via passwordless sudo.

```
ssh root@<node>
dnf install -y git
git clone git@github.com:openstack-k8s-operators/osp-director-dev-tools.git
```

#### Install Dependencies

If not already installed, install the required dependencies

```
dnf install -y ansible git libvirt-client python3-netaddr python3-lxml
```

#### Modify the variable files

Modify `ansible/vars/default.yaml` to meet your req.

#### Create local-defaults.yaml file with personal information

First create the following files relative to the project root:

`vars/rhel-subscription.yaml` in the format:

```
rhel_subscription_activation_key: xyz
rhel_subscription_org_id: "123123123"
```

`files/pull-secret` which contains your OCP pull-secrets file.

Any other parameter from `vars/default.yaml` can be customized using
`local-defaults.yaml`. Add parameters to meet your req.

You may and the optionally add a `secrets_repo` setting to your `local-defaults.yaml`.
NOTE: `secrets_repo` is optional, if unset the above files must be manually copied
into place inside this project.

Also follow either the "IPI install" or "Assisted install" instructions below,
depending on which deployment method you prefer to use

##### Installer Provisioned Infrastructure (IPI) install via dev-scripts

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

##### Assisted Installer (AI) install via assisted service

Create `local-defaults.yaml` file with settings like so:

```
ocp_ai: true
```

##### 3-master-worker-combo nodes install via AI

We support the ability to deploy a cluster without dedicated workers -- instead using the master nodes as both
masters and workers -- through our assisted installer integration.  To do so, set the following variables in
your `local-defaults.yaml`:

```
ocp_ai: true
ocp_num_workers: 0
ocp_master_memory: 40000
ocp_master_vcpu: 12
ocp_master_disk: 50
```

Note that `ocp_num_extra_workers` still defaults to 2 in `vars/default.yaml`, meaning 2 extra VMs will be created
for use as OSP compute nodes.  You may obviously change this if needed.

#### Install all steps using the Makefile

There is a Makefile which runs all the steps per default

```
dnf install -y make
cd osp-director-dev-tools/ansible
make
```

**Note**
prepare_host.yaml will delete the home lvs and grow the root partition to max.
In case there is data stored on /home, make a backup!

#### When installation finished

On the local system add the required entries to your local /etc/hosts. The previous used ansible playbook also outputs the information:

```
cat <<EOF >> /etc/hosts
192.168.111.4   console-openshift-console.apps.ostest.test.metalkube.org console openshift-authentication-openshift-authentication.apps.ostest.test.metalkube.org api.ostest.test.metalkube.org prometheus-k8s-openshift-monitoring.apps.ostest.test.metalkube.org alertmanager-main-openshift-monitoring.apps.ostest.test.metalkube.org kubevirt-web-ui.apps.ostest.test.metalkube.org oauth-openshift.apps.ostest.test.metalkube.org grafana-openshift-monitoring.apps.ostest.test.metalkube.org
EOF
```

#### Access OCP
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

sshuttle -r <user>@<virthost> 192.168.111.0/24 192.168.25.0/24
```

Now you can access the OCP console using your local web browser: <https://console-openshift-console.apps.ostest.test.metalkube.org>

| <!-- --> | <!-- --> |
| ------------ | ------------ |
| User | `kubeadmin` |
| Pwd (IPI) | `/home/ocp/dev-scripts/ocp/ostest/auth/kubeadmin-password` |
| Pwd (AI) | `/home/ocp/cluster_mgnt_roles/kubeadmin-password.ostest` |

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
export KUBECONFIG=/home/ocp/cluster_mgnt_roles/kubeconfig.ostest
oc get pods -n openstack
```

#### Install OSP

The ansible playbook generates the scaffolding needed for tripleo to deploy OpenStack. The actual OpenStack installation need to be triggered manually
```
oc exec -it -n openstack openstackclient /home/cloud-admin/deploy_tripleo.sh
```

#### Access OSP
You can also access the OSP console using your local web browser: <http://192.168.25.100>

| <!-- --> | <!-- --> |
| ------------ | ------------ |
| User | `admin` |
| Pwd | The admin password can be found in the `/home/cloud-admin/.config/openstack/clouds.yaml` file on the `openstackclient` pod in the `openstack` namespace. |

```
oc exec -it openstackclient -- cat /home/cloud-admin/.config/openstack/clouds.yaml | grep -w password
```

### Cleanup options

#### Delete OCP env

NOTE: This destroys the OCP cluster, and thus the OSP-D operator and any deployed overcloud!

```
make destroy_ocp
```

#### Delete OSP overcloud only

NOTE: This deletes the overcloud and the OCP resources that are associated with it.  
      It does not remove the OCP cluster nor the OSP-D operator, however.

```
make openstack_cleanup
```

#### Delete the operator only

NOTE: This deletes the OSP-D operator, but leaves any resources it deployed intact.  
      However, if those resources later change and would require OCP reconciliation, 
      the OSP-D operator will obviously not be present to act upon them.

```
make olm_cleanup
```

#### Tempest to run functional test

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
