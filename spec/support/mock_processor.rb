# frozen_string_literal: true

module ContextRequestSubscriber
  module Processor
    class MockProcessor < Base; end
    class MockExceptionProcessor < Base
      def call(*_ignore)
        raise StandardError(self.class.name)
      end
    end
  end
end
