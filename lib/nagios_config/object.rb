module NagiosConfig
  class Object
    @@all = []
    attr_accessor :type, :own_variables, :objectspace, :parent, :cache_parent
    
    def initialize(type, variables={}, objectspace=@@all, cache_parent=false)
      self.type = type.to_sym
      self.own_variables = Hash[variables.map {|k,v| [k.to_sym,v]}]
      self.objectspace = objectspace
      self.cache_parent = cache_parent
    end
    
    def self.from_node(node, objectspace=@@all, cache_parent=false)
      instance = new(node.type.value, {}, objectspace, cache_parent)
      node.variables.each do |variable|
        instance[variable.name.value] = variable.val.value
      end
      instance
    end
    
    def self.of_type(type, objectspace=@@all)
      type = type.to_sym
      objectspace.select {|obj| obj.type == type}
    end
    
    def self.clear
      objectspace.clear
    end
    
    def self.objectspace
      @@all
    end
    
    def parent
      return @parent if cache_parent && @parent
      
      use = own_variables[:use]
      if use
        parent = self.class.of_type(type, objectspace).find do |other|
          other.own_variables[:name] == use
        end
        raise ParentNotFound.new("can't use #{use}") unless parent
        self.parent = parent if cache_parent
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
    
    def cache_parent=(value)
      @parent = nil unless value
      @cache_parent = value
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