require 'spec_helper'
require 'yeti_logger/test_helper'

class NakedLogger
  include YetiLogger
end

describe YetiLogger::WrappedLogger do
  include YetiLogger::TestHelper

  let(:instance) { NakedLogger.new }
  let(:logger) { instance.as_logger }

  YetiLogger::LEVELS.each do |level|
    describe "##{level}" do
      it "forwards #{level} to the instance" do
        expect(instance).to receive("log_#{level}").with('foo')
        logger.send(level, 'foo')
      end

      it "forwards #{level} with a block to the instance" do
        expect(instance).to receive("log_#{level}").and_call_original
        should_log(level).with("NakedLogger: from block")
        logger.send(level) { 'from block' }
      end
    end
  end
end
