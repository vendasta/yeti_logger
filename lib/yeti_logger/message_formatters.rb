# require 'logger'
# require 'yeti_logger/version'
# require 'yeti_logger/configuration'
# require 'active_support/core_ext/benchmark'
# require 'active_support/concern'
# require 'active_support/core_ext/object/blank'
# require 'active_support/core_ext/object/try'


# Helper class used to format messages for logging. These can be used
# directly, but are more convenient when used via YetiLogger
module YetiLogger::MessageFormatters
  NUM_LINES_OF_EXCEPTIONS = 50

  # Helper method used to build up a single log message string you can pass to
  # the underlying logger implementation.
  # @param klass [String] Name of the class you are logging on behalf
  # @param obj [Object] Object to log, may be nil
  # @param exception [Exception] Optional exception to include in the log message
  # @return string [String] to log
  def self.build_log_message(klass, obj, exception = nil, backtrace_lines = NUM_LINES_OF_EXCEPTIONS)
    msg = if obj.is_a?(Hash)
            if exception
              format_hash(obj.merge(exception_hash(exception, backtrace_lines)))
            else
              format_hash(obj)
            end
          elsif exception
            "#{obj} Exception: #{exception.message} "\
            "Error Class: #{exception.class.name} "\
            "#{format_backtrace(exception, backtrace_lines)}"
          else
            obj
          end
    "#{klass}: #{msg}"
  end

  # Format a Hash into key=value pairs, separated by whitespace.
  # TODO: support nested hashes by serializing to JSON?
  #
  # @param hash [Hash] Hash to serialize into a key=value string
  # @return [String] string representation of hash
  def self.format_hash(hash)
    hash.map do |k, v|
      "#{k}=#{quote_unquoted(v.to_s)}"
    end.join(' ')
  end

  # Helper method to quote strings that need quoting (spaces in them, or
  # embedded quotes) that have not already been quoted.
  # @param str [String] string to quote if it has spaces within it
  # @return [String] original string, or quoted version if necessary
  def self.quote_unquoted(str)
    if str && (!needs_quoting?(str) || quoted?(str))
      str
    else
      str.inspect
    end
  end

  def self.needs_quoting?(str)
    str.index(' ') || str.index('"')
  end
  private_class_method :needs_quoting?

  def self.quoted?(str)
    str[0] == ?" && str[-1] == ?"
  end
  private_class_method :quoted?

  # Create a hash with the exception message and backtrace. You can merge this
  # into an existing hash if you're logging key=value pairs.
  # @param exception [Exception] The Exception you want to create a hash for.
  # @param lines [Integer] How many lines of the backtrace to keep.
  # @return [Hash] Hash with exception details in it.
  def self.exception_hash(exception, lines = 20)
    {
      :error => exception.message,
      :error_class => exception.class.name,
      :backtrace => format_backtrace(exception, lines)
    }
  end

  # Format a backtrace by joining all lines into a single line and quoting the
  # results. You can optionally specify how many lines to include.
  # @param exception [Exception] The Exception you want to convert to a string
  # @param lines [Integer] How many lines of the backtrace to keep.
  # @return [String] String of the backtrace.
  def self.format_backtrace(exception, lines = 20)
    exception.try(:backtrace).try(:take, lines).try(:join, ', ').inspect
  end

end
