module Promulgate
  class Unsubscribe
    include Sidekiq::Worker

    def perform(url, callback_url)
      challenge = SecureRandom.hex(100)
      query = {
        'hub.mode' => 'unsubscribe',
        'hub.topic' => url,
        'hub.challenge' => challenge
      }
      response = HTTParty.get(callback_url, query: query)
      case response.code
      when 200
        if response.body == challenge
          RedisHelpers.unsubscribe(url, callback_url)
          puts "Subscription for '#{url}' was removed."
        else
          puts "Unsubscription callback challenge did not match."
        end
      when 404
        puts "Unsubscription request not found by subscriber."
      else
        puts "Unsubscription callback failed."
      end
    end

  end
end