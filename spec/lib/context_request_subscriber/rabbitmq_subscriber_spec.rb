# frozen_string_literal: true

require 'spec_helper'

module ContextRequestSubscriber
  RSpec.describe RabbitMQSubscriber do
    describe '#run' do
      let(:session_params) { { automatically_recover: true, threaded: true } }
      let(:url) { nil }
      let(:connection) { double('connection') }
      let(:channel) { double('channel', exchanges: exchanges) }
      let(:exchange) { double('exchange') }
      let(:exchanges) { { exchange_name => exchange } }
      let(:exchange_name) { ContextRequestSubscriber.exchange_name }
      let(:queue) { double('queue') }
      let(:properties) { { type: 'mock_processor' } }
      let(:payload) { '{}' }
      let(:delivery_info) do
        double('DeliveryInfo', delivery_tag: 'anything',
                               to_hash: { delivery_tag: 'anything' })
      end
      let(:logger) { instance_double('Logger', error: nil, debug: nil) }
      let(:config) do
        ContextRequestSubscriber
          .config.merge(logger: logger,
                        on_error: ErrorHandler::LogAndRaiseErrorHandler)
      end
      let(:processor) { Processor::MockProcessor.new(logger) }
      let(:queue_durable) { true }

      subject do
        described_class.new(**{ queue_durable: queue_durable }.merge(config))
      end

      context 'with bunny impl' do
        before do
          expect(Bunny).to receive(:new).with(url, session_params)
                                        .and_return(connection)
          expect(connection).to receive(:start)
          expect(connection).to receive(:create_channel)
            .and_return(channel)
          expect(channel).to receive(:queue)
            .with(ContextRequestSubscriber.queue_name,
                  exclusive: false,
                  durable: queue_durable)
            .and_return(queue)
        end

        context 'happy path' do
          before do
            expect(queue).to receive(:bind).with(exchange, routing_key: '#')
            expect(queue).to receive(:subscribe)
              .with(manual_ack: true, block: false)
              .and_yield(delivery_info, properties, payload)
            expect(exchange).to receive_message_chain(:channel,
                                                      :work_pool, :join)
              .and_return(nil)
          end
          context 'with existent queue' do
            it { expect(subject.run).to be_nil }
          end

          context 'with queue_opts' do
            let(:queue_durable) { false }
            it { expect(subject.run).to be_nil }
          end

          context 'with non existent exchange' do
            let(:exchanges) { {} }

            before do
              expect(Bunny::Exchange).to receive(:new)
                .with(channel, 'topic', exchange_name, {}).and_return(exchange)
            end

            it { expect(subject.run).to be_nil }
          end
        end

        context 'handle_error' do
          let(:properties) { { type: 'mock_exception_processor' } }

          before do
            expect(queue).to receive(:bind).with(exchange, routing_key: '#')
            expect(queue).to receive(:subscribe)
              .with(manual_ack: true, block: false)
              .and_yield(delivery_info, properties, payload)
          end

          it do
            expect { subject.run }.to raise_error(StandardError)
          end
        end
      end

      context 'with fetch_queue_callback' do
        before do
          allow(ContextRequestSubscriber.config).to receive(:logger) { logger }
          get_queue = ->(_context) { [exchange, queue] }
          expect(queue).to receive(:subscribe)
            .with(manual_ack: true, block: false)
            .and_yield(delivery_info, properties, payload)
          expect(ContextRequestSubscriber).to receive(:fetch_queue_callback)
            .and_return(get_queue)
          expect(exchange).to receive_message_chain(:channel,
                                                    :work_pool, :join)
            .and_return(nil)
        end
        it { expect(subject.run).to be_nil }
      end
    end
  end
end
