$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

env = (ENV['RACK_ENV'] || 'development').to_sym

require "bundler/setup"
Bundler.require(:default, env)

Dotenv.load unless env == :production

# optionally use sentry in production
if env == :production && ENV.key?('SENTRY_DSN')
  Raven.configure do |config|
    config.dsn = ENV['SENTRY_DSN']
    config.processors -= [Raven::Processor::PostData]
  end
  use Raven::Rack
end

$stdout.sync = true

require 'promulgate'
require 'sidekiq/web'

run Rack::URLMap.new(
  '/' => Promulgate::Server,
  '/sidekiq' => Sidekiq::Web
)
