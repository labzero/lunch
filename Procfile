web:  bundle exec rails server -p $PORT
api:  cd api && bundle exec rackup -p $PORT
ldap: cd ldap && ./run-server --port $PORT
redis: redis-server
resque: QUEUE=* rake environment resque:work