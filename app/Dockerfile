FROM nginx:latest

# Remove default Nginx static files
RUN rm -rf /usr/share/nginx/html/*

# Copy your entire website into the container
COPY index.html /usr/share/nginx/html/

# Expose port 80 for web access
EXPOSE 80