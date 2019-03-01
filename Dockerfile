FROM node:9.11

# Set a working directory
WORKDIR /usr/src/app

COPY ./build/package.json .
COPY ./build/yarn.lock .

# Install Node.js dependencies
RUN yarn install --production --no-progress

EXPOSE 3000

# Copy application files
COPY ./build .

CMD [ "node", "server.js" ]
