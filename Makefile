virtualenv:
	test -d .venv-ansible-lint || python3.6 -m venv .venv-ansible-lint
	source .venv-ansible-lint/bin/activate; pip install -U ansible-lint

ansible-lint: virtualenv
	source .venv-ansible-lint/bin/activate; ansible-lint **/*.yaml

clean:
	rm -rf .venv-ansible-lint
	find -iname "*.pyc" -delete

