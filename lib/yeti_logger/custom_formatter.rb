class YetiLogger::CustomFormatter
  # @param tags [Hash] - maps names of tags to procs that return their value
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
  # @param msg [String]
  def call(severity, time, progname, msg)
    timestamp = "#{Time.now.iso8601(3)}"
    pid = Process.pid
    msg = msg.inspect unless msg.is_a?(String)
    msg = "#{msg}\n" unless msg[-1] == ?\n
    log_str = "#{timestamp} pid=#{pid} "
    @tags.to_h.each do |k, v|
      tag_val = v.call
      if !tag_val.blank?
        log_str += "#{k}=#{tag_val} "
      end
    end

    log_str + "[#{severity}] - #{msg}"
  end
end

