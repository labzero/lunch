FROM node:8.6.0-alpine

# Set a working directory
WORKDIR /usr/src/app

COPY ./build/package.json .
COPY ./build/yarn.lock .

# Install Node.js dependencies
RUN yarn install --production --no-progress

EXPOSE 3000

# Copy application files
COPY ./build .

# Run the container under "node" user by default
USER node

CMD [ "node", "server.js" ]
