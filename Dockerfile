FROM nginx

RUN rm -rf /usr/share/nginx/html/*
COPY public/* /usr/share/nginx/html/

CMD ["nginx", "-g", "'daemon off;'"]