module Nagios
  class Formater
    attr_accessor :buffer, :in_define, :define_indent, :define_name_width, :define_variable_width
    
    def initialize
      self.buffer = ""
      self.define_indent = 2
      self.define_name_width = 2
      self.define_variable_width = 2
    end
    
    def format(root)
      root.whitespace.each do |whitespace|
        if whitespace.value !~ /\n/
          before = root.before(whitespace)
          before.trailing_comment = whitespace.trailing_comment if before.respond_to?(:trailing_comment)
          root.remove_node(whitespace)
        end
      end
      root.nodes.each do |node|
        op = "format_#{node.class.name.sub(/^Nagios::/, "").gsub(/::/, "_")}"
        send(op, node)
      end
      buffer
    end
    alias format_Config format
    
    def format_Comment(comment)
      buffer << comment.value.split(/\n/).map do |comment|
        "##{comment}\n"
      end.join
    end
    
    def format_Whitespace(whitespace)
      buffer << "\n"
    end
    
    def format_Variable(variable)
      if in_define
        format = "#{" " * define_indent}%-#{define_name_width}s%s\n"
      else
        format = "%s=%s\n"
      end
      var_string = format % [variable.name.value, variable.val.value]
      if variable.trailing_comment
        var_string = "%-#{define_variable_width}s;%s\n" % [var_string.chomp("\n"), variable.trailing_comment.value]
      end
      buffer << var_string
    end
    
    def format_Define(define)
      buffer << "define "
      name_width = define.variables.map(&:name).map(&:value).map(&:length).max
      value_width = define.variables.map(&:val).map(&:value).map(&:length).max
      variable_width = define_indent + define_name_width + name_width + value_width
      
      self.define_name_width += name_width
      self.define_variable_width += variable_width
      self.in_define = true
      
      format(define)
      
      self.in_define = false
      self.define_variable_width -= variable_width
      self.define_name_width -= name_width
      
      buffer << "}\n"
    end
    
    def format_Type(type)
      buffer << "#{type.value} {\n"
    end
    
  end
end