.PHONY: clean clean-test clean-pyc  docs help download-api-doc
.DEFAULT_GOAL := help

define BROWSER_PYSCRIPT
import os, webbrowser, sys

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

help:
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

clean: clean-build clean-pyc clean-test ## 清除所有build, test等等的遗留

clean-build: ## 清除build遗留
	rm -fr build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -f {} +
	find . -name '*.db' -exec rm -f {} +

clean-pyc: ## 清除.pyc .pyo等等
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

clean-test: ## 清除测试遗留
	rm -fr .tox/
	rm -f .coverage
	rm -fr htmlcov/
	rm -fr .pytest_cache

lint: ## flake8检测代码风格
	flake8 datacenter tests

test: ## 快速测试代码
	pytest tests


coverage: ## 生成代码覆盖报告
	coverage run --source datacenter -m pytest tests
	coverage report -m
	coverage html
	$(BROWSER) htmlcov/index.html

download-api-doc: ##从YAPI下载最新API文档
	 curl --cookie-jar cookies.txt -H "Content-Type: application/json" --data '{"email":"$(YAPI_USER)","password":"$(YAPI_PASSWORD)"}' -X POST  http://yapi.xarc/api/user/login
	 curl -b cookies.txt -o docs/api.html http://yapi.xarc/api/plugin/export\?type\=html\&pid\=200\&status\=all\&isWiki\=true
	 rm -f cookies.txt

docs: ## 生成 Sphinx HTML 文档, 包括 API 文档
	rm -f docs/datacenter.rst
	mv .env .env.bk
	cp .env.example .env
	sphinx-apidoc -o docs/ datacenter
# 	sed -e '1,2s/datacenter/DataCenter代码注释文档/g'  docs/modules.rst > docs/modules.rst.temp
# 	mv docs/modules.rst.temp docs/modules.rst
#   pandoc --from=markdown --to=rst --output=docs/api.rst docs/api.md
	$(MAKE) -C docs clean
	$(MAKE) -C docs html
	mv .env.bk .env

watchdocs: docs ## 查看文档
	$(BROWSER) docs/build/html/index.html

servedocs: docs ## 编译文档并查看变更
	watchmedo shell-command -p '*.rst' -c '$(MAKE) -C docs html' -R -D .

publishdocs: download-api-doc docs ## 内网发布文档
	scp -r docs/build/html master:/home/devops/datacenter-service-doc
	ssh master 'sudo rm -rf /data/documents/datacenter-service-doc'
	ssh master 'sudo mv /home/devops/datacenter-service-doc /data/documents/datacenter-service-doc'


write-dep: ## 依赖包写到文件（先激活venv）
	 echo " -i https://mirrors.aliyun.com/pypi/simple/" > requirements.txt
	 pip3 freeze >> requirements.txt

init-venv: ## 初始化虚拟环境
	 rm -rf .venv
	 python3 -m venv  .venv

active-venv: ## 激活虚拟环境
	 source .venv/bin/active

run: ## 运行
	 python run_manage.py run

update-db: ## 更新数据库表
	 python run_manage.py db migrate
	 python run_manage.py db upgrade



check-out-dev-env: ## 切换为开发环境dotenv
	 cp env/dev.env  ./.env

check-out-pro-env: ## 切换为生产环境dotenv
	 cp env/pro.env  ./.env


k8s-dev-deploy: ## K8S-Deployment
	 kubectl apply -f deploy/local-k8s-deploy.yaml -n batch-register

k8s-dev-service: ## K8S-Service
	 kubectl apply -f deploy/local-k8s-service.yaml -n dbatch-register



