# frozen_string_literal: true

module ContextRequestSubscriber
  module Processor
    # :nodoc:
    class Base
      def call(payload)
        if (handler = ContextRequestSubscriber.handlers[type_name])
          handler.new(payload).call
        else
          ContextRequestSubscriber.logger.error("Could not find handler for \
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
