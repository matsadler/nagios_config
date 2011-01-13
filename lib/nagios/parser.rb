require 'strscan'
require 'rubygems'
require 'events'

module Nagios
  class Parser
    attr_accessor :scanner
    include Events::Emitter
    
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
    
    def stream_parse(string)
      self.scanner = StringScanner.new(string)
      start
    end
    
    private
    def start
      finish || comment && start || whitespace && start ||
        trailing_comment && start || name && value && start ||
        definition && start ||
        (raise ParseError.new("unrecognised input"))
    end
    
    def comment
      line_start = scanner.beginning_of_line?
      comment = scanner.scan(/#.*(\n|\Z)/)
      if comment && line_start
        comment.slice!(0)
        comment.chomp!("\n")
        emit(:comment, comment)
      elsif comment
        raise ParseError.new("comment must be at start of line")
      end
      comment
    end
    
    def whitespace
      whitespace = scanner.scan(/([ \t]*\n|[ \t]+)/)
      if whitespace
        emit(:whitespace, whitespace)
      end
      whitespace
    end
    
    def name
      line_start = scanner.beginning_of_line?
      name = scanner.scan(/.+=/)
      if name && line_start
        name.chomp!("=")
        emit(:name, name)
      elsif name
        raise ParseError.new("name must be at start of line")
      end
      name
    end
    
    def value
      value = scanner.scan(/.+(\n|\Z)/)
      if value
        value.chomp!("\n")
        emit(:value, value)
      else
        raise ParseError.new("value expected")
      end
      value
    end
    
    def definition
      if scanner.skip(/define[ \t]/)
        emit(:begin_define)
        type
      end
    end
    
    def type
      type = scanner.scan(/[^;{]+[ \t]*\{/)
      if type
        type.strip!
        type.chomp!("{")
        type.strip!
        emit(:type, type)
        definition_body if newline
      else
        raise ParseError.new("type expected")
      end
    end
    
    def definition_body
      finish_definition || whitespace && definition_body ||
        comment && definition_body || trailing_comment && definition_body ||
        definition_name && definition_value && definition_body ||
        (raise ParseError.new("} expected"))
    end
    
    def definition_name
      name = scanner.scan(/[^\s;}]+/)
      if name
        name.strip!
        emit(:name, name)
      end
      name
    end
    
    def definition_value
      value = scanner.scan(/[ \t]+[^\s;}]+/)
      if value
        value.strip!
        emit(:value, value)
        newline
      else
        raise ParseError.new("value expected")
      end
      value
    end
    
    def finish_definition
      line_start = scanner.beginning_of_line?
      teminator = scanner.scan(/\}/)
      if teminator && line_start
        emit(:finish_define)
        true
      elsif teminator
        raise ParseError.new("} must be at start of line")
      end
    end
    
    def trailing_comment
      event = scanner.beginning_of_line? ? :comment : :trailing_comment
      comment = scanner.scan(/;.*\n/)
      if comment
        comment.chomp!("\n")
        comment.slice!(0)
        emit(event, comment)
      end
      comment
    end
    
    def finish
      scanner.eos?
    end
    
    def newline
      linebreak = scanner.skip(/[ \t]*\n/) || (whitespace || true) && trailing_comment
      if linebreak
        true
      else
        raise ParseError.new("newline expected")
      end
    end
    
  end
end