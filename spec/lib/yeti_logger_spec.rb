require 'spec_helper'
require 'yeti_logger/test_helper'

# Class used for class and instance level testing
module Yucatan
  class YellinYeti
    include YetiLogger
  end
end

# Used for testing via module and also by inclusion into rspecs.
module ModularLog
  include YetiLogger

  def invoke_logger
    log_warn "invoke via include"
  end
end

# Class used for class and instance level testing
module Yucatan
  class YellinYeti
    include YetiLogger
  end
end

# Used for testing via module and also by inclusion into rspecs.
module ModularLog
  include YetiLogger

  def invoke_logger
    log_warn "invoke via include"
  end
end

describe YetiLogger do

  include YetiLogger::TestHelper

  include ModularLog

  let(:instance) { Yucatan::YellinYeti.new }
  let(:data) do
    {
        "pet" => "dog",
        "color" => "brown"
    }
  end

  let(:ex) do
    e = nil
    begin
      raise Exception.new("breakin!")
    rescue Exception => exception
      e = exception
    end
    e
  end
  let(:runtime) do
    e = nil
    begin
      raise "fail!"
    rescue Exception => ex
      e = ex
    end
    e
  end

  it 'has a version number' do
    expect(YetiLogger::VERSION).to_not be_nil
  end

  it "can be used by rspec code that includes modules that use it" do
    should_log(:warn).with(/.*invoke via include/)
    invoke_logger
  end

  [ Yucatan::YellinYeti, Yucatan::YellinYeti.new, ModularLog ].each do |target|
    class_name = "Yucatan::YellinYeti"
    target_type = "instance"
    if target.class == Class
      target_type = "class"
    elsif target.class == Module
      class_name = "ModularLog"
      target_type = "module"
    end

    context "when used with a #{target_type}" do

      # Debug tested separately below.
      %w{ info warn error fatal }.each do |level|

        it "has #{target_type} methods for level '#{level}'" do
          should_log(level).with("#{class_name}: #{target_type}-stuffs")
          target.send("log_#{level}", "#{target_type}-stuffs")
        end

      end

      describe "log_debug" do
        let(:user_id) { rand(9000) }

        shared_examples_for "it logs at the expected level" do |expected_level|
          it "logs at #{expected_level} level" do
            regex = /#{class_name}:.*#{target_type}.*debuggin.*user_id=#{user_id}/
            expect_to_see_log_message(regex, expected_level) do
              target.log_debug(msg: "#{target_type} debuggin", user_id: user_id)
            end
          end
        end

        context "when there's no Settings module," do
          before(:each) do
            if defined?(Settings)
              Object.send(:remove_const, :Settings)
            end
          end

          it_behaves_like "it logs at the expected level", :debug
        end

        context "when there's a Settings module" do
          before(:each) do
            Settings = Class.new
          end

          after(:each) do
            if defined?(Settings)
              Object.send(:remove_const, :Settings)
              expect(defined?(Settings)).to be nil
            end
          end

          context "when there is an extra_logging_user_ids setting," do
            before(:each) do
              allow(Settings).to receive(:extra_logging_user_ids) { extra_logging_user_ids }
            end

            context "when the extra_logging_user_ids setting is nil," do
              let(:extra_logging_user_ids) { nil }

              it_behaves_like "it logs at the expected level", :debug
            end

            context "when the extra_logging_user_ids setting is an empty array," do
              let(:extra_logging_user_ids) { [] }

              it_behaves_like "it logs at the expected level", :debug
            end

            context "when the extra_logging_user_ids setting doesn't include the user ID in the payload," do
              let(:extra_logging_user_ids) { [user_id + 1] }

              it_behaves_like "it logs at the expected level", :debug
            end

            context "when the extra_logging_user_ids setting includes the user ID in the payload," do
              let(:extra_logging_user_ids) { [user_id] }

              it_behaves_like "it logs at the expected level", :info

              context "when there's no user_id in the log payload," do
                it "logs at debug level" do
                  regex = /#{class_name}:.*#{target_type}.*debuggin/
                  expect_to_see_log_message(regex, :debug) do
                    target.log_debug(msg: "#{target_type} debuggin")
                  end
                end
              end
            end
          end
        end
      end

      it "can log key value pairs at #{target_type} level" do
        should_log(:info).with("#{class_name}: pet=dog color=brown")
        target.log_info(data)
      end

      it "can log exceptions at #{target_type} level" do
        should_log(:info) do |m|
          m.start_with?("#{class_name}: breakin!").should == true
          m.include?("/spec/lib/yeti_logger_spec.rb:").should == true
        end
        target.log_info(ex)
      end

      it "can log subclasses of exceptions at #{target_type} level" do
        should_log(:info) do |m|
          m.start_with?("#{class_name}: fail!").should == true
          m.include?("/spec/lib/yeti_logger_spec.rb:").should == true
        end
        target.log_info(runtime)
      end

      it "can log messages and exceptions at #{target_type} level" do
        re = /#{class_name}:\ssomething\sException:\sbreakin!\sError\sClass:\sException
              .*\/spec\/lib\/yeti_logger_spec\.rb:.*/x
        should_log(:info).with(re)
        expect(ex.backtrace).to_not be_nil
        target.log_info("something", ex)
      end

      it "will only log exception messages if it has no backtrace at #{target_type} level" do
        should_log(:info).with("#{class_name}: blat!")
        target.log_info(Exception.new("blat!"))
      end

      it "can be called without arguments" do
        should_log(:info).with("#{class_name}: ")
        target.log_info
      end

      it "can log string messages from block" do
        should_log(:info).with("#{class_name}: from block")
        target.log_info { "from block" }
      end

      it "can log hash messages from block" do
        should_log(:info).with("#{class_name}: pet=dog color=brown")
        target.log_info { data }
      end

      it "can log exceptions from block" do
        should_log(:info) do |m|
          m.start_with?("#{class_name}: breakin!").should == true
          m.include?("/spec/lib/yeti_logger_spec.rb:").should == true
        end
        target.log_info { ex }
      end

      it "only logs the block and ignores the obj argument" do
        should_log(:info).with("#{class_name}: and block")
        target.log_info("argument") { "and block" }
      end

      it "only logs the block and ignores both obj and ex arguments" do
        should_log(:info).with("#{class_name}: and block")
        target.log_info("argument", ex) { "and block" }
      end

      it "will not evaluate block unless the log level is high enough" do
        with_log_level(Logger::INFO) do
          target.log_info do
            @my_var = 2
            "incremented at info"
          end
          expect(@my_var).to eq(2)
          target.log_debug do
            @my_var = 3
            "incremented at debug?"
          end
          expect(@my_var).to eq(2)
        end
      end

    end
  end # Iterate over class & instance

  describe '#log_time' do

    it "logs time at the info level by default" do
      should_log(:info)
      instance.log_time("query_db") do
        sleep 0.1
      end
    end

    it "logs at the user-specified level when asked" do
      should_log(:warn)
      instance.log_time("query", :warn) do
        sleep 0.01
      end
    end
  end

  describe '#as_logger' do
    it 'returns a WrappedLogger' do
      expect(instance.as_logger).to be_instance_of(YetiLogger::WrappedLogger)
    end

    it 'uses the current instance as the wrapped object' do
      expect(instance.as_logger.instance_variable_get(:@obj)).to eql(instance)
    end
  end
end

