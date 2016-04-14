<img src="https://github.com/labzero/lunch/raw/master/src/components/Header/lunch.png" width="500" alt="Lunch">

An app for groups to decide on nearby lunch options. [Read the blog post about it!](https://labzero.com/people/blog/lunch-search-no-longer-to-sate-your-hunger)

## Setup

### Environment variables

Make a copy of `.env.sample` and name it `.env`.

`OAUTH_DOMAIN` is optional, but it allows you to restrict logins to a specific domain (such as your company's) 

#### Google project

For `GOOGLE_CLIENT_*` env variables:

- Create a Google Developer app in the [console](https://console.developers.google.com/).
- Enable the Google+ API as well as the Contacts API.
- Go to the Credentials section and create an OAuth client ID.
- For local development:
  - Enter `http://localhost:3000` and `http://localhost:3001` as authorized JavaScript origins
  - Enter `http://localhost:3000/login/callback` and `http://localhost:3001/login/callback` as authorized redirect URIs
- Add your deployment target(s) as additional origins/redirect URIs.
- Go back to the Credentials section and create an API key.
  - Choose "Browser key".
  - Optionally limit requests to certain referrers.

#### Database

Set up a PostgreSQL database and enter the credentials into `.env`. If you want to use another database dialect, change it in `database.js`.

### Commands

After setting up your environment:

```bash
npm install
npm install -g sequelize-cli
sequelize db:migrate
```

## Development server

### Running
```bash
npm start
```

## Production server

### Building
```bash
npm run build
```

### Environment variables
Copy your production `.env` file into the newly created `build` folder.

### Running
```bash
node build/server.js
```

### Deploying
You can modify `tools/deploy.js` as needed to work with your deployment strategy.

## More info

This project was created using [React Starter Kit](https://www.reactstarterkit.com/). Many technology choices originate from its [repository](https://github.com/kriasoft/react-starter-kit), but this project adds on [Sequelize](http://docs.sequelizejs.com/en/latest/), RESTful APIs instead of GraphQL, and [Redux](http://redux.js.org/).
