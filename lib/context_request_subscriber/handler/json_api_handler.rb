# frozen_string_literal: true

require 'json_api_client'

module ContextRequestSubscriber
  module Handler
    module JsonApiHandler
      # :nodoc:
      class Base < JsonApiClient::Resource
        def initialize(params, **keys)
          @headers = keys.fetch(:handler_headers, {})
          self.class.site = keys.fetch(:site, nil)
          super(params)
        end

        def call
          self.class.with_headers(@headers) do
            save
          end
        end
      end

      # :nodoc:
      class Context < Base; end

      # :nodoc:
      class Request < Base; end
    end
  end
end
