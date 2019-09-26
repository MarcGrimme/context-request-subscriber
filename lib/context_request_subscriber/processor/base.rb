# frozen_string_literal: true

module ContextRequestSubscriber
  module Processor
    # :nodoc:
    class Base
      def initialize(logger, **keys)
        @logger = logger
        @handler_params = keys[:handler_params] || {}
      end

      def call(payload)
        if (handler = ContextRequestSubscriber.handlers[type_name])
          handler.new(payload, **@handler_params).call
        else
          @logger.error("Could not find handler for \
message type #{type_name}")
        end
      end

      private

      def type_name
        self.class.name.split('::').last.underscore.downcase.to_sym
      end
    end
  end
end
