require 'strscan'
require 'stringio'
require 'rubygems'
require 'events'

module NagiosConfig
  class Parser
    attr_accessor :scanner, :state
    include Events::Emitter
    
    NEWLINE = "\n".freeze
    EQUALS = "=".freeze
    OPEN_BRACE = "{".freeze
    
    def initialize(ignore_comments=false)
      @state = :body
      @scanner = StringScanner.new("")
      @value_buffer = ""
      @ignore_comments = ignore_comments
    end
    
    def parse(io)
      root = NagiosConfig::Config.new
      current = root
      current_variable = nil
      on(:comment) do |comment|
        current.add_node(NagiosConfig::Comment.new(comment))
      end unless @ignore_comments
      on(:whitespace) do |whitespace|
        current.add_node(NagiosConfig::Whitespace.new(whitespace))
      end unless @ignore_comments
      on(:trailing_comment) do |comment|
        current.nodes.last.add_node(NagiosConfig::TrailingComment.new(comment))
      end unless @ignore_comments
      on(:name) do |name|
        current_variable = NagiosConfig::Variable.new
        current_variable.add_node(NagiosConfig::Name.new(name))
        current.add_node(current_variable)
      end
      on(:value) do |value|
        current_variable.add_node(NagiosConfig::Value.new(value))
      end
      on(:begin_define) do
        current = NagiosConfig::Define.new
        root.add_node(current)
      end
      on(:type) do |type|
        current.add_node(NagiosConfig::Type.new(type))
      end
      on(:finish_define) do
        current = root
      end
      stream_parse(io)
      root
    end
    
    def stream_parse(io)
      io = StringIO.new(io) unless io.respond_to?(:read)
      until io.eof?
        self << io.read(1024)
      end
    end
    
    def <<(string)
      @scanner << string
      @state = send(@state)
    end
    
    private
    def body
      empty_line || leading_whitespace || comment || definition || name || :body
    end
    alias start body
    
    def empty_line
      whitespace = @scanner.scan(/[ \t]*\n/)
      if whitespace
        emit(:whitespace, whitespace) unless @ignore_comments
        @in_define ? definition_body : body
      elsif @in_define && whitespace = @scanner.scan(/[ \t]*(?=;)/) && trailing_comment
        emit(:whitespace, whitespace) unless @ignore_comments
        definition_body
      end
    end
    
    def leading_whitespace
      if @scanner.skip(/[ \t]+[^\s]/)
        raise ParseError.new("leading whitespace not allowed")
      end
    end
    
    def comment
      comment = @scanner.scan(/[ \t]*#[^\n]*\n/)
      if comment
        if !@ignore_comments
          comment.lstrip!
          comment.slice!(0)
          comment.chomp!(NEWLINE)
          emit(:comment, comment)
        end
        @in_define ? definition_body : body
      elsif @scanner.check(/#/)
        :comment
      end
    end
    
    def name
      name = @scanner.scan(/[^\s=]+=/)
      if name
        name.chomp!(EQUALS)
        emit(:name, name)
        value
      elsif @scanner.skip(/[^\n]+\n/)
        raise ParseError.new("expected variable definition")
      elsif @scanner.check(/[^\s]+/) && !@scanner.check(/d(e(f(i(n(e?))?)?)?)?\Z/)
        :name
      end
    end
    
    def value
      value = @scanner.scan(/[^\n]*\n/)
      if value
        value = @value_buffer + value
        value.chomp!(NEWLINE)
        raise ParseError.new("value expected") if value.empty?
        emit(:value, value)
        @value_buffer = ""
        body
      elsif value = @scanner.scan(/.+/)
        @value_buffer << value
        :value
      else
        :value
      end
    end
    
    def definition
      if @scanner.skip(/define[ \t]/)
        emit(:begin_define)
        @in_define = true
        type
      end
    end
    
    def type
      type = @scanner.scan(/[^;{]+[ \t]*\{[ \t]*\n/)
      if type
        type.strip!
        type.chomp!(OPEN_BRACE)
        type.strip!
        emit(:type, type)
        definition_body
      elsif @scanner.check(/([^;{]+[ \t]*(\{[ \t]*)?)?\Z/)
        :type
      else
        raise ParseError.new("type expected")
      end
    end
    
    def definition_body
      finish_definition || empty_line || comment || definition_name || :definition_body
    end
    
    def definition_name
      name = @scanner.scan(/[ \t]*[^\s;#]+[ \t]+/)
      if name
        name.strip!
        emit(:name, name)
        definition_value
      elsif @scanner.check(/[ \t]*[^\s#;}]+\Z/)
        :definition_name
      elsif @scanner.skip(/[ \t]*[^\s#;]+\n/)
        raise ParseError.new("value expected")
      end
    end
    
    def definition_value
      value = @scanner.scan(/[^\n;#]*(?=(\n|;))/)
      if value
        value = @value_buffer + value
        value.strip!
        raise ParseError.new("value expected") if value.empty?
        emit(:value, value)
        @value_buffer = ""
        after_value
      elsif value = @scanner.scan(/[^\n;#]+/)
        @value_buffer << value
        :definition_value
      else
        :definition_value
      end
    end
    
    def after_value
      if @scanner.skip(/[ \t]*\n/) || trailing_comment
        definition_body
      else
        :after_value
      end
    end
    
    def finish_definition
      if @scanner.skip(/[ \t]*\}[ \t]*\n/)
        emit(:finish_define)
        @in_define = false
        body
      end
    end
    
    def trailing_comment
      trailing_comment = @scanner.scan(/[ \t]*;[^\n]*\n/)
      if trailing_comment && !@ignore_comments
        trailing_comment.strip!
        trailing_comment.chomp!(NEWLINE)
        trailing_comment.slice!(0)
        emit(:trailing_comment, trailing_comment)
      end
      trailing_comment
    end
    
  end
end