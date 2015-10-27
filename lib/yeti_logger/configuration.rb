module YetiLogger

  module Configuration
    attr_accessor :logger

    def configure(&block)
      instance_eval &block
    end

  end

  extend Configuration

end