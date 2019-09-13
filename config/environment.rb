# frozen_string_literal: true

require 'context_request_subscriber'
ContextRequestSubscriber.logger =
  ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
$stdout.sync = true if %w[1 yes true].include? ENV.fetch('SYNC_STDOUT', 'true')

ContextRequestSubscriber.configure do |config|
  config[:url] = if ENV['RABBITMQ_URL'].nil?
                   "amqp://\
#{ENV.fetch('RABBITMQ_USERNAME', 'guest')}:\
#{ENV.fetch('RABBITMQ_PASSWORD', 'guest')}@\
#{ENV.fetch('RABBITMQ_NODE_IP_ADDRESS', '127.0.0.1')}:\
#{ENV.fetch('RABBITMQ_NODE_PORT', 5672)}\
#{ENV.fetch('RABBITMQ_VHOST', '/')}"
                 else
                   ENV['RABBITMQ_URL']
                 end

  config[:session_params] = {} unless config[:session_params]
  config[:session_params][:heartbeat] =
    ENV.fetch('RABBITMQ_HEARTBEAT_SUBSCRIBER', :server)
  config[:session_params][:network_recovery_interval] = 4
  config[:session_params][:continuation_timeout] = 3000
  config[:session_params][:auth_mechanism] = 'PLAIN'
  config[:routing_key] = '#'
end
