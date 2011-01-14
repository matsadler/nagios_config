require 'strscan'
require 'stringio'
require 'rubygems'
require 'events'

module Nagios
  class Parser
    attr_accessor :scanner, :state, :in_define, :value_buffer
    include Events::Emitter
    
    def initialize
      @state = :body
      self.scanner = StringScanner.new("")
      self.value_buffer = ""
    end
    
    def parse(io)
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
      stream_parse(io)
      root
    end
    
    def stream_parse(io)
      io = StringIO.new(io) unless io.respond_to?(:read)
      until io.eof?
        self << io.read(1024 * 16)
      end
    end
    
    def <<(string)
      scanner.string.replace(scanner.rest)
      scanner.reset
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
      elsif in_define && whitespace = scanner.scan(/[ \t]*(?=;)/) && trailing_comment
        emit(:whitespace, whitespace)
        definition_body
      end
    end
    
    def leading_whitespace
      if scanner.scan(/[ \t]+[^\s]/)
        raise ParseError.new("leading whitespace not allowed")
      end
    end
    
    def comment
      comment = scanner.scan(/[ \t]*#.*(\n)/)
      if comment
        comment.lstrip!
        comment.slice!(0)
        comment.chomp!("\n")
        emit(:comment, comment)
        in_define ? definition_body : body
      elsif scanner.check(/#/)
        :comment
      end
    end
    
    def name
      name = scanner.scan(/[^\s=]+=/)
      if name
        name.chomp!("=")
        emit(:name, name)
        value
      elsif scanner.scan(/.+\n/)
        raise ParseError.new("expected variable definition")
      elsif scanner.check(/[^\s]+/) && !scanner.check(/d(e(f(i(n(e?))?)?)?)?\Z/)
        :name
      end
    end
    
    def value
      value = scanner.scan(/.+\n/)
      if value
        value = value_buffer + value
        value.chomp!("\n")
        raise ParseError.new("value expected") if value.empty?
        emit(:value, value)
        self.value_buffer = ""
        body
      elsif value = scanner.scan(/.+/)
        value_buffer << value
        :value
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
      elsif scanner.check(/([^;{]+[ \t]*(\{[ \t]*)?)?\Z/)
        :type
      else
        raise ParseError.new("type expected")
      end
    end
    
    def definition_body
      finish_definition || empty_line || comment || definition_name || :definition_body
    end
    
    def definition_name
      name = scanner.scan(/[ \t]*[^\s;#]+[ \t]+/)
      if name
        name.strip!
        emit(:name, name)
        definition_value
      elsif scanner.check(/[ \t]*[^\s#;}]+\Z/)
        :definition_name
      elsif scanner.scan(/[ \t]*[^\s#;]+\n/)
        raise ParseError.new("value expected")
      end
    end
    
    def definition_value
      value = scanner.scan(/[^\n;#]*(?=(\n|;))/)
      if value
        value = value_buffer + value
        value.strip!
        raise ParseError.new("value expected") if value.empty?
        emit(:value, value)
        self.value_buffer = ""
        after_value
      elsif value = scanner.scan(/[^\n;#]+/)
        value_buffer << value
        :definition_value
      else
        :definition_value
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
      if scanner.scan(/[ \t]*\}[ \t]*\n/)
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