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
  config[:session_params][:vhost] = ENV.fetch('RABBITMQ_VHOST', '/')
  config[:session_params][:heartbeat] =
    ENV.fetch('RABBITMQ_HEARTBEAT_SUBSCRIBER', :server)
  config[:session_params][:network_recovery_interval] = 4
  config[:session_params][:continuation_timeout] = 3000
  config[:session_params][:auth_mechanism] = 'PLAIN'
  config[:routing_key] = '#'
  config.logger.level = begin
                          Logger.const_get(ENV.fetch('LOG_LEVEL', '').upcase)
                        rescue StandardError
                          Logger::INFO
                        end
  config.handler_params = {
    site: ENV.fetch('HANDLER_URL', 'http://localhost'),
    handler_headers: {
      'Authorization' => "Token #{ENV['HANDLER_API_TOKEN']}"
    }
  }
end
