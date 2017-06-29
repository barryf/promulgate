$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

env = (ENV['RACK_ENV'] || 'development').to_sym

require "bundler/setup"
Bundler.require(:default, env)

Dotenv.load unless env == :production

$stdout.sync = true

require 'promulgate'
