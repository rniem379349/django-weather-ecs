.PHONY: test requirements
RUN := docker compose run --rm web

requirements:
	$(RUN) pip-compile --generate-hashes -o requirements/prod.txt pyproject.toml
	$(RUN) pip-compile --generate-hashes -o requirements/dev.txt --extra dev pyproject.toml

test:
	$(RUN) pytest

collectstatic:
	$(RUN) python manage.py collectstatic

migrations:
	$(RUN) python manage.py makemigrations
	$(RUN) python manage.py migrate

rebuild-images:
	docker buildx build -t djangoweather-django:latest --build-arg PROJECT_MODE=dev .
	docker buildx build -t djangoweather-proxy:latest docker/nginx/
	docker buildx build -t djangoweather-prometheus:latest docker/prometheus/
	docker buildx build -t djangoweather-grafana:latest docker/grafana/

restart-minikube:
	minikube stop
	minikube delete
	minikube start

load-images-minikube:
	minikube image load djangoweather-django:latest
	minikube image load djangoweather-proxy:latest
	minikube image load djangoweather-prometheus:latest
	minikube image load djangoweather-grafana:latest

apply-konfig:
	kubectl apply -k deploy/

helm-install-prometheus:
	helm install prometheus prometheus-community/kube-prometheus-stack --version "57.0.1"
