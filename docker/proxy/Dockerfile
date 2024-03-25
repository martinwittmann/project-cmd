FROM nginx

RUN apt-get update && apt-get install -y openssl wget git cron vim
RUN openssl dhparam -out /etc/nginx/dhparam.pem 4096

RUN sed -i "s/^.*include \/etc\/nginx\/conf.d\/.*/    include \/etc\/nginx\/sites-enabled\/*.conf;/" /etc/nginx/nginx.conf