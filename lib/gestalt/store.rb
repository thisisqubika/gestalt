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
    def [](key)
      value = @configuration[key]
      value.is_a?(Hash) ? Store.new(value, key, self) : value
    end

    # Stores a value in the passed key
    #
    # @param key the target key
    # @param value the value to store
    def []=(key, value)
      @configuration[key] = value
    end

    # Returns a string representation of the route to the current store
    #
    # @example three levels of breadcrumbs
    #   store.breadcrumbs # => "root" -> "2ndlevel" -> "current"
    #
    # @return [String] a string representation of the route
    def breadcrumbs
      if @parent
        "#{@parent.breadcrumbs} -> #{@key.inspect}"
      else
        @key&.inspect || ROOT.inspect
      end
    end

    # Returns a copy of the configuration hash instance
    #
    # @return [Hash] a copy of the configuration hash instance
    def to_hash
      @configuration.dup
    end

    private

    def method_missing(name, *args, &block)
      stringified_name = name.to_s

      if stringified_name[-1] == '='
        name_without_assignment = stringified_name[0..-2]
        self[name_without_assignment] = args.first
      elsif args.empty?
        if block_given? || !block.nil?
          self[stringified_name] = block.call
        elsif @configuration.has_key?(stringified_name)
          self[stringified_name]
        else
          raise KeyNotFoundError, "Key #{stringified_name.inspect} is not present at #{breadcrumbs}"
        end
      else
        super
      end
    end

  end
end
