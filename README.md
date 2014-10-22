# FHLB Member Portal

# Local Development

We use [Foreman](https://github.com/ddollar/foreman) to manage all the various local services that the project needs. Local environment configuration is supplied via [dotenv](https://github.com/bkeepers/dotenv). You will want to start with a copy of the example environment defined in `.env.example`.

Follow these steps to get up and running (they assume you have [RVM](http://rvm.io/) installed):

1. `bundle install`
2. `cp .evn.example .env`
3. `foreman start`
4. Navigate over to [http://localhost:3000](http://localhost:3000)
