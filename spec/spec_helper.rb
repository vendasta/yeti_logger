# Start up coverage before anything else,
# otherwise we only get coverage for rspecs.
require 'simplecov'
SimpleCov.start do
  add_filter "/spec/" # ignore spec files
end
SimpleCov.minimum_coverage 100

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'active_support/log_subscriber/test_helper'

require 'yeti_logger'
require 'yeti_logger/test_helper'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.include ActiveSupport::LogSubscriber::TestHelper

  config.before do
    YetiLogger.configure do |config|
      config.logger = ActiveSupport::LogSubscriber::TestHelper::MockLogger.new
    end
  end

end
