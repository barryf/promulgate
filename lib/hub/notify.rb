module Promulgate
  module Notify
    module_function
    #include Sidekiq::Worker

    def perform(subscriber_url, topic_url)
      topic = RedisHelpers.get_topic(topic_url)
      if topic.nil?
        puts "Topic '#{topic_url}' was not found."
        return
      end

      headers = {
        'Content-Type' => topic['content_type'],
        'Link' => "<#{ENV.fetch('ROOT_URL')}>; rel=\"hub\", " +
                  "<#{topic_url}>; rel=\"self\""
      }

      subscriber = RedisHelpers.get_subscriber(subscriber_url)
      unless subscriber.nil? || !subscriber.key?('secret') ||
             subscriber['secret'].nil?
        signature = Utils.hmac(subscriber['secret'], topic['body'])
        headers['X-Hub-Signature'] = "sha256=#{signature}"
      end

      response = HTTParty.post(subscriber_url, body: topic['body'],
        headers: headers)
      puts "Notified subscriber '#{subscriber_url}' for topic " +
        "'#{topic_url}' and received status #{response.code}."
    end

  end
end