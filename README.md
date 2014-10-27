# FHLB Member Portal

# Local Development

We use [Foreman](https://github.com/ddollar/foreman) to manage all the various local services that the project needs. Local environment configuration is supplied via [dotenv](https://github.com/bkeepers/dotenv). You will want to start with a copy of the example environment defined in `.env.example`.

## Prerequisites

* [RVM](http://rvm.io/) installed.
* Ruby 2.1.2 (or whatever is currently called out in `.ruby-version`) installed via RVM. If you `cd` into the working copy and don't have the right Ruby installed, RVM will suggest that you install it. Complete the installation before moving forward. You will want to close the terminal session and start a new one after installing Ruby.

## Setup Instructions

Follow these steps to get up and running:

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