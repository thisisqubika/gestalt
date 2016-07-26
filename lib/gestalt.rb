require "gestalt/version"
require 'gestalt/store'
require 'json'
require 'yaml'

require 'byebug'

module Gestalt
  class UndefinedEnvironmentError < StandardError; end
  class UnsupportedExtensionError < StandardError; end
  
  DEFAULT_CONFIG_PATH = '/Users/mig/Workspace/gestalt/config/*'

  def self.included(base)
    _gestalt_init(base)
  end

  def self.extended(base)
    _gestalt_init(base)
  end

  attr_accessor :configuration
  alias :config :configuration
  
  def load_environment(env)
    @configuration = Store.new("root")
    env_to_s = env.to_s

    files = Dir["#{_gestalt_no_trailing_slash(_gestalt.config_path)}/*"]

    files.each do |file|
      name_without_extension = File.basename(file).gsub(/\.\w+/, '')
      extension = File.extname(file)
      file_pointer = File.open(file)

      case extension
      when '.json'
        content = JSON.load(file_pointer)
      when '.yml', '.yaml'
        content = YAML.load(file_pointer)
      else
        raise UnsupportedExtensionError, "Extension '#{extension}' is not supported"
      end
      
      if content && content.has_key?(env_to_s)
        @configuration[name_without_extension] = content[env_to_s]
      else
        raise UndefinedEnvironmentError, "Environment '#{env_to_s}' not found in #{file}"
      end
    end
  end

  private

  def self._gestalt_init(base)
    # Initialize with default values
    # Make sure to change these AFTER the module has been included/extended
    config = Store.new('gestalt', {})
    config.config_path = DEFAULT_CONFIG_PATH
    
    # "config" is only exposed through this closure
    base.define_singleton_method(:gestalt) do |&block|
      if block
        block.call(config)
      else
        config
      end
    end
  end

  def _gestalt
    self.class.gestalt
  end

  def _gestalt_no_trailing_slash(path)
    path.gsub(/\/$/, '')
  end

end
