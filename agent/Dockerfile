FROM node:22-alpine

WORKDIR /workspace/agent

# Install dependencies first (cached layer)
COPY package.json package-lock.json ./
RUN npm ci --production

# Copy agent source
COPY . .

CMD ["node", "index.js"]
