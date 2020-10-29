# openstack-k8s/ansible

#### Provisioning steps

##### Provision the host

Provision a host with RHEL 8.2 or CentOS should also work with at least 128GB of RAM

##### Clone the repository to the beaker host

The ansible playbooks can be used as any user, but this user needs to be able to
get root priviledges to the host via passwordless sudo.

```
ssh root@<node>
dnf install -y git
git clone git@github.com:openstack-k8s-operators/osp-director-dev-tools.git
```

##### Install Ansible

If not already installed, install ansible

```
dnf install -y ansible
```

##### Modify the variable files

Modify `ansible/vars/default.yaml` to meet your req.

##### Create local-deaults.yaml file with personal information

Create `local-deaults.yaml` file with information to `secrets_repo` which holds
the `pull-secret` and `rhel-subscription.yaml` files. `rhel-subscription.yaml` in the
format:

```
rhel_subscription_activation_key: xyz
rhel_subscription_org_id: "123123123"
```

`local-deaults.yaml` has the min format:

```
secrets_repo: https://path/to/my/repo.git
ci_token: <TOKEN>
```

You can get this token from https://api.ci.openshift.org/ by
clicking on your name in the top right corner and coping the login
command (the token is part of the command)

Any other parameter from `vars/default.yaml` can be customized using
`local-deaults.yaml`. Add parameters to meet your req.

##### Install all steps using the Makefile

There is a Makefile which runs all the steps per default

```
dnf install -y make
cd osp-director-dev-tools/ansible
make
```

**Note**
prepare_host.yaml will delete the home lvs and grow the root partition to max.
In case there is data stored on /home, make a backup!

##### When installation finished

* On the local system add the required entries to your local /etc/hosts. The previous used ansible playbook also outputs the information:

```
cat <<EOF >> /etc/hosts
192.168.111.4   console-openshift-console.apps.ostest.test.metalkube.org console openshift-authentication-openshift-authentication.apps.ostest.test.metalkube.org api.ostest.test.metalkube.org prometheus-k8s-openshift-monitoring.apps.ostest.test.metalkube.org alertmanager-main-openshift-monitoring.apps.ostest.test.metalkube.org kubevirt-web-ui.apps.ostest.test.metalkube.org oauth-openshift.apps.ostest.test.metalkube.org grafana-openshift-monitoring.apps.ostest.test.metalkube.org
EOF
```

**Note**
The cluster name is used in the hostname records, where `ostest` is the default in dev-scripts.
Update the above example to use the cluster name set in the vars file.

Run:

```
sshuttle -r <user>@<virthost> 192.168.111.0/24 192.168.25.0/24
```

Now you can access the OCP console using your local web browser: <https://console-openshift-console.apps.ostest.test.metalkube.org>

User: `kubeadmin`
Pwd: `/home/ocp/dev-scripts/ocp/<cluster name>/auth/kubeadmin-password`

You can also access the OCP console using your local web browser: <http://192.168.25.100>

User: `admin`
Pwd: The admin password can be found in the `/home/stack/cnvrc` file on the undercloud.

##### Access the OCP env from cli

```
su - ocp
export KUBECONFIG=/home/ocp/dev-scripts/ocp/ostest/auth/kubeconfig
oc get pods -n openstack
```

#### Cleanup full env:

```
make cleanup
```

#### Othere possible cleanup steps

##### Delete ocp env only

```
make destroy_ocp
```

##### Delete OSP controllers
TODO:
```
make ocp_controller_cleanup
```

##### Tempest to run functional test

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
