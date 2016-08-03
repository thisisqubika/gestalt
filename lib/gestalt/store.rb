module Gestalt
  class KeyNotFoundError < StandardError; end

  class Store
    ROOT = 'root'

    def initialize(configuration = {}, key = nil, parent = nil)
      @key = key
      @configuration = configuration
      @parent = parent
    end

    # Returns the value stored into the passed key
    #
    # @param key an object representing a key
    # @return [Store] an inner level of settings stored in the passed key
    # @return a non-hash object stored in the passed key
    # @raise [KeyNotFoundError] if key is not found
    def [](key)
      if @configuration.has_key?(key)
        value = @configuration[key]
        value.is_a?(Hash) ? Store.new(value, key, self) : value
      else
        raise KeyNotFoundError, "Key #{key.inspect} is not present at #{breadcrumbs}"
      end
    end

    # Stores a value in the passed key
    #
    # @param key the target key
    # @param value the value to store
    def []=(key, value)
      @configuration[key] = value
    end

    def breadcrumbs
      if @parent
        "#{@parent.breadcrumbs} -> #{@key.inspect}"
      else
        @key&.inspect || ROOT.inspect
      end
    end

    def method_missing(name, *args, &block)
      stringified_name = name.to_s

      if stringified_name[-1] == '='
        name_without_assignment = stringified_name[0..-2]
        self[name_without_assignment] = args.first
      elsif args.empty?
        if block_given? || !block.nil?
          self[stringified_name] = block.call
        else
          self[stringified_name]
        end
      else
        super
      end
    end

  end
end
