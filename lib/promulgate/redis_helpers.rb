module Promulgate
  module RedisHelpers
    module_function

    REDIS = Redis.new(url: ENV.fetch('REDIS_URL'))
    TOPIC_EXPIRES = 3_600 # 1 hour

    def get_topic(topic_url)
      json = REDIS.get(topic_url)
      return if json.nil?
      JSON.parse(json)
    end

    def set_topic(url, content_type, body)
      json = {
        'content_type' => content_type,
        'body' => body.encode('utf-8')
      }.to_json
      REDIS.set(url, json)
      REDIS.expire(url, TOPIC_EXPIRES)
    end

    def get_subscriber(subscriber_url)
      json = REDIS.get(subscriber_url)
      return if json.nil?
      obj = JSON.parse(json)
      # refresh expiry
      REDIS.expire(subscriber_url, obj['lease_seconds'])
      obj
    end

    def set_subscriber(subscriber_url, secret, lease_seconds)
      obj = { 'lease_seconds' => lease_seconds }
      obj['secret'] = secret unless secret.nil?
      json = obj.to_json
      REDIS.set(subscriber_url, json)
      REDIS.expire(subscriber_url, lease_seconds)
    end

    def subscribe(topic_url, subscriber_url)
      REDIS.sadd("SUB__#{topic_url}", subscriber_url)
    end

    def unsubscribe(topic_url, subscriber_url)
      REDIS.srem("SUB__#{topic_url}", subscriber_url)
    end

    def find_subscriptions(topic_url)
      REDIS.smembers("SUB__#{topic_url}")
    end

  end
end