FROM node:5.9.1

# Create app directory
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

# Bundle app source
ADD build /usr/src/app/

RUN npm install --production

EXPOSE 3000

CMD [ "npm", "start" ]