# FHLB Member Portal

# Local Development

We use [Foreman](https://github.com/ddollar/foreman) to manage all the various local services that the project needs. Local environment configuration is supplied via [dotenv](https://github.com/bkeepers/dotenv). You will want to start with a copy of the example environment defined in `.env.example`.

Follow these steps to get up and running (they assume you have [RVM](http://rvm.io/) installed):

1. `bundle install`
2. `cp .env.example .env`
3. Edit `.env` and set `SECRET_KEY_BASE` to some long cryptographic string. If you change this, old cookies will become unusable.
4. `foreman start`
5. Navigate over to [http://localhost:3000](http://localhost:3000)

# .env Details

This is a summary of the options supported in our .env files:

* `PORT`: The base port for foreman.
* `SECRET_KEY_BASE`: The secret key used to sign cookies for this environment. You can get a value from [Fourmilab](https://www.fourmilab.ch/cgi-bin/Hotbits?nbytes=128&fmt=password&npass=1&lpass=30&pwtype=2).
* `DATABASE_URL`: Optional URL that overrides `config/database.yml` configuration for the current environment.