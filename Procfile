web:  bundle exec rails server -p $PORT
api:  bundle exec rackup -p $PORT api/config.ru
ldap: cd ldap && ./run-server --port $PORT --fresh
redis: redis-server
resque: TERM_CHILD=1 QUEUE=* resque-pool -i