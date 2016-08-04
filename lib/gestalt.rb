require "gestalt/version"
require 'gestalt/store'
require 'json'
require 'yaml'

module Gestalt
  class RootKeyNotFoundError < StandardError; end
  class UnsupportedExtensionError < StandardError; end

  # Default configuration values
  CONFIG_PATH = './config/*'
  IGNORE_UNSUPPORTED_EXTENSIONS = true

  def self.included(base)
    _gestalt_init(base)
  end

  def self.extended(base)
    _gestalt_init(base)
  end

  attr_accessor :configuration
  alias :config :configuration

  # Loads a set of configuration files from a path specified in the gem configuration.
  #
  # @example load a set of JSON/YAML files located at "~/config" with "test" as their root key
  #   object.gestalt.config_path = '~/config' # Contains file ~/config/test_1.json
  #   object.load("test")
  #   object.config.file_1 # Returns the contents of the file
  # @example load a set of JSON/YAML files with "test" as their root key and call a block after it ends
  #   object.load("test") do
  #     puts "Finished loading!"
  #   end
  #
  # @param key [String|Symbol] a key name representing the root key in all the configuration files
  # @raise [UnsupportedExtensionError] if a file has an unsupported  extension and 'ignore_unsupported_extensions' is not set
  # @raise [RootKeyNotFoundError] if there's a file whose root key is not the one passed as a parameter
  # @yield any passed block at the end of the loading process
  def parse_configuration(key = nil)
    @configuration = Store.new
    string_key = key.to_s

    files = Dir["#{_gestalt_no_trailing_slash(_gestalt.config_path)}/*"]
    files.each do |file|
      begin
        content = _gestalt_parse_file(file)
      rescue UnsupportedExtensionError => e
        raise e unless _gestalt.ignore_unsupported_extensions
      else
        name_without_extension = File.basename(file).gsub(/\.\w+/, '')

        if key.nil?
          @configuration[name_without_extension] = content
        elsif content&.has_key?(string_key)
          @configuration[name_without_extension] = content[string_key]
        else
          raise RootKeyNotFoundError, "Key '#{string_key}' not found at root of #{file}"
        end
      end
    end

    yield if block_given?
  end

  private

  def self._gestalt_init(base)
    # Initialize with default values
    # Make sure to change these AFTER the module has been included/extended
    config = Store.new({}, 'gestalt')
    config.config_path = CONFIG_PATH
    config.ignore_unsupported_extensions = IGNORE_UNSUPPORTED_EXTENSIONS

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
    self.respond_to?(:gestalt) ? self.gestalt : self.class.gestalt
  end

  def _gestalt_parse_file(file)
    extension = File.extname(file)
    file_pointer = File.open(file)

    case extension
    when '.json'
      JSON.load(file_pointer)
    when '.yml', '.yaml'
      YAML.load(file_pointer)
    else
      raise UnsupportedExtensionError, "Extension '#{extension}' is not supported"
    end
  end

  def _gestalt_no_trailing_slash(path)
    path.gsub(/\/$/, '')
  end

end
