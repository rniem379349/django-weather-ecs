http {
    upstream django {
        server web:8080;
    }
 
    server {
        listen 80;

        location / {
            proxy_set_header Host $host;
            proxy_pass              http://django;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

        location /static/ {
            autoindex on;
            alias /static/;
        }

        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;
    }
}
