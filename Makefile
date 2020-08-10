.PHONY: clean clean-test clean-pyc clean-build docs help
.DEFAULT_GOAL := help

define BROWSER_PYSCRIPT
import os, webbrowser, sys

try:
	from urllib import pathname2url
except:
	from urllib.request import pathname2url

webbrowser.open("file://" + pathname2url(os.path.abspath(sys.argv[1])))
endef
export BROWSER_PYSCRIPT

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

BROWSER := python -c "$$BROWSER_PYSCRIPT"
CURRENT_DIR = $(shell pwd)

help:
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

clean: clean-build clean-pyc clean-test ## remove all build, test, coverage and Python artifacts

clean-build: ## remove build artifacts
	rm -fr build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -f {} +

clean-pyc: ## remove Python file artifacts
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

clean-test: ## remove test and coverage artifacts
	rm -fr .tox/
	rm -f .coverage
	rm -fr htmlcov/
	rm -fr .pytest_cache

lint: ## check style with flake8
	flake8 clru tests

test: ## run tests quickly with the default Python
	py.test

test-jenkins: ## run the test and generate the Jenkins report
	py.test --junitxml results.xml

coverage: ## check code coverage quickly with the default Python
	coverage run --source clru -m pytest

docs: ## generate Sphinx HTML documentation, including API docs
	rm -f docs/clru.rst
	rm -rf docs/modules
	sphinx-apidoc -o docs/modules clru
	$(MAKE) -C docs -e clean
	$(MAKE) -C docs -e html

docs-show: docs ## generate sphinx HTML documentation and open it on a Browser
	$(BROWSER) docs/_build/html/index.html

docs-doc8: ## check rST files for errors
	doc8



docs-docker: ## generate the docs using docker
	docker run \
		-it \
		--volume $(CURRENT_DIR):/src \
		--env AWS_ACCESS_KEY_ID \
		--env AWS_SECRET_ACCESS_KEY \
		--env AWS_REGION \
		--env ASSETS_BUCKET \
		--env PROJECT_NAME=clru \
		docker.jampp.com/readthedocs-image-builder:1.0.0-python2 \
		build_docs

release: dist ## package and upload a release
	twine upload -r jampp dist/*

dist: clean ## builds source and wheel package
	python setup.py sdist
	python setup.py bdist_wheel
	ls -l dist

install: clean ## install the package to the active Python's site-packages
	python setup.py install
