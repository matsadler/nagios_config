module NagiosConfig
  
  # Usage:
  #   conf = NagiosConfig::Builder.new
  #   
  #   conf.foo = "bar"
  #   conf.define("test") do |test|
  #     test.a = "b"
  #     test.a.comment("foo")
  #   end
  #   
  #   puts conf
  class Builder
    attr_accessor :root
    
    def initialize(root=NagiosConfig::Config.new)
      self.root = root
    end
    
    def [](name)
      var = get_variable_named(name)
      if var
        extend(var.val.value, var)
      end
    end
    
    def []=(name, value)
      set_variable_named(name, value)
      value
    end
    
    def define(type)
      raise "can't define in a define" if root.is_a?(NagiosConfig::Define)
      define = NagiosConfig::Define.new
      define.add_node(NagiosConfig::Type.new(type.to_s))
      root.add_node(define)
      yield self.class.new(define)
      define
    end
    
    def break
      root.add_node(NagiosConfig::Whitespace.new("\n"))
    end
    
    def comment(string)
      root.add_node(NagiosConfig::Comment.new(string))
    end
    
    def to_s
      NagiosConfig::Formater.new.format(root)
    end
    
    def method_missing(name, *args)
      if name.to_s =~ /=$/ && args.length == 1
        self[name.to_s.chomp("=")] = args.first
      elsif args.empty?
        self[name]
      else
        super
      end
    end
    
    private
    def get_variable_named(name)
      root.nodes.find do |node|
        node.is_a?(NagiosConfig::Variable) && node.name.value == name.to_s
      end
    end
    
    def set_variable_named(name, value)
      var = get_variable_named(name)
      if !var && !value.nil?
        var = NagiosConfig::Variable.new
        var.add_node(NagiosConfig::Name.new(name))
        var.add_node(NagiosConfig::Value.new)
        root.add_node(var)
      end
      if value.nil?
        root.remove_node(var)
      elsif value == true
        var.val.value = "1"
      elsif value == false
        var.val.value = "0"
      else
        var.val.value = value.to_s
      end
      var
    end
    
    def extend(value, parent)
      metaclass = class << value; self; end
      metaclass.send(:define_method, :comment) do |string|
        parent.add_node(NagiosConfig::TrailingComment.new(string))
      end
      value
    end
    
    
  end
end