# yeti_logger changelog

## v3.3.3
- Replace deprecated `active_support/core_ext/benchmark` with Ruby's standard `Benchmark` library (fixes Rails 8.2 deprecation warning)

## v3.3.2
- CustomFormatter does not include timestamp in log in production and staging environments

## v3.3.1
- CustomFormatter uses Time.now instead of Time.now.utc

## v3.3.0
- Add custom rails logger formatter

## v3.2.0
- Added configuration to override debug logging for specific users

## v3.1.0
- Added `YetiLogger::TestHelper.expect_to_not_see_log_message[s]` for testing
  that given messages were not logged at the given log level.

## v3.0.0
- First public release
