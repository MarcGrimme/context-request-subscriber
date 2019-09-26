# frozen_string_literal: true

module ContextRequestSubscriber
  module Handler
    class MockHandler
      def initialize(payload, **_keys)
        @payload = payload
      end

      def call
        @payload
      end
    end
  end
end
