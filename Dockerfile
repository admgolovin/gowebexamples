FROM nginx

RUN rm -rf /usr/share/nginx/html/*
COPY public/* /usr/share/nginx/html/

CMD ["exec nginx -g 'daemon off;'"]