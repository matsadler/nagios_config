module NagiosConfig
  class Object
    @@all = []
    @@find_cache = {}
    attr_accessor :type, :own_variables, :objectspace, :parent
    
    def initialize(type, variables={}, objectspace=@@all)
      self.type = type.to_sym
      self.own_variables = Hash[variables.map {|k,v| [k.to_sym,v]}]
      self.objectspace = objectspace
    end
    
    def self.from_node(node, objectspace=@@all)
      instance = new(node.type.value, {}, objectspace)
      node.variables.each do |variable|
        instance[variable.name.value] = variable.val.value
      end
      instance
    end
    
    def self.find(type, query, objectspace=@@all)
      key = [type, query.sort, objectspace.object_id]
      result = @@find_cache[key]
      return result if result && result.objectspace == objectspace &&
        query.inject(true) do |memo, (key, value)|
          memo && result[key.to_sym] == value
        end
      
      @@find_cache[key] = objectspace.find do |obj|
        obj.type == type && query.inject(true) do |memo, (key, value)|
          memo && obj[key.to_sym] == value
        end
      end
    end
    
    def self.clear_cache
      @@find_cache.clear
    end
    
    def self.clear
      objectspace.clear
      clear_cache
      nil
    end
    
    def self.objectspace
      @@all
    end
    
    def parent
      use = own_variables[:use]
      if use
        parent = self.class.find(type, {:name => use}, objectspace)
        raise ParentNotFound.new("can't use #{use}") unless parent
        parent
      end
    end
    
    def [](name)
      name = name.to_sym
      result = own_variables[name]
      if result
        result
      elsif own_variables[:use] && name != :name && name != :register
        parent[name]
      end
    end
    
    def []=(name, value)
      own_variables[name.to_sym] = value
    end
    
    def ==(other)
      other.is_a?(self.class) && other.type == type &&
        other.variables == variables
    end
    
    def objectspace=(value)
      @objectspace.delete(self) if @objectspace
      value.push(self) if value
      @objectspace = value
    end
    
    def inspect
      "#<#{self.class.name}:#{object_id} @type=#{type}, " <<
      "@objectspace=#{objectspace.class.name}:#{objectspace.object_id}" <<
      "(#{objectspace.length} items), @own_variables=#{own_variables.inspect}>"
    end
    
    def method_missing(name, *args)
      if name.to_s !~ /=$/ && args.empty?
        self[name.to_sym]
      elsif name.to_s =~ /=$/ && args.length == 1
        self[name.to_s.chomp("=").to_sym] = args.first
      else
        super
      end
    end
    
    protected
    def variables
      parent_variables = parent.variables if parent
      if parent_variables
        parent_variables.delete(:name)
        parent_variables.delete(:register)
        variables = parent_variables.merge(own_variables)
        variables.delete(:use)
        variables
      else
        own_variables.dup
      end
    end
    
  end
end