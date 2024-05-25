FROM nginxinc/nginx-unprivileged:alpine3.18-perl

COPY ./default.conf.tpl /etc/nginx/default.conf.tpl
COPY ./run_nginx.sh /run_nginx.sh

USER root

RUN touch /etc/nginx/conf.d/default.conf && \
    chown nginx:nginx /etc/nginx/conf.d/default.conf && \
    chmod +x /run_nginx.sh

USER nginx

CMD ["/run_nginx.sh"]
