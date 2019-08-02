require 'logger'
require 'yeti_logger/version'
require 'yeti_logger/constants'
require 'yeti_logger/configuration'
require 'yeti_logger/wrapped_logger'
require 'yeti_logger/message_formatters'
require 'active_support/core_ext/benchmark'
require 'active_support/concern'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'

# Mixin module providing Yesware logging functionality including formatting of
# log message data (exceptions, hashes, etc). Refer to the Readme for further
# information and examples.
#
# Module you can include in your class to get logging with class name prefixing.
# This will also log hashes as key=value pairs and exception backtraces. These
# methods are added via metaprogramming. When it's done, you'll have methods to
# log at each level:
# - debug
# - info
# - warn
# - error
#
# Each method will have a signature that looks like:
#   log_info(obj = nil, exception = nil, &block)
#
# Each of these arguments is optional. Pass no arguments results in a blank line
# being logged (with a classname prefix).
#
# The ideal usage for YetiLogger is to pass in blocks:
#
#   log_info { "Here is my message with #{some} class #{values}" }
#
# This will defer evaluation of the string until the logger has determined if
# the current log level is high enough to warrant evaluating the string and
# logging it.
#
# Exceptions will be logged as a combination of the message, the class and some
# number of lines of the backtrace. If you pass in a value for obj that is a
# Hash, then the exception will be injected into the hash.
#
#   log_info("My message", exception)
#
# If you only need the exception, then use the block form above:
#
#   log_info { exception }
#
# The value passed in for obj or returned by the block will be formatted
# depending on the content of it. If it is a hash, we will format into
# "key=value" pairs separated by whitespace. If the value is an exception, the
# message will be logged along with the backtrace. All other objects are
# converted to string via the to_s method.
#
# For hash logging, each key and value are converted to strings which means
# nested hashes might not serialize like you would think. Additionally, no
# quotes are provided around keys or values, meaning for hashes that contain
# data that may include whitespace, it might make sense to pass in a serialized
# form of the hash instead of the hash itself. If you would like to override
# this behavior, pass in the serialized format for the hash, such as:
#
#   log_info { hash.to_json }
#   log_info { hash.to_s }
#   log_info { hash.to_my_log_format }
#
#
module YetiLogger
  extend ActiveSupport::Concern

  # This module contains log method definitions that are used at both the
  # class and the instance level.
  # Each log method is defined explicitly, despite the obvious repetition,
  # to avoid the cost of creating a Proc for any, possibly unused, block
  # passed to the log method.
  # Define these methods explicitly allows the use of yield.
  module LogMethods
    # See usage at https://github.com/Yesware/yeti_logger/blob/master/README.md#user-based-logging
    def log_debug(obj = nil, ex = nil)
      should_log_as_info = YetiLogger.try(:promote_debug_to_info?, obj)

      if YetiLogger.logger.level <= Logger::DEBUG || should_log_as_info
        msg = if block_given?
                MessageFormatters.build_log_message(log_class_name, yield)
              else
                MessageFormatters.build_log_message(log_class_name, obj, ex)
              end
        YetiLogger.logger.send(should_log_as_info ? :info : :debug, msg)
      end
    end

    def log_info(obj = nil, ex = nil)
      if YetiLogger.logger.level <= Logger::INFO
        msg = if block_given?
                MessageFormatters.build_log_message(log_class_name, yield)
              else
                MessageFormatters.build_log_message(log_class_name, obj, ex)
              end
        YetiLogger.logger.send(:info, msg)
      end
    end

    def log_warn(obj = nil, ex = nil)
      if YetiLogger.logger.level <= Logger::WARN
        msg = if block_given?
                MessageFormatters.build_log_message(log_class_name, yield)
              else
                MessageFormatters.build_log_message(log_class_name, obj, ex)
              end
        YetiLogger.logger.send(:warn, msg)
      end
    end

    def log_error(obj = nil, ex = nil)
      if YetiLogger.logger.level <= Logger::ERROR
        msg = if block_given?
                MessageFormatters.build_log_message(log_class_name, yield)
              else
                MessageFormatters.build_log_message(log_class_name, obj, ex)
              end
        YetiLogger.logger.send(:error, msg)
      end
    end

    def log_fatal(obj = nil, ex = nil)
      if YetiLogger.logger.level <= Logger::FATAL
        msg = if block_given?
                MessageFormatters.build_log_message(log_class_name, yield)
              else
                MessageFormatters.build_log_message(log_class_name, obj, ex)
              end
        YetiLogger.logger.send(:fatal, msg)
      end
    end
  end

  # Class-level methods.
  module ClassMethods
    include LogMethods

    def log_class_name
      self.name
    end
  end

  # Instance-level log methods
  include LogMethods

  def log_class_name
    self.class.name
  end

  def log_time(action, level = :info)
    ms = Benchmark.ms do
      yield
    end
    YetiLogger.logger.send(level,
                           MessageFormatters.build_log_message(self.class.name,
                                                               { action: action,
                                                                 time_ms: ms.to_i }))
  end

  # Wrap self in an object that responds to :info, :warn, :error, :debug, etc.
  # @return [YetiLogger::WrapperLogger]
  def as_logger
    YetiLogger::WrappedLogger.new(self)
  end
end
