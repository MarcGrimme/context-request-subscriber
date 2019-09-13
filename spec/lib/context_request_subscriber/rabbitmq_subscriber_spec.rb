# frozen_string_literal: true

require 'spec_helper'

module ContextRequestSubscriber
  RSpec.describe RabbitMQSubscriber do
    describe '#run' do
      let(:processor) { Processor::MockProcessor.new }
      let(:session_params) { {} }
      let(:url) { nil }
      let(:bunny_session) { double('bunny_session') }
      let(:bunny_channel) { double('bunny_channel') }
      let(:exchange) { double('exchange') }
      let(:exchange_name) { ContextRequestSubscriber.exchange_name }
      let(:channel) { double('channel') }
      let(:queue) { double('queue') }
      let(:properties) { { type: 'mock_processor' } }
      let(:payload) { '{}' }
      let(:delivery_info) do
        double('DeliveryInfo', delivery_tag: 'anything',
                               to_hash: { delivery_tag: 'anything' })
      end
      let(:logger) { instance_double('Logger', error: nil) }
      let(:config) { ContextRequestSubscriber.config }

      subject do
        described_class.new(processor, **config)
      end

      before do
        allow(ContextRequestSubscriber.config).to receive(:logger) { logger }
        expect(Bunny).to receive(:new).with(url, session_params)
                                      .and_return(bunny_session)
        expect(bunny_session).to receive(:start)
        expect(bunny_session).to receive(:create_channel)
          .and_return(bunny_channel)
        expect(bunny_channel).to receive(:confirm_select)
        expect(bunny_channel).to receive(:exchanges)
          .and_return(exchange_name => exchange)
      end

      context 'happy path' do
        before do
          expect(bunny_channel).to receive(:queue)
            .with(ContextRequestSubscriber.queue_name,
                  exclusive: false,
                  durable: true)
            .and_return(queue)
          expect(exchange).to receive(:channel).and_return(channel)
          expect(queue).to receive(:bind).with(exchange, nil)
          expect(queue).to receive(:subscribe)
            .with(manual_ack: true, block: false)
            .and_yield(delivery_info, properties, payload)
          expect(channel).to receive(:ack).with('anything')
        end
        it { expect(subject.run).to be_nil }
      end

      context 'non existing exchange' do
        let(:exchange_name) { 'none' }
        it do
          expect { subject.run }
            .to raise_error(RabbitMQSubscriber::ExchangeNotFound)
        end
      end

      context 'special config' do
        let(:exchange_name) { 'none' }
        let(:config) do
          { queue_name: 'myqueue', queue_durable: true }
        end
        it do
          expect { subject.run }
            .to raise_error(RabbitMQSubscriber::ExchangeNotFound)
        end
      end

      context 'handle_error' do
        let(:properties) { { type: 'mock_exception_processor' } }

        before do
          expect(bunny_channel).to receive(:queue)
            .with(ContextRequestSubscriber.queue_name,
                  exclusive: false,
                  durable: true)
            .and_return(queue)
          expect(exchange).to receive(:channel).and_return(channel)
          expect(queue).to receive(:bind).with(exchange, nil)
          expect(queue).to receive(:subscribe)
            .with(manual_ack: true, block: false)
            .and_yield(delivery_info, properties, payload)
        end

        it { expect { subject.run }.to raise_error StandardError }
      end
    end
  end
end
