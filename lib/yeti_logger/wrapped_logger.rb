module YetiLogger

  # This class provides a wrapper around an instance of a class that includes
  # YetiLogger.
  #
  # The wrapper responds to the standard Logger methods :info, :warn, :error,
  # and :debug, and forwards to the YetiLogger methods.
  class WrappedLogger

    # @param obj [Object] An instance of a class that includes YetiLogger.
    def initialize(obj)
      @obj = obj
    end

    # Use metaprogramming to define methods on the instance for each
    # log level that YetiLogger supports.
    YetiLogger::LEVELS.each do |level|
      define_method(level) do |*args, &block|
        instance_variable_get(:@obj).send("log_#{level}", *args, &block)
      end
    end

  end
end
