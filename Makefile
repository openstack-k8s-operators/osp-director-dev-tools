ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
ANSIBLE_HOME:=$(ROOT_DIR)/.ansible
export ANSIBLE_HOME

virtualenv:
	test -d .venv-ansible-lint || python3 -m venv .venv-ansible-lint
	source .venv-ansible-lint/bin/activate; pip install -U ansible-lint==25.6.1

ansible-lint: virtualenv
	ansible-galaxy install -r ansible/requirements.yml
	source .venv-ansible-lint/bin/activate; ansible-lint

clean:
	rm -rf .venv-ansible-lint
	find -iname "*.pyc" -delete

