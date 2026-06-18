FROM nginx:alpine
COPY infrastructure/nginx/nginx.conf /etc/nginx/conf.d/default.conf
COPY infrastructure/nginx/empty.png /usr/share/nginx/html/empty.png
COPY frontend /usr/share/nginx/html
RUN chmod -R a+rX /usr/share/nginx/html
