# frozen_string_literal: true

require 'spec_helper'

module ContextRequestSubscriber
  module ErrorHandler
    RSpec.describe LogErrorHandler do
      let(:logger) { instance_double('Logger') }
      let(:error) { StandardError.new('testmessage') }
      subject { described_class.new(logger) }
      describe '#call' do
        it do
          errormessage = "Error recieved during processing the message. \
Error testmessage."
          expect(logger).to receive(:error).with(errormessage)
                                           .and_return(nil)
          expect(subject.call(error, {}, {}, {})).to be_nil
        end
      end
    end

    RSpec.describe LogAndRaiseErrorHandler do
      let(:logger) { instance_double('Logger') }
      let(:error) { StandardError.new('testmessage') }
      subject { described_class.new(logger) }
      describe '#call' do
        it do
          errormessage = "Error recieved during processing the message. \
Error testmessage."
          expect(logger).to receive(:error).with(errormessage)
                                           .and_return(nil)
          expect { subject.call(error, {}, {}, {}) }.to raise_error(error)
        end
      end
    end
  end
end
