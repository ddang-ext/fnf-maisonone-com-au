include .env

default: up

DRUPAL_VER ?= 9
PHP_VER ?= 8.1
COMPOSER_ROOT ?= /app
DRUPAL_ROOT ?= /app/web
DOCKER_APP ?= docker/app
DOCKER_WEB ?= docker/web

## help		:	Print commands help.
.PHONY: help
help : Makefile
	@sed -n 's/^##//p' $<

## up	:	Start up containers.
.PHONY: up
up:
	echo "Preparing Dockerfiles for $(PROJECT_NAME)..."
	rm -rf $(DOCKER_APP) && mkdir -p $(DOCKER_APP) && cd $(DOCKER_APP) && git clone git@gitlab.moet-hennessy.net:automation1/images/drupal-smile/php-fpm.git .
	rm -rf $(DOCKER_WEB) && mkdir -p $(DOCKER_WEB) && cd $(DOCKER_WEB) && git clone git@gitlab.moet-hennessy.net:automation1/images/drupal-smile/nginx.git .

	# echo "Add development tools setup on top of php-fpm Dockerfile..."
	# rsync -avzP docker/xdebug/ $(DOCKER_APP)/
	# cat $(DOCKER_APP)/Dockerfile.xdebug >> $(DOCKER_APP)/Dockerfile

	echo "Starting up containers for $(PROJECT_NAME)..."
	docker-compose pull
	docker-compose up -d --remove-orphans

## mutagen-up	:	Start up containers with mutagen to impove the file sharing for macOS users
.PHONY: mutagen-up
mutagen-up:
	echo "Preparing Dockerfiles for $(PROJECT_NAME)..."
	rm -rf $(DOCKER_APP) && mkdir -p $(DOCKER_APP) && cd $(DOCKER_APP) && git clone git@gitlab.moet-hennessy.net:automation1/images/drupal-smile/php-fpm.git .
	rm -rf $(DOCKER_WEB) && mkdir -p $(DOCKER_WEB) && cd $(DOCKER_WEB) && git clone git@gitlab.moet-hennessy.net:automation1/images/drupal-smile/nginx.git .

	echo "Starting up containers for $(PROJECT_NAME)..."
	mutagen-compose up

## down	:	Stop containers.
.PHONY: down
down:
	echo "Dropping containers for $(PROJECT_NAME)..."
	docker-compose down

## start	:	Start containers without updating.
.PHONY: start
start:
	echo "Starting containers for $(PROJECT_NAME) from where you left off..."
	docker-compose start

## stop	:	Stop containers.
.PHONY: stop
stop:
	echo "Stopping containers for $(PROJECT_NAME)..."
	docker-compose stop

## prune	:	Remove containers and their volumes.
##		You can optionally pass an argument with the service name to prune single container
##		prune mariadb	: Prune `mariadb` container and remove its volumes.
##		prune mariadb solr	: Prune `mariadb` and `solr` containers and remove their volumes.
.PHONY: prune
prune:
	echo "Removing containers for $(PROJECT_NAME)..."
	docker-compose down -v $(filter-out $@,$(MAKECMDGOALS))

## ps	:	List running containers.
.PHONY: ps
ps:
	docker ps --filter name='$(PROJECT_NAME)*'

## sh-web	:	Access `nginx` container via shell.
.PHONY: sh-web
sh-web:
	docker exec -ti -e COLUMNS=$(shell tput cols) -e LINES=$(shell tput lines) $(shell docker ps --filter name='$(PROJECT_NAME)_web' --format "{{ .ID }}") sh

## sh-app	:	Access `php` container via shell.
.PHONY: sh-app
sh-app:
	docker exec -ti -e COLUMNS=$(shell tput cols) -e LINES=$(shell tput lines) $(shell docker ps --filter name='$(PROJECT_NAME)_app' --format "{{ .ID }}") sh

## solr-core	:	Create new Solr core via shell.
.PHONY: solr-core
solr-core:
	docker exec $(shell docker ps --filter name='$(PROJECT_NAME)_solr' --format "{{ .ID }}") /opt/solr/bin/solr create_core -c ${SOLR_CORE}

## composer	:	Executes `composer` command in a specified `COMPOSER_ROOT` directory.
##		To use "--flag" arguments include them in quotation marks.
##		For example: make composer "update drupal/core --with-dependencies"
.PHONY: composer
composer:
	docker exec --user 1000 $(shell docker ps --filter name='^/$(PROJECT_NAME)_app' --format "{{ .ID }}") composer --working-dir=$(COMPOSER_ROOT) $(filter-out $@,$(MAKECMDGOALS))

## ci	:	Executes `composer install` command in a specified `COMPOSER_ROOT` directory.
.PHONY: ci
ci:
	docker exec $(shell docker ps --filter name='^/$(PROJECT_NAME)_app' --format "{{ .ID }}") composer install --working-dir=$(COMPOSER_ROOT) $(filter-out $@,$(MAKECMDGOALS))

## drush	:	Executes `drush` command in a specified `DRUPAL_ROOT` directory.
##		To use "--flag" arguments include them in quotation marks.
##		For example: make drush "watchdog:show --type=cron"
.PHONY: drush
drush:
	docker exec -it $(shell docker ps --filter name='^/$(PROJECT_NAME)_app' --format "{{ .ID }}") /app/vendor/drush/drush/drush -r $(DRUPAL_ROOT) $(filter-out $@,$(MAKECMDGOALS))

## logs	:	View containers logs.
##		You can optinally pass an argument with the service name to limit logs
##		logs php	: View `php` container logs.
##		logs nginx php	: View `nginx` and `php` containers logs.
.PHONY: logs
logs:
	docker-compose logs -f $(filter-out $@,$(MAKECMDGOALS))
