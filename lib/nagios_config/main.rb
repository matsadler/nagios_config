module NagiosConfig
  class Main
    attr_accessor :variables, :objects
    
    def initialize(variables={}, objects=[])
      self.variables = Hash[*variables.map {|k,v| [k.to_sym,v]}.flatten]
      self.objects = objects
    end
    
    def self.from_node(node)
      instance = new
      object_store = instance.objects
      node.nodes.each do |node|
        if node.is_a?(NagiosConfig::Variable)
          name = node.name.value
          value = node.val.value
          case instance[name]
          when nil
            instance[name] = value
          when Array
            instance[name].push(value)
          else
            instance[name] = [instance[name], value]
          end
        elsif node.is_a?(NagiosConfig::Define)
          NagiosConfig::Object.from_node(node, object_store)
        end
      end
      instance
    end
    
    def self.parse(io, include_comments=false)
      from_node(NagiosConfig::Parser.new(!include_comments).parse(io))
    end
    
    def [](name)
      variables[name.to_sym]
    end
    
    def []=(name, value)
      variables[name.to_sym] = value
    end
    
    def objects(of_type=nil)
      return @objects unless of_type
      of_type = of_type.to_sym
      objects.select {|obj| obj.type == of_type}
    end
    
    def ==(other)
      other.is_a?(self.class) && other.variables == variables &&
        other.objects == objects
    end
    
    def inspect
      "#<#{self.class.name}:#{object_id} @variables=#{variables.inspect}, " <<
      "@objects=#{objects.class.name}:#{objects.object_id}" <<
      "(#{objects.length} items)>"
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
    
  end
end