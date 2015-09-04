# FHLB Member Portal

# Local Development

We use [Foreman](https://github.com/ddollar/foreman) to manage launching the various applications defined in this repository. Local environment configuration is supplied via [dotenv](https://github.com/bkeepers/dotenv). You will want to start with a copy of the example environment defined in `.env.example`.

We use [Vagrant](https://www.vagrantup.com/) to manage a VM that provides all the needed services for the applications. You will need to make sure your Vagrant VM is running before you try and launch the application. Note that the VM requires 2 GB of RAM and a dedicated CPU.

## Prerequisites

* [RVM](http://rvm.io/) installed.
* Ruby 2.1.2 (or whatever is currently called out in `.ruby-version`) installed via RVM. If you `cd` into the working copy and don't have the right Ruby installed, RVM will suggest that you install it. Complete the installation before moving forward. You will want to close the shell session and start a new one after installing Ruby.
* [VirtualBox](https://www.virtualbox.org/) installed.
* [Vagrant](https://www.vagrantup.com/) installed.
* [Oracle Instant Client](http://www.oracle.com/technetwork/database/features/instant-client/index-097480.html) 11g installed, along with the accompanying SDK headers (separate download). See below for details.
* [Oracle DB Express 11g Release 2](http://www.oracle.com/technetwork/database/database-technologies/express-edition/downloads/index-083047.html) for Linux (RPM) downloaded. You just need the file, installation will be handled by Vagrant.
* [Redis](http://redis.io/) installed. `brew install redis` if you are on a Mac with Homebrew.
* [wkhtmltopdf](http://wkhtmltopdf.org/) with patched QT installed.
* [ImageMagick](http://www.imagemagick.org/) installed.  `brew install imagemagick` if you are on a Mac with Homebrew.
* [GhostScript](http://www.ghostscript.com/) installed.  `brew install gs` if you are on a Mac with Homebrew.
* ACE Agent SDK v8.1 (obtained from the Bank) installed.
* [Chrome Web Driver](https://sites.google.com/a/chromium.org/chromedriver/downloads) (for local integration tests, can skip if you plan to test via another mechanism, like SauceLabs)

### Oracle Instant Client

Oracle Instant Client is needed for the Oracle DB adapter used by ActiveRecord. To install, follow these steps (POSIX systems):

1. [Download](http://www.oracle.com/technetwork/database/features/instant-client/index-097480.html) the Oracle Instant Client (11g release 2, currently 11.2.0.4.0) for your platform, as well as the SDK package and SQL*Plus package for your platform (found on the same page).
2. Extract all three zip files into the same directory.
3. Place that directory somewhere in your system in a path that **contains no spaces**. If there are any spaces anywhere in the path the gem install will not work. You will get an obtuse error saying that `DYLD_LIBRARY_PATH` needs to be defined.
4. `cd` into the Oracle Instant Client directory in your shell and run `ln -s libclntsh.dylib.11.1 libclntsh.dylib` (OS X) or `ln -s libclntsh.so.11.1 libclntsh.so` (Linux), which creates a needed symlink.
5. Open `~/.bash_profile` (or `~/.bashrc` depending on your OS/shell) and add the following lines (replacing `YOUR_PATH` with the absolute path to the Oracle Instant Client directory):

   OS X:
   ```
   export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:YOUR_PATH
   export NLS_LANG="AMERICAN_AMERICA.UTF8"
   export PATH=$PATH:YOUR_PATH
   ```

   Linux:
   ```
   export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:YOUR_PATH
   export NLS_LANG="AMERICAN_AMERICA.UTF8"
   export PATH=$PATH:YOUR_PATH
   ```

6. `source ~/.bashrc` to load the new environment variables into your current shell.

### ACE Agent SDK

You must obtain the binaries for the ACE Agent SDK from the Bank. See the project lead with questions.

1. Download the SDK.
2. Extract the ZIP file to a known, permananet location.
3. Open `~/.bash_profile` (or `~/.bashrc` depending on your OS/shell) and add the following lines (replacing `YOUR_PATH` with the absolute path to the ACE Agent SDK directory and `YOUR_ARCH` with the directory or directories needed to get to the library for your machine, eg. `64bit/lnx/release` for 64bit Linux ):

   ```
   export ACE_SDK_INC=YOUR_PATH/inc
   export ACE_SDK_LIB=YOUR_PATH/lib/YOUR_ARCH
   ```


## Setup Instructions

Follow these steps to get up and running:

1. `bundle install`
2. `cp .env.example .env`
3. Edit `.env` and set `SECRET_KEY_BASE` to some long cryptographic string. If you change this, old cookies will become unusable.
4. Edit `.env` and set `MAPI_SECRET_TOKEN` to some long cryptographic string. If you change this, old cookies will become unusable.
5. `export ORACLE_INSTALLER=PATH_TO_INSTALLER` with `PATH_TO_INSTALLER` replaced with the path to the directory containing the Oracle DB 11g RPM.
6. `vagrant up` -- This will take 15-30 minutes, and will generate a `.deb` version of the 11g RPM in the same directory was the RPM. Save this file if you want to be able to rebuild your Vagrant system more quickly.
7. If you want to be able to work offline, [follow these steps](http://chaos667.tumblr.com/post/20006357466/ora-21561-and-oracle-instant-client-11-2) to add a needed host entry to `/etc/hosts`.
8. `rake db:setup` -- You may be asked for the SYSTEM password twice, which is `password`.
9. `rake db:setup RAILS_ENV=test` -- You may be asked for the SYSTEM password twice, which is `password`.
10. `foreman start`
11. Navigate over to [http://localhost:3000](http://localhost:3000).
12. The login details are 'local' (username) and 'development' (password).

# .env Details

This is a summary of the options supported in our .env files:

* `PORT`: The base port for foreman.
* `SECRET_KEY_BASE`: The secret key used to sign cookies for this environment. You can get a value from [Fourmilab](https://www.fourmilab.ch/cgi-bin/Hotbits?nbytes=128&fmt=password&npass=1&lpass=30&pwtype=2).
* `DATABASE_USERNAME`: The username to use to connect to the DB (overrides the values found in database.yml).
* `DATABASE_PASSWORD`: The password to use to connect to the DB (overrides the values found in database.yml).
* `SAUCE_USERNAME`: The username of the SauceLabs user, used when cucumber tests are run via SauceLabs.
* `SAUCE_ACCESS_KEY`: The access key associated with the SauceLabs user (`SAUCE_USERNAME`). Only used when running cucumber tests via SauceLabs.
* `MAPI_SECRET_TOKEN`: The shared secret between MAPI and Rails.
* `MAPI_COF_ACCOUNT`: FHLBSF account for getting COF data.
* `MAPI_FHLBSF_ACCOUNT`: FHLBSF account for getting Calypso data.
* `MAPI_WEB_AO_ACCOUNT`: WEB-AO
* `SOAP_SECRET_KEY`: FHLBSF password for Market Data Service.
* `MAPI_MDS_ENDPOINT`: FHLBSF endpoint for Market Data Service.
* `MAPI_CALENDAR_ENDPOINT`: FHLBSF endpoint for Market Data Service.
* `MAPI_CAPITALSTOCK_ENDPOINT`: FHLBSF endpoint for Capital Stock Service.
* `MAPI_TRADE_ENDPOINT`: FHLBSF endpoint for Trade Service.
* `LDAP_HOST`: Hostname of the LDAP server.
* `LDAP_PORT`: Port of the LDAP server.
* `LDAP_ADMIN_USERNAME`: Username of the LDAP service account.
* `LDAP_ADMIN_PASSWORD`: Password for the LDAP service account.
* `LDAP_EXTRANET_SSL_MODE`: The SSL mode to use for Extranet LDAP. Options are `start_tls` and `simple_tls`.
* `LDAP_SSL_MODE`: The SSL mode to use for Intranet LDAP. Options are `start_tls` and `simple_tls`.
* `LDAP_CA_BUNDLE_PATH`: The optional CA bundle path for LDAP over SSL.
* `TIMEZONE`: The time zone to use when we create new Time.zone objects. Defaults to "Pacific Time (US & Canada)" and should not deviate from this.
* `RESQUE_WORKER_COUNT`: How many Resque workers to start
* `REDIS_URL`: The URL of the Redis server to use.
* `RESQUE_REDIS_URL`: Thr URL of the Redis server to use for Resque. Autogenerated from REDIS_URL if not supplied.
* `S3_BUCKET_NAME`: Name of the S3 bucket. Used in config/environment files to point to the proper S3 bucket.
* `S3_PATH_PREFIX`: Prefix for S3 asset paths. Used in config/environment files to point to the proper S3 bucket.
* `S3_REGION`: AWS region. Used in config/environment files to point to the proper S3 bucket.
* `SECURID_TEST_MODE`: What test mode, if any, to use for the SecurID service. In test mode the RSA ACE server is never contacted.
* `SECURID_USER_PREFIX`: The value to prepend to a username before connecting to the RSA ACE server.
* `DEBUG`: Enables the ByeBug remote debugging server when set to `true`.
* `BYEBUG_PORT`: What port to launch the ByeBug remote debugging server on. In its absence, it finds a free port and uses that.
* `SMTP_HOSTNAME`: The hostname of the SMTP server.
* `SMTP_PORT`: The port of the SMTP server.
* `SMTP_DOMAIN`: The domain to use as part of the HELO to the SMTP server.
* `SMTP_USERNAME`: The username used to authenticate with the STMP server.
* `SMTP_PASSWORD`: The password used to authenticate with the STMP server.
* `SMTP_AUTHENTICATION_MODE`: The SMTP authentication mode to use (`plain`, `login` or `cram_md5`).
* `SMTP_SSL_VERIFICATION`: The SMTP SSL verification mode to use. Defaults to 'verify'.



## Running the Tests

To run the unit tests and security analysis, use `rake ci:build`. If you want to run just the Rails unit test suite, use `rake spec`. To run the MAPI unit test suite, use `rake spec:api`. For integration tests (cucumber), run `cucumber`. The cucumber tests are not run as part of `rake ci:build`.

All commits should pass `rake ci:build && cucumber` before being pushed.

