require 'spec_helper'

class YetiLogger::TestLogger
  include YetiLogger
end


describe YetiLogger::TestHelper do
  include described_class

  let(:instance) { YetiLogger::TestLogger.new }

  before(:each) do
    YetiLogger.logger.level = Logger::INFO
    expect(YetiLogger.logger.level).to be > Logger::DEBUG
  end

  # NOTE: I'm using the block form here since YetiLogger does the level checking
  # for blocks, rather than relying on the logger implementation.
  describe '.with_log_level' do

    context 'when not using with_log_level' do

      it 'respects the log level' do
        expect(YetiLogger.logger).to_not receive(:debug)
        expect(YetiLogger.logger).to receive(:info).with('YetiLogger::TestLogger: info')

        instance.log_debug { 'debug' }
        instance.log_info { 'info' }
      end

      it 'can adjust the log level to log more' do
        expect(YetiLogger.logger).to receive(:debug).with('YetiLogger::TestLogger: say')
        with_log_level(Logger::DEBUG) do
          instance.log_debug { 'say' }
        end
      end

      it 'can adjust the log level to log less' do
        expect(YetiLogger.logger).to_not receive(:warn)
        with_log_level(Logger::ERROR) do
          instance.log_warn { 'warn!' }
        end
      end

    end

  end

  describe '.expect_to_see_log_messages' do
    it 'has a singular form' do
      expect_to_see_log_message('YetiLogger::TestLogger: foo', :warn) do
        instance.log_warn('foo')
      end
    end

    it 'checks for multiple messages' do
      messages = [
                  'YetiLogger::TestLogger: one',
                  'YetiLogger::TestLogger: two'
                 ]
      expect_to_see_log_messages(messages, :info) do
        instance.log_info('one')
        instance.log_info('two')
      end
    end

    it 'only stubs the log level you request' do
      expect(YetiLogger.logger).to receive(:info).with('YetiLogger::TestLogger: info')

      expect_to_see_log_message('YetiLogger::TestLogger: warn', :warn) do
        instance.log_info { 'info' }
        instance.log_warn { 'warn' }
      end
    end

    it 'supports regexes' do
      messages = [
                  'YetiLogger::TestLogger: one',
                  /two-\d/,
                  'YetiLogger::TestLogger: three'
                 ]
      expect_to_see_log_messages(messages, :info) do
        instance.log_info('one')
        instance.log_info('two-7')
        instance.log_info('three')
      end
    end

    it 'fails when it cannot find the string message' do
      expect do
        expect_to_see_log_message('not there', :info) do
          instance.log_info('one')
        end
      end.to raise_exception(RSpec::Expectations::ExpectationNotMetError)
    end

    it 'fails when it cannot find the regexp message' do
      expect do
        expect_to_see_log_message(/bazinga/, :info) do
          instance.log_info('one')
        end
      end.to raise_exception(RuntimeError)
    end

    it 'fails when it runs out of messages to search through' do
      expect do
        messages = [
                    'YetiLogger::TestLogger: one',
                    /two-\d/,
                    'YetiLogger::TestLogger: three',
                    'YetiLogger::TestLogger: four'
                   ]
        expect_to_see_log_messages(messages, :info) do
          instance.log_info('one')
          instance.log_info('two-7')
          instance.log_info('three')
        end
      end.to raise_exception(RSpec::Expectations::ExpectationNotMetError)
    end

  end

  describe '.should_log' do
    it 'verifies a log message came through' do
      should_log(:info).with("YetiLogger::TestLogger: hello!")
      instance.log_info("hello!")
    end
  end

  describe '.should_not_log' do
    it 'verifies a log message does not happen' do
      should_not_log(:info)
      if false
        instance.log_info("hello!")
      end
    end
  end

end
