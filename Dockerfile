# Use the official Node.js LTS image as the base image
FROM node:20-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json/yarn.lock files to the working directory
COPY package*.json ./

# Install dependencies
RUN npm install --frozen-lockfile

# Copy the rest of the application code to the working directory
COPY . .

# Install OpenSSL
RUN apk add --no-cache openssl

ARG DATABASE_URL
ENV DATABASE_URL=$DATABASE_URL

# Build the Next.js application
RUN npm run build

# Install only production dependencies
RUN npm prune --production

# Use a lightweight image for the production stage
FROM node:20-alpine AS runner

# Set the working directory inside the container
WORKDIR /app

# Copy production dependencies from the builder stage
COPY --from=builder /app/node_modules ./node_modules

# Copy the built application from the builder stage
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package*.json ./

# Expose the port on which the application will run
EXPOSE 3000

# Start the Next.js application
CMD ["npm", "start"]
