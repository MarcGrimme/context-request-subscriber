# frozen_string_literal: true

require 'spec_helper'

module ContextRequestSubscriber
  module Processor
    RSpec.describe Request do
      let(:payload) { JsonHelper.parse_file('request') }
      let(:logger) { instance_double('Logger') }
      subject { described_class.new(logger) }

      describe 'call' do
        before do
          allow(ContextRequestSubscriber)
            .to receive(:handlers)
            .and_return(request:
                        ContextRequestSubscriber::Handler::MockHandler)
        end
        it do
          expect(subject.call(payload)).to include(
            'request_id' => '20709b0d-822d-49ec-ad1a-0446cc65a6c4',
            'request_context' => '7f67494e-187e-429e-9174-0aa2d61286cf',
            'request_start_time' => '',
            'request_path' => '/abc',
            'request_method' => 'POST',
            'request_params' => {
              'param1' => '1',
              'param2' => '2'
            },
            'app_id' => 'myapp2',
            'source' => 'myhost',
            'host' => 'localhost'
          )
        end
      end
    end
  end
end
