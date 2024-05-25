FROM python:3.11
ENV PYTHONUNBUFFERED 1
# PROJECT_MODE - choose dev or prod (set in .envrc)
ARG PROJECT_MODE
COPY ./djangoweather/requirements/${PROJECT_MODE}.txt /app/requirements.txt

RUN python -m venv /py && \
    /py/bin/pip install --upgrade pip && \
    /py/bin/pip install -r /app/requirements.txt

ADD ./djangoweather /app
WORKDIR /app

ENV VIRTUAL_ENV /env
RUN chmod -R +x /app/scripts
ENV PATH="/app/scripts:/py/bin:$PATH"

EXPOSE 8080
CMD ["sh", "/app/scripts/run_django.sh"]
