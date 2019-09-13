# frozen_string_literal: true

module ContextRequestSubscriber
  # :nodoc:
  module Processor
    autoload :Base, 'context_request_subscriber/processor/base'
    autoload :Request, 'context_request_subscriber/processor/request'
    autoload :Context, 'context_request_subscriber/processor/context'

    extend self

    def run(_delivery_info, properties, payload)
      payload = JSON.parse(payload)
      process(properties[:type], properties[:headers]&.dig('version'), payload)
    rescue JSON::ParserError
      ContextRequestSubscriber.logger.error("Could not parse message payload \
with payload #{payload}. Ignoring.")
      nil
    end

    def process(name, version = nil, payload = {})
      processor = processor_class(name, version)&.new
      if processor
        processor.call(payload)
      else
        ContextRequestSubscriber.logger.error("Invalid processor type or \
processor type with name #{name} cannot be found")
      end
    end

    def processor_class(name, version = nil)
      version = "V#{version}" if version
      [self.name, version, name.tr('.', '_').camelize].compact.join('::')
                                                      .constantize
    rescue NameError
      nil
    end
  end
end
