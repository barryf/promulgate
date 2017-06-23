module Promulgate
  module Publish
    module_function
    #include Sidekiq::Worker

    def perform(topic_url)
      response = HTTParty.get(topic_url)
      unless response.code == 200
        puts "Topic at '#{topic_url}' returned status #{response.code}."
        return
      end
      RedisHelpers.set_topic(topic_url, response.headers['Content-Type'],
        response.body)

      subscriptions = RedisHelpers.find_subscriptions(topic_url)
      subscriptions.each do |subscriber_url|
        subscriber = RedisHelpers.get_subscriber(subscriber_url)
        unless subscriber.nil?
          puts "Queueing notification of subscriber '#{subscriber_url}' " +
            "for topic '#{topic_url}'."
          Notify.perform(subscriber_url, topic_url)
        else
          RedisHelpers.unsubscribe(topic_url, subscriber_url)
          puts "Subscriber '#{subscriber_url}' was not found so has been " +
            "unsubscribed from topic '#{topic_url}'."
        end
      end
    end

  end
end