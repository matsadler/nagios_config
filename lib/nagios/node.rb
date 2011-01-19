module Nagios
  class Node
    attr_accessor :nodes, :value
    
    def initialize(value=nil)
      self.value = value
      self.nodes = []
    end
    
    def self.allow(*node_types)
      if node_types.any?
        allow.push(*node_types)
      else
        @allowed_node_types ||= []
      end
    end
    
    def self.nodes(name, plural="#{name}s", klass=generate_node_type(name))
      if plural
        define_method(plural) do
          nodes.select {|n| n.is_a?(klass)}
        end
        alias_method :"add_#{name}", :add_node
      else
        define_method(name) do
          nodes.find {|n| n.is_a?(klass)}
        end
        define_method("#{name}=") do |value|
          remove_node(name)
          add_node(value) if value
        end
      end
      allow(klass)
      yield klass if block_given?
    end
    
    def self.node(name, klass=generate_node_type(name))
      nodes(name, nil, klass)
    end
    
    def self.generate_node_type(name, klass=Nagios::Node)
      subclass = Class.new(klass)
      const_set(name.to_s.capitalize, subclass)
      subclass
    end
    
    def allow?(node)
      self.class.allow.include?(node.class)
    end
    
    def add_node(node)
      raise "node type #{node.class} not allowed in #{self.class}" unless allow?(node)
      nodes << node
      self
    end
    
    def remove_node(node)
      nodes.delete(node)
      self
    end
    
    def after(node)
      nodes[nodes.index(node) + 1]
    end
    
    def before(node)
      index = nodes.index(node) - 1
      if index >= 0
        nodes[index]
      end
    end
    
    def insert_before(position_node, node)
      nodes.insert(nodes.index(position_node), node)
    end
    
    def insert_after(position_node, node)
      nodes.insert(nodes.index(position_node) + 1, node)
    end
    
  end
end