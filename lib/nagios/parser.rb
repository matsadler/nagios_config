require 'strscan'
require 'rubygems'
require 'events'

module Nagios
  class Parser
    attr_accessor :scanner, :state, :in_define
    include Events::Emitter
    
    def initialize
      @state = :body
      self.scanner = StringScanner.new("")
    end
    
    def parse(string)
      root = Nagios::Config.new
      current_define = nil
      current_variable = nil
      on(:comment) do |comment|
        (current_define || root).add_node(Nagios::Comment.new(comment))
      end
      on(:whitespace) do |whitespace|
        (current_define || root).add_node(Nagios::Whitespace.new(whitespace))
      end
      on(:trailing_comment) do |comment|
        (current_define || root).nodes.last.add_node(Nagios::TrailingComment.new(comment))
      end
      on(:name) do |name|
        current_variable = Nagios::Variable.new
        current_variable.add_node(Nagios::Name.new(name))
        (current_define || root).add_node(current_variable)
      end
      on(:value) do |value|
        current_variable.add_node(Nagios::Value.new(value))
        current_variable = nil
      end
      on(:begin_define) do
        current_define = Nagios::Define.new
        root.add_node(current_define)
      end
      on(:type) do |type|
        current_define.add_node(Nagios::Type.new(type))
      end
      on(:finish_define) do
        current_define = nil
      end
      stream_parse(string)
      root
    end
    
    def stream_parse(file_or_string)
      file_or_string.each_line do |line|
        self << line
      end
    end
    
    def <<(string)
      scanner << string
      self.state = send(state)
    end
    
    private
    def body
      empty_line || leading_whitespace || comment || definition || name || :body
    end
    alias start body
    
    def empty_line
      whitespace = scanner.scan(/[ \t]*\n/)
      if whitespace
        emit(:whitespace, whitespace)
        in_define ? definition_body : body
      end
    end
    
    def leading_whitespace
      if scanner.scan(/[ \t]/)
        raise ParseError.new("leading whitespace not allowed")
      end
    end
    
    def comment
      comment = scanner.scan(/#.*(\n|\Z)/)
      if comment
        comment.slice!(0)
        comment.chomp!("\n")
        emit(:comment, comment)
        in_define ? definition_body : body
      elsif scanner.check(/#/)
        :comment
      end
    end
    
    def name
      name = scanner.scan(/.+=/)
      if name
        name.chomp!("=")
        emit(:name, name)
        value
      elsif scanner.scan(/.+(\n|\Z)/)
        raise ParseError.new("expected variable definition")
      elsif scanner.check(/.+/) && !scanner.check(/d(e(f(i(n(e?))?)?)?)?\Z/)
        :name
      end
    end
    
    def value
      value = scanner.scan(/.+(\n|\Z)/)
      if value
        value.chomp!("\n")
        emit(:value, value)
        body
      elsif scanner.scan(/\n|\Z/)
        raise ParseError.new("value expected")
      else
        :value
      end
    end
    
    def definition
      if scanner.skip(/define[ \t]/)
        emit(:begin_define)
        self.in_define = true
        type
      end
    end
    
    def type
      type = scanner.scan(/[^;{]+[ \t]*\{[ \t]*\n/)
      if type
        type.strip!
        type.chomp!("{")
        type.strip!
        emit(:type, type)
        definition_body
      elsif scanner.check(/[^;{]+[ \t]*(\{[ \t]*)?\Z/)
        :type
      else
        raise ParseError.new("type expected")
      end
    end
    
    def definition_body
      finish_definition || empty_line || comment || definition_name || :definition_body
    end
    
    def definition_name
      name = scanner.scan(/[ \t]*[^\s;]+[ \t]+/)
      if name
        name.strip!
        emit(:name, name)
        definition_value
      elsif scanner.check(/[ \t]*[^\s;]+\Z/)
        :definition_name
      elsif scanner.scan(/[ \t]*[^\s;]+\n/)
        raise ParseError.new("value expected")
      end
    end
    
    def definition_value
      value = scanner.scan(/[ \t]*[^\s;]+(?=(\s|;))/)
      if value
        value.strip!
        emit(:value, value)
        after_value
      elsif scanner.check(/[ \t]*[^\s;]+/)
        :definition_value
      elsif scanner.scan(/[ \t]*(;|\n|\Z)/)
        raise ParseError.new("value expected")
      end
    end
    
    def after_value
      if scanner.skip(/[ \t]*\n/) || trailing_comment
        definition_body
      else
        :after_value
      end
    end
    
    def finish_definition
      if scanner.scan(/[ \t]*\}[ \t]*(\n|\Z)/)
        emit(:finish_define)
        self.in_define = false
        body
      end
    end
    
    def trailing_comment
      trailing_comment = scanner.scan(/[ \t]*;.*\n/)
      if trailing_comment
        trailing_comment.strip!
        trailing_comment.chomp!("\n")
        trailing_comment.slice!(0)
        emit(:trailing_comment, trailing_comment)
      end
      trailing_comment
    end
    
  end
end