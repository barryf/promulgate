module Promulgate
  module Utils
    module_function

    def valid_url?(url)
      begin
        uri = URI.parse(url)
        uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      rescue URI::InvalidURIError
      end
    end

    def hmac(secret, body)
      digest = OpenSSL::Digest.new('sha256')
      OpenSSL::HMAC.hexdigest(digest, secret, body)
    end

  end
end
