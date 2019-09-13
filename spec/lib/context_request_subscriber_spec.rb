# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContextRequestSubscriber do
  describe 'configs' do
    it do
      expect(described_class.logger).to be_an_instance_of(Logger)
      expect(described_class.exchange_name).to eq('fos.context_request')
      expect(described_class.queue_name).to eq('fos.context_request')
      expect(described_class.handlers).to eq({})
    end
  end

  describe '#run' do
    let(:subscriber_mock) { instance_double('RabbitMQSubscriber') }
    it do
      expect(ContextRequestSubscriber::RabbitMQSubscriber)
        .to receive(:new)
        .and_return(subscriber_mock)
      expect(subscriber_mock).to receive(:run).and_return(nil)
      expect(described_class.run).to be_nil
    end
  end
end
