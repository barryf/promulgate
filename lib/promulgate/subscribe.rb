module Promulgate
  class Subscribe
    include Sidekiq::Worker

    DEFAULT_LEASE_SECONDS = 604_800 # 7 days

    def perform(topic_url, subscriber_url, secret, lease_seconds)
      lease_seconds ||= DEFAULT_LEASE_SECONDS

      challenge = SecureRandom.hex(100)
      query = {
        'hub.mode' => 'subscribe',
        'hub.topic' => topic_url,
        'hub.challenge' => challenge,
        'hub.lease_seconds' => lease_seconds
      }
      begin
        response = HTTParty.get(subscriber_url, query: query)
      rescue => e
        puts "Subscription failed when fetching '#{subscriber_url}' (#{e.message})."
        return
      end
      case response.code
      when 200
        if response.body == challenge
          RedisHelpers.set_subscriber(subscriber_url, secret, lease_seconds)
          RedisHelpers.subscribe(topic_url, subscriber_url)
          puts "Subscription for topic '#{topic_url}' was created."
        else
          puts "Subscription callback challenge did not match."
        end
      when 404
        puts "Subscription request not found by subscriber."
      else
        puts "Subscription callback failed."
      end
    end

  end
end