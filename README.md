# yeti_logger

Provides standardized logging across Yesware apps.

[![Build Status](https://travis-ci.org/Yesware/yeti_logger.svg?branch=master)](https://travis-ci.org/Yesware/yeti_logger)

## Installation

Add this line to your application's Gemfile:

    gem 'yeti_logger'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install yeti_logger

## Usage

### Initialization

To use YetiLogger within an app it must be configured with a logger. For example
in a Rails application, create an initializer such as
`config/initializers/yeti_logger.rb`:

    require 'yeti_logger'

    YetiLogger.configure do |config|
      config.logger = Rails.logger
    end

### Logging for Classes

In classes where you want to use YetiLogger you must include the module:

    include YetiLogger

This will define `log_error`, `log_warn`, `log_info`, and `log_debug` methods
at both the class and instance level.

Each method has a similar signature:

    log_info(obj = nil, exception = nil, &block)

Each of these arguments is optional. Passing no args results in a blank log
message.

All log messages are automatically prefixed with the name of the class.

Exceptions will always be logged as their message and a backtrace. If you
would like a message along with the exception, use this form:

    log_info("My messsage", exception)

If you only need the exception, then use the block form above:

    log_info { exception }

In situations where a logger object is required, the `#as_logger` instance
method can be used to return an object that responds to `error`, `warn`, `info`,
and `debug`, and forwards to the instance to format log messages using
`YetiLogger`:

    logger = instance.as_logger

    # The following result in equivalent log messages
    logger.info('this message')
    instance.log_info('this message')

### Preferred use

The preferred way to use `YetiLogger` is via the block as it defers evaluation
of the string until we've decided whether or not to log the message. Along with
blocks, passing data in as a hash is also preferred.

    log_debug { { system: "dagobah", jedi: expensive_to_compute() } }

    log_debug({ system: "dagobah", jedi: expensive_to_compute() })

Both of these will result in a log message formatted with `key=value` pairs
separated by whitespace. The latter will call the `expensive_to_compute()`
method prior to entry into the `log_debug` function meaning it will be computed
whether or not the log statement is actually written out.

The block format does not support separate arguments for exception and
non-exception data. If you need both, either use the block format and use the
functions in `YetiLogger::MessageFormatters` to format the exception, or use the
`(obj, exception)` arguments taking note of any performance implications in
building the log message.

### Message formatting

The value passed in for obj or returned by the block will be formatted
depending on the content of it. If it is a hash, it will be formatted into
"key=value" pairs separated by whitespace. Any value that needs to be quoted
(embedded quotes, or has whitespace), will be quoted and embedded quotes
escaped.

Formatting of exceptions is dependent on the data type of the obj argument. If
it is a string, then a string form of the exception details is included. If obj
is a hash, then the exception in injected into the hash and printed as
additional `key=value` pairs. Classname, message and backtrace are included in
the message.

### Nested Hashes

For hash logging, each key and value are converted to strings which means
nested hashes might not serialize like you would think. Additionally, no
quotes are provided around keys or values, meaning for hashes that contain
data that may include whitespace, it might make sense to pass in a serialized
form of the hash instead of the hash itself. If you would like to override
this behavior, pass in the serialized format for the hash, such as:

    log_info { hash.to_json }
    log_info { hash.to_s }
    log_info { hash.to_my_log_format }

### User-based Logging

You can override the app-wide log level for specific user configured in `Settings.extra_logging_user_ids`. Those users will emit logs from `log_debug` calls even if the app's log level is configured as `info`. The user ID is taken from the `user_id` key of the log payload, e.g. `log_debug(user_id: @current_user.id, msg: "this is fine")`, so this won't work with the block syntax. This feature enables us to get more logging for (and hence more insight into) specific users who are experiencing problems, without hardcoding user IDs, setting environment variables and restarting the app, or increasing the overall log volume. Apps that wish to use this feature need to have the [settings-in-redis gem](https://github.com/Yesware/settings-in-redis)  and configure it as necessary ([example](https://github.com/Yesware/gmail-api-server/pull/74)).

## Test Support

There are a couple helpers provided to support testing of YetiLogger calls. All
helpers are available by requiring the relevant file and importing the module:

    require 'yeti_logger/test_helper'

    describe MyClass do
      include YetiLogger::TestHelper

      # tests here
    end

The simpler form sets up an expectation that the log level method in YetiLogger
will be called. It returns that expectation and you can extend it with your
preferred matcher:

    ...
    should_log(:info).with("exact message here")
    ...
    should_log(:warn).with(/a pattern/)
    ...

If you have an application that produces many lines of log messages at any one
level, this can be cumbersome so `YetiLogger::TestHelper` provides methods for
you to set up expectation to see specific log messages amongst all of the
messages it may receive:

    messages = [
                'YourClass: one',
                /match a regex!/,
                'YourOtherClass: three'
               ]

    expect_to_see_log_messages(messages, :info) do
      trigger_code_that_results_in_logging
    end

There is also a singular form of this `expect_to_see_log_message` that takes a
single message to match.

If you have code that logs at a level below your threshold set during testing
you may have hidden bugs. Consider the following:

    def my_method
      ...
      log_debug do
        compute_log_message(arg1, arg2)
      end
      ...
    end

If in test you set your log level to be warn, then this block will never
execute. Now, if this method were recently renamed, or another argument was
added, you would have a runtime error just waiting for someone to set the log
level down to debug. If you want to temporarily raise the log level for a given
test, you can do so:

    with_log_level(:debug) do
      should_log(:debug).with("expected message")
      my_method()
    end

Once the block is finished, the log level will be returned to whatever level you
had it previously.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
