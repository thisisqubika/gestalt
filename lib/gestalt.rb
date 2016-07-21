require "gestalt/version"
require_relative "gestalt/config_store"
require_relative "gestalt/config_file_reader"

module Gestalt

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    attr_accessor :config_files

    def load!(env = nil)
      ConfigStore.setup!(env)
      Array(config_files).each do |filename|
        ConfigStore.config[filename] = ConfigFileReader.read_config(filename.to_s, ConfigStore.config[:env])
      end
    end

    def config
      ConfigStore.config
    end
  end
end
