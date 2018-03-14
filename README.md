<img src="https://github.com/labzero/lunch/raw/master/src/components/Header/lunch.png" width="500" alt="Lunch">

An app for groups to decide on nearby lunch options. [Check out a live version](https://lunch.pink), or [read the blog post about it!](https://labzero.com/people/blog/lunch-search-no-longer-to-sate-your-hunger)

## Setup

### `/etc/hosts`

Add this line to `/etc/hosts`:

```
127.0.0.1 local.lunch.pink
```

If you will be testing subdomains, you should add an additional line for each subdomain, e.g.:

```
127.0.0.1 labzero.local.lunch.pink
127.0.0.1 someotherteam.local.lunch.pink
```

### Environment variables

Make two copies of `.env.sample`, named `.env` and `.env.prod`.

#### Google project

For `GOOGLE_CLIENT_*` env variables:

* Create a Google Developer app in the [console](https://console.developers.google.com/).
* Enable the Google+ API, Contacts API, Google Maps JavaScript API, Google Places API Web Service, and Google Maps Geocoding API.
* Go to the Credentials section and create an OAuth client ID.
* For local development:
  * Enter `http://local.lunch.pink:3000` as an authorized JavaScript origin
  * Enter `http://local.lunch.pink:3000/login/google/callback` as an authorized redirect URI
* Add your deployment target(s) as additional origins/redirect URIs.
* Go back to the Credentials section and create an API key.
  * Choose "Browser key".
  * Optionally limit requests to certain referrers.

#### Database

Set up a PostgreSQL database and enter the credentials into `.env`. If you want to use another database dialect, change it in `database.js`.

To seed your database with a Superuser, fill out the `SUPERUSER_*` env variables accordingly, then run

```bash
npx sequelize db:seed:all
```

After setting up and starting the app, you will be able to log in with this user and create a team. If you did not supply a SUPERUSER_PASSWORD, you will need to log in via OAuth, using the email address you supplied for SUPERUSER_EMAIL.

### Commands

After setting up your environment:

First, [install Yarn.](https://yarnpkg.com/en/docs/install) Then:

```bash
yarn
npx sequelize db:migrate
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

### Running

```bash
node build/server.js
```

### Deploying

You can modify `tools/deploy.js` as needed to work with your deployment strategy.

## Testing

### Unit tests

```bash
npm test
```

#### Testing with coverage

```bash
npm run coverage
```

### Integration tests

Make sure your `.env` file is filled out. Set up a separate test database using the same user as your development environment. Enter the following into `.env.test`:

```bash
DB_NAME=your_test_db_name
```

Then run:

```bash
npm run integration
```

### Linting

```bash
npm run lint
```

## More info

This project was created using [React Starter Kit](https://www.reactstarterkit.com/). Many technology choices originate from its [repository](https://github.com/kriasoft/react-starter-kit), but this project adds on [Sequelize](http://docs.sequelizejs.com/en/latest/), RESTful APIs instead of GraphQL, and [Redux](http://redux.js.org/).
