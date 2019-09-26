# frozen_string_literal: true

module ContextRequestSubscriber
  # :nodoc:
  module Processor
    autoload :Base, 'context_request_subscriber/processor/base'
    autoload :Request, 'context_request_subscriber/processor/request'
    autoload :Context, 'context_request_subscriber/processor/context'

    # Class to execute the processing of the messages.
    # Base on the message_type a processor is instantiated and provides
    # processing.
    class Executor
      attr_accessor :handler_params

      def initialize(logger, **keys)
        @logger = logger
        @handler_params = keys[:handler_params] || {}
      end

      def run(_delivery_info, properties, payload)
        @logger.debug("#{properties[:type]} processing message.")
        @logger.debug("   payload: #{payload}")
        @logger.debug("   properties: #{properties}")
        payload = JSON.parse(payload)
        process(properties[:type], properties[:headers]&.dig('version'),
                payload)
      rescue JSON::ParserError
        @logger.error("Could not parse message payload \
with payload #{payload}. Ignoring.")
        nil
      end

      def process(name, version = nil, payload = {})
        processor = Processor.processor_class(name, version)
          &.new(@logger, handler_params: handler_params)
        if processor
          processor.call(payload)
        else
          @logger.error("Invalid processor type or \
processor type with name #{name} cannot be found")
        end
      end

      # Method can be overwriten to communicate with the MQ and ack the message
      # if processing was successful.
      # Default is to do nothing because the setup is auto_ack.
      def ack(_channel); end
    end

    def self.processor_class(name, version = nil)
      version = "V#{version}" if version
      [self.name, version, name.tr('.', '_').camelize].compact.join('::')
                                                      .constantize
    rescue NameError
      nil
    end
  end
end
