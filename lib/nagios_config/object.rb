module NagiosConfig
  class Object
    @@all = []
    @@template_cache = {}
    attr_accessor :type, :own_variables, :objectspace, :parent
    
    def initialize(type, variables={}, objectspace=@@all)
      self.type = type.to_sym
      self.own_variables = Hash[*variables.map {|k,v| [k.to_sym,v]}.flatten]
      self.objectspace = objectspace
    end
    
    def self.from_node(node, objectspace=@@all)
      instance = new(node.type.value, {}, objectspace)
      node.variables.each do |variable|
        instance[variable.name.value] = variable.val.value
      end
      instance
    end
    
    def self.find_template(type, name, objectspace=@@all)
      type = type.to_sym
      name = name.to_s
      key = [type, name, objectspace.object_id]
      cached = @@template_cache[key]
      
      if cached && cached.type == type && cached.name == name
        cached
      else
        @@template_cache[key] = objectspace.find do |obj|
          obj.type == type && obj.name == name
        end
      end
    end
    
    def self.clear_cache
      @@template_cache.clear
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
        parent = self.class.find_template(type, use, objectspace)
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