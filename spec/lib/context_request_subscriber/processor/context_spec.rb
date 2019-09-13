# frozen_string_literal: true

require 'spec_helper'

module ContextRequestSubscriber
  module Processor
    RSpec.describe Context do
      let(:payload) { JsonHelper.parse_file('context') }
      subject { described_class.new }

      describe 'call' do
        before do
          allow(ContextRequestSubscriber)
            .to receive(:handlers)
            .and_return(context:
                        ContextRequestSubscriber::Handler::MockHandler)
        end
        it do
          expect(subject.call(payload)).to include(
            'context_id' => '7f67494e-187e-429e-9174-0aa2d61286cf',
            'owner_id' => '31cdd619-21c2-4b26-8409-f2d40909a0c5',
            'context_status' => 'active',
            'context_type' => 'session'
          )
        end
      end
    end
  end
end
