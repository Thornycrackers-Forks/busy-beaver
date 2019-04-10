help:
	@echo 'Makefile for managing application                                  '
	@echo '                                                                   '
	@echo 'Usage:                                                             '
	@echo ' make build            rebuild containers                          '
	@echo ' make up               start local dev environment                 '
	@echo ' make down             stop local dev environment                  '
	@echo ' make attach           attach to process for debugging purposes    '
	@echo ' make migration        create migration m="message"                '
	@echo ' make migrate-up       run all migration                           '
	@echo ' make migrate-down     roll back last migration                    '
	@echo ' make test             run tests                                   '
	@echo ' make test-cov         run tests with coverage.py                  '
	@echo ' make test-covhtml     run tests and load html coverage report     '
	@echo ' make test-skipvcr     run non-vcr tests                           '
	@echo ' make lint             run flake8 linter                           '
	@echo '                                                                   '
	@echo ' make debug            attach to app container for debugging       '
	@echo ' make log              attach to logs                              '
	@echo ' make enter            log into into app container -- bash-shell   '
	@echo ' make shell-dev        open ipython shell with application context '
	@echo ' make ngrok            start ngrok to forward port                 '
	@echo '                                                                   '
	@echo ' make prod-build       build production images                     '
	@echo ' make prod-up          start prod environment                      '
	@echo ' make prod-down        stop prod environment                       '
	@echo ' make prod-pull-imge   pull latest deployment image                '
	@echo ' make prod-deploy      redeploy application                        '
	@echo '                                                                   '

build:
	docker-compose -p busy_beaver build

up:
	docker-compose -p busy_beaver up -d

clean:
	docker-compose -p busy_beaver down

attach:
	docker attach `docker-compose -p busy_beaver ps -q app`

migration: ## Create migrations
	docker-compose -p busy_beaver exec app flask db migrate -m "$(m)"

migrate-up: ## Run migrations
	docker-compose -p busy_beaver exec app flask db upgrade

migrate-down: ## Rollback migrations
	docker-compose -p busy_beaver exec app flask db downgrade

test:
	docker-compose -p busy_beaver exec app pytest $(args)

test-cov:
	docker-compose -p busy_beaver exec app pytest --cov ./

test-covhtml:
	docker-compose -p busy_beaver exec app pytest --cov --cov-report html && open ./htmlcov/index.html

test-pdb:
	docker-compose -p busy_beaver exec app pytest --pdb -s

test-skipvcr:
	docker-compose -p busy_beaver exec app pytest -m 'not vcr'

lint:
	docker-compose -p busy_beaver exec app flake8
	docker-compose -p busy_beaver exec app black .

log:
	docker logs `docker-compose -p busy_beaver ps -q app`

debug:
	docker attach `docker-compose -p busy_beaver ps -q app`

enter:
	docker-compose -p busy_beaver exec app bash

shell-db:
	docker-compose -p busy_beaver exec db psql -w --username "bbdev_user" --dbname "busy-beaver"

shell-dev:
	docker-compose -p busy_beaver exec app ipython -i scripts/dev/shell.py

dev-shell: shell-dev

ngrok:
	ngrok http 5000

prod-build-image:
	docker build -f docker/prod/Dockerfile --tag alysivji/busy-beaver .

prod-build:
	docker-compose -p busy_beaver -f docker-compose.prod.yml build

prod-migrate-up:
	docker-compose -p busy_beaver -f docker-compose.prod.yml exec app flask db upgrade

prod-up:
	docker-compose -p busy_beaver -f docker-compose.prod.yml up -d
	make prod-migrate-up

prod-down:
	docker-compose -p busy_beaver -f docker-compose.prod.yml down

prod-pull-image:
	docker pull alysivji/busy-beaver:latest

prod-deploy: prod-pull-image
	make prod-down
	make prod-up
