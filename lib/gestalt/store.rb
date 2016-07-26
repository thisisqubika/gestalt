module Gestalt
  class KeyNotFoundError < StandardError; end

  class Store
    def initialize(key, configuration = {}, parent = nil)
      @key = key
      @configuration = configuration
      @parent = parent
    end

    def [](key)
      if @configuration.has_key?(key)
        value = @configuration[key]
        value.is_a?(Hash) ? Store.new(key, value, self) : value
      else
        raise KeyNotFoundError, "Key #{key.inspect} is not present at #{breadcrumbs}"
      end
    end

    def []=(key, value)
      @configuration[key] = value
    end

    def breadcrumbs
      if @parent
        "#{@parent.breadcrumbs} -> #{@key.inspect}"
      else
        "#{@key.inspect}"
      end
    end

    def method_missing(name, *args, &block)
      stringified_name = name.to_s

      if stringified_name.match(/\w+=$/) && args.length == 1
        name_without_assignment = stringified_name.gsub('=', '')
        self[name_without_assignment] = args.first
      elsif args.empty? && block.nil? && !block_given?
        self[stringified_name]
      elsif @configuration.respond_to?(name)
        @configuration.send(name, *args, &block)
      else
          super
      end
    end

  end
end
