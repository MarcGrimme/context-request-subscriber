# frozen_string_literal: true

require 'spec_helper'

module ContextRequestSubscriber
  module Handler
    module JsonApiHandler
      RSpec.describe Request do
        subject(:request) { described_class.new({}, site: url) }
        let(:url) { 'http://localhost:8080' }

        describe '#initialize' do
          it { expect(request.class.site).to eq url }
        end

        describe '#call' do
          before do
            expect(request).to receive(:save).and_return(nil)
            expect(described_class).to receive(:with_headers).with({}).and_yield
          end

          it { expect(request.call).to be_nil }
        end
      end
    end
  end
end
