# Helper methods for tests that interact with the Logging system
#
module YetiLogger::TestHelper

  # Execute a block within the context of a changed log level. This will ensure
  # the level is returned to is original state upon exit.
  def with_log_level(level = Logger::DEBUG)
    orig_level = YetiLogger.logger.level
    begin
      YetiLogger.logger.level = level
      yield
    ensure
      YetiLogger.logger.level = orig_level
    end
  end

  # Execute a block and ensure that among all the log messages received, message
  # is among them. Not as elegant as a should_log type of method, but I can't
  # figure out how to inject that into the rspec framework so it's evaluated
  # after the method is done being called like should_receive's are.
  def expect_to_see_log_message(message, level = :debug, &block)
    expect_to_see_log_messages([message], level, &block)
  end

  # Plural version of above
  def expect_to_see_log_messages(messages, level = :debug, &block)
    log_messages = get_log_messages(level, &block)

    # Find each message, removing the first occurrence.
    messages.each do |message|
      if message.is_a?(Regexp)
        found = log_messages.find do |log_message|
          log_message =~ message
        end
        if found
          log_messages.delete_at(log_messages.find_index(found))
        else
          fail "Should have found #{message.inspect} amongst #{log_messages.inspect}"
        end
      else
        expect(log_messages).to include(message)
        log_messages.delete_at(log_messages.find_index(message))
      end
    end
  end

  # Execute a block and ensure that the supplied log message is not among the
  # messages logged at the specified level.
  def expect_to_not_see_log_message(message, level = :debug, &block)
    expect_to_not_see_log_messages([message], level, &block)
  end

  # Plural version of above
  def expect_to_not_see_log_messages(messages, level = :debug, &block)
    log_messages = get_log_messages(level, &block)

    found = messages.find do |message|
      if message.is_a?(Regexp)
        log_messages.find do |log_message|
          log_message =~ message
        end
      else
        log_messages.include?(message)
      end
    end

    if found.present?
      fail "Should not have found #{found.inspect} amongst #{log_messages.inspect}"
    end
  end

  def get_log_messages(level = :debug, &block)
    log_messages = []

    allow(YetiLogger.logger).to receive(level) do |log_line|
      log_messages << log_line
    end

    block.call

    # There is no unstub in rspec 3, but the closest to that would be to
    # continue to stub it, but defer to the original implementation.
    allow(YetiLogger.logger).to receive(level).and_call_original

    log_messages
  end

  def should_log(level = :info)
    expect(YetiLogger.logger).to(receive(level))
  end

  def should_not_log(level = :info)
    expect(YetiLogger.logger).to_not(receive(level))
  end

end
