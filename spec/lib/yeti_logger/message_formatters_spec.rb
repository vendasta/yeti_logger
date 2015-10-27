require 'spec_helper.rb'

# Class used for class and instance level testing
module Yucatan
  class YellinYeti
    include YetiLogger
  end
end

describe YetiLogger::MessageFormatters do
  let(:exception) do
    begin
      raise StandardError.new('fail!')
    rescue => ex
      ex
    end
  end
  let(:exception_without_backtrace) do
    StandardError.new('no-backtrace fail!')
  end
  let(:klass) do
    Yucatan::YellinYeti.name
  end

  describe '.build_log_message' do
    let(:klassname) { klass }
    let(:obj) { 'foo bar' }
    let(:hash) do
      {
        :k1 => 'value',
        :k2 => 37
      }
    end

    it 'dumps plain ole objects' do
      expect(described_class.build_log_message(klass, obj)).
          to eq("#{klassname}: foo bar")
    end

    it 'formats hashes' do
      expect(described_class.build_log_message(klass, hash)).
          to eq("#{klassname}: k1=value k2=37")
    end

    it 'appends on exceptions if they there' do
      expect(described_class.build_log_message(klass, 'message', exception)).
          to eq("#{klassname}: message Exception: fail! "\
                "Error Class: StandardError "\
                "#{exception.backtrace.take(50).join(', ').inspect}")
    end

    it 'appends an exception onto the hash' do
      expect(described_class.build_log_message(klass, hash, exception)).
          to eq("#{klassname}: k1=value k2=37 "\
                "error=fail! "\
                "error_class=StandardError "\
                "backtrace=#{exception.backtrace.take(50).join(', ').inspect}")
    end

    it 'quotes values that need them.' do
      hash[:quoted] = 'some value that is very long'
      expect(described_class.build_log_message(klass, hash)).
          to eq("#{klassname}: k1=value k2=37 "\
                "quoted=\"some value that is very long\"")
    end

  end

  describe '.exception_hash' do
    it 'formats a hash with the exception details' do
      expect(described_class.exception_hash(exception)).
          to eq({
                  :error => 'fail!',
                  :error_class => 'StandardError',
                  :backtrace => exception.backtrace.take(20).join(', ').inspect
                })
    end

    it 'can deal with an exception without a backtrace' do
      expect(described_class.exception_hash(exception_without_backtrace)).
          to eq({
                  :error => 'no-backtrace fail!',
                  :error_class => 'StandardError',
                  :backtrace => 'nil'
                })
    end

    it 'can be told to produce shorter backtraces' do
      expect(described_class.exception_hash(exception, 1)).
          to eq({
                  :error => 'fail!',
                  :error_class => 'StandardError',
                  :backtrace => exception.backtrace.take(1).join(', ').inspect
                })
    end
  end

  describe '.format_backtrace' do

    it 'formats backtraces on one line' do
      expect(described_class.format_backtrace(exception)).
          to eq(exception.backtrace.take(20).join(', ').inspect)
    end

    it 'deals with exceptions without backtraces' do
      expect(described_class.format_backtrace(exception_without_backtrace)).
          to eq('nil')
    end

    it 'can be told to produce shorter backtraces' do
      expect(described_class.format_backtrace(exception, 1)).
          to eq(exception.backtrace.take(1).join(', ').inspect)
    end

  end

  describe '.quote_unquoted' do

    it 'does not quote nil values' do
      expect(described_class.quote_unquoted(nil)).to eq("nil")
    end

    it 'does not quote simple values' do
      expect(described_class.quote_unquoted("hello")).to eq("hello")
    end

    it 'does quote values with spaces in them' do
      expect(described_class.quote_unquoted("hello world")).
          to eq("\"hello world\"")
    end

    it 'does quote values with quotes in them' do
      expect(described_class.quote_unquoted("hello\"world")).
          to eq("\"hello\\\"world\"")
    end

    it 'does not re-quote quoted values' do
      expect(described_class.quote_unquoted("\"hello world\"")).
          to eq("\"hello world\"")
    end

  end
end
