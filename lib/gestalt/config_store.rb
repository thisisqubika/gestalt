class ConfigStore
  class << self
    attr_accessor :config

    def setup!(env = nil)
      self.config = {}

      if env
        self.config[:env] = env
      elsif config[:env].nil?
        self.config[:env] = :development
      end
    end
  end
end
