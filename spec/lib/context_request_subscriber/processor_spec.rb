# frozen_string_literal: true

require 'spec_helper'

module ContextRequestSubscriber
  RSpec.describe Processor do
    describe '#run' do
      let(:delivery_info) { nil }
      let(:properties) { { type: message_type, headers: headers } }
      let(:headers) { {} }
      let(:logger) { instance_double('Logger', error: nil) }

      before do
        allow(ContextRequestSubscriber.config).to receive(:logger) { logger }
      end

      context 'with invalid type' do
        let(:message_type) { 'does.not.matter' }

        it 'processor complains about invalid type.' do
          subject.run(delivery_info, properties, 'null')
          expect(logger).to have_received(:error)
            .with("Invalid processor type or processor type with \
name #{message_type} cannot be found")
        end
      end

      context 'with invalid payload' do
        let(:message_type) { 'request' }
        let(:payload) { 'xxx: yyy' }

        it 'processor complains about invalid payload.' do
          subject.run(delivery_info, properties, payload)
          expect(logger).to have_received(:error)
            .with("Could not parse message payload with payload \
#{payload}. Ignoring.")
        end
      end

      context 'call the processor without handler' do
        let(:message_type) { 'mock.processor' }
        let(:payload) { 'null' }

        it 'processor calls call in processor.' do
          subject.run(delivery_info, properties, payload)
          expect(logger).to have_received(:error)
            .with("Could not find handler for \
message type mock_processor")
        end
      end
    end
  end
end
