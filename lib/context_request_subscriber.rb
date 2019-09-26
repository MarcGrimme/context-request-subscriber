# frozen_string_literal: true

require 'json'
require 'active_support'
require 'active_support/inflector'
require 'context_request_subscriber/handler'
require 'context_request_subscriber/processor'
require 'context_request_subscriber/error_handler'
require 'context_request_subscriber/rabbitmq_subscriber'

# Base module for the context request subscriber.
# This class provides all the configurables to the logic for the
# subscriber and handler logic of the request context logic.
module ContextRequestSubscriber
  include ActiveSupport::Configurable
  config_accessor(:logger, instance_accessor: false) do
    ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
  end
  config_accessor(:queue_name, instance_accessor: false) do
    'fos.context_request'
  end
  config_accessor(:exchange_name, instance_accessor: false) do
    'fos.context_request'
  end
  # queue_durable: if the queue is durable. Default: true
  config_accessor(:queue_durable, instance_accessor: false)

  # queue_auto_delete: if the queue gets autodeleted.
  config_accessor(:queue_auto_delete, instance_accessor: false)

  # queue_exclusive: default false.
  config_accessor(:queue_exclusive, instance_accessor: false)

  # Callable that is called instead of the default logic to return
  # a Bunny object for both the channel, the connection and the queue.
  config_accessor(:fetch_queue_callback, instance_accessor: false)

  # routing_key: the routing_key used. Default #.
  config_accessor(:routing_key, instance_accessor: false) { '#' }

  # Hash of small cased classname of callable object to be called in order
  # to handle the message. The type of the message indicates the handler class.
  # Defaults to JsonApiHandler for request and context types.
  config_accessor(:handlers, instance_accessor: false) do
    {
      context: ContextRequestSubscriber::Handler::JsonApiHandler::Context,
      request: ContextRequestSubscriber::Handler::JsonApiHandler::Request
    }
  end
  # Handler URL is the url to reach out for handling.
  config_accessor(:handler_url, instance_accessor: false)

  # Set of session parameters
  config_accessor(:session_params, instance_accessor: false) { {} }

  # url to connect to the RabbitMQ Server
  config_accessor(:url, instance_accessor: false)

  # heartbeat: heartbeat for the connection. Defaults to nil.
  config_accessor(:heartbeat, instance_accessor: false)

  # on_error: callable object that handles errors during processing the
  #       message.
  config_accessor(:on_error, instance_accessor: false) do
    ErrorHandler::LogErrorHandler
  end

  # Instruct the subscriber to keep the subscriber alive even if the
  # queue is empty.
  # Default: true
  config_accessor(:subscriber_keep_alive, instance_accessor: false) { false }

  config_accessor(:handler_params, instance_accessor: false) { {} }

  def self.run
    subscriber = RabbitMQSubscriber.new(**config)
    subscriber.run
  end
end
