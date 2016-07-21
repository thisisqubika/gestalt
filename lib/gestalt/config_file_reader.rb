require "json"

class ConfigFileReader

  # Reads given file
  #
  # @param [String]
  # @param [String]
  def self.read_config(filename, env)
    path = File.join(".", "config", "#{filename}.json")
    file = File.open(path)
    config_options = JSON.parse(File.read(file), symbolize_names: true)
    config_options[env]
  end
end
