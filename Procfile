web: rackup -s puma -p $PORT
worker: bundle exec sidekiq -c 5 -r ./worker.rb
