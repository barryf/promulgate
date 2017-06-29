module Promulgate
  class Server < Sinatra::Application

    configure do
      use Rack::SSL if settings.production?
      set :server, :puma
    end

    get '/' do
      "WebSub hub: <a href=\"https://github.com/barryf/promulgate\">" +
        "https://github.com/barryf/promulgate</a>"
    end

    post '/' do
      begin
        case params['hub.mode']
        when 'publish'
          publish
          "Publish notification received."
        when 'subscribe'
          subscribe
          status 202
          "Subscription request received."
        when 'unsubscribe'
          unsubscribe
          status 202
          "Unsubscription request received."
        else
          raise "'hub.mode' value '#{params['hub.mode']}' is not valid."
        end
      rescue StandardError => e
        halt 400, e.message
      end
    end

    def publish
      urls = get_urls
      urls.each do |url|
        puts "Queueing publish of '#{url}'."
        Publish.perform_async(url)
      end
    end

    def subscribe
      url = get_url
      callback = get_callback
      lease_seconds = if params.key?('hub.lease_seconds') &&
                         params['hub.lease_seconds'].to_i > 0
        params['hub.lease_seconds']
      end
      secret = if params.key?('hub.secret') && !params['hub.secret'].empty?
        params['hub.secret']
      end
      puts "Queueing subscription of '#{url}' by '#{callback}'."
      Subscribe.perform_async(url, callback, secret, lease_seconds)
    end

    def unsubscribe
      url = get_url
      callback = get_callback
      puts "Queueing Unsubscription of '#{url}' by '#{callback}'."
      Unsubscribe.perform_async(url, callback)
    end

    def get_urls
      urls = if params.key?('hub.url')
               params['hub.url']
             elsif params.key?('hub.topic')
               params['hub.topic']
             end
      raise "'hub.url' (or 'hub.topic') must be specified." if urls.nil?
      urls = Array(urls)
      urls.each do |url|
        raise "'#{url}' is not a valid URL." unless Utils.valid_url?(url)
      end
      urls
    end

    def get_url
      get_urls[0]
    end

    def get_callback
      unless params.key?('hub.callback') &&
             Utils.valid_url?(params['hub.callback'])
        raise "'hub.callback' must be specified using a valid URL."
      end
      params['hub.callback']
    end

  end
end
