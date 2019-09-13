# frozen_string_literal: true

module ContextRequestSubscriber
  module ErrorHandler
    # :nodoc:
    class LogErrorHandler
      def initialize(logger = nil)
        @logger = (logger || ContextRequestSubscriber.logger)
      end

      def call(error, _info, _properties, _payload)
        @logger.error("Error recieved during processing the message. \
Error #{error}.")
      end
    end

    # :nodoc:
    class LogAndRaiseErrorHandler < LogErrorHandler
      def call(error, info, properties, payload)
        super(error, info, properties, payload)
        raise error
      end
    end
  end
end
