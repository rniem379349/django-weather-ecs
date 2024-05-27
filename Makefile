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
