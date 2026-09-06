FROM nginx:1.27-alpine

# Install gettext for envsubst utility
RUN apk add --no-cache gettext

# Remove default nginx html files
RUN rm -rf /usr/share/nginx/html/*

# Copy nginx config template (${BACKEND_URL} will be substituted at runtime)
COPY nginx.conf.template /etc/nginx/conf.d/default.conf.template

# Copy frontend static files
COPY . /usr/share/nginx/html

# Clean up build artefacts from the public web directory
RUN rm -f /usr/share/nginx/html/nginx.conf.template

# Expose HTTP port
EXPOSE 80

# At startup: substitute env vars into the nginx template, then start nginx
CMD ["/bin/sh", "-c", \
     "envsubst '${BACKEND_URL}' < /etc/nginx/conf.d/default.conf.template \
      > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
