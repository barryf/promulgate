web: rackup -s puma -p $PORT
worker: bundle exec sidekiq -c 5 -r ./worker.rb

# heroku config:set REDIS_PROVIDER=REDIS_URL