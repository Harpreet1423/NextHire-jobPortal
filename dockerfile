# ---- Build Stage ----
FROM node:22-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build --verbose

# ---- Serve Stage ----
FROM nginx:alpine

# Copy custom Nginx config (your line here 👇)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the built React app to Nginx's web root
COPY --from=build /app/dist /usr/share/nginx/html

# Expose port 80 (standard for HTTP)
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
