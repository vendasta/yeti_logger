# CustomFormatter is a custom Rails log formatter.
# It has support for adding arbitrary tags to every log created by the Rails logger.
# Tag values are generated at log creation time.
class YetiLogger::CustomFormatter
  # @param tags [Hash] - maps names of tags to procs that return their value.
  def initialize(tags = {})
    super()
    @tags = tags
  end

  # @param tags [Hash] - maps names of tags to procs that return their value
  def add_tags(tags)
    @tags.merge!(tags)
  end

  # @param severity [String]
  # @param time [Time] unused
  # @param progname [String] unused
  # @param msg [String] - log body
  def call(severity, time, progname, msg)
    timestamp = %w(production staging).include?(ENV['RAILS_ENV']) ? "" : "#{Time.now.iso8601(3)} "
    pid = Process.pid
    msg = msg.inspect unless msg.is_a?(String)
    msg = "#{msg}\n" unless msg[-1] == ?\n
    log_str = "#{timestamp}pid=#{pid}"

    tag_str = @tags.map { |k, v|
      value = v.call
      "#{k}=#{value}" unless value.to_s.empty?
    }.compact.join(' ')

    "#{log_str}#{tag_str.empty? ? '' : ' ' + tag_str} [#{severity}] - #{msg}"
  end
end
