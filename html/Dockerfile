FROM nginx:1.27-alpine

# Remove default nginx html files and pre-packaged configs
RUN rm -rf /usr/share/nginx/html/* /etc/nginx/conf.d/default.conf

# Copy custom nginx configuration template for auto-envsubst
COPY default.conf.template /etc/nginx/templates/default.conf

# Copy frontend static files
COPY . /usr/share/nginx/html

# Clean up template from public web directory
RUN rm -f /usr/share/nginx/html/default.conf

# Only substitute BACKEND_URL so Nginx built-in variables ($host, $uri, etc.) are untouched
ENV NGINX_ENVSUBST_FILTER="BACKEND_URL"

# Default to http://backend (standard for Azure Container Apps)
ENV BACKEND_URL="http://backend"

# Expose HTTP port
EXPOSE 80

# Run nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
