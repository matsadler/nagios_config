module NagiosConfig
  class Formater
    attr_accessor :buffer, :in_define, :define_indent, :define_name_width, :define_variable_width
    
    def initialize(buffer="")
      self.buffer = buffer
      self.define_indent = 2
      self.define_name_width = 2
      self.define_variable_width = 2
    end
    
    def format(root)
      root.nodes.each do |node|
        op = "format_#{node.class.name.sub(/^NagiosConfig::/, "").gsub(/::/, "_")}"
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
      buffer << whitespace.value
    end
    
    def format_Variable(variable)
      if in_define
        format = "#{" " * define_indent}%-#{define_name_width}s%s"
      else
        format = "%s=%s"
      end
      var_string = format % [variable.name.value, variable.val.value]
      if variable.trailing_comment
        var_string = "%-#{define_variable_width}s;%s" % [var_string, variable.trailing_comment.value]
      end
      buffer << var_string << "\n"
    end
    
    def format_Define(define)
      buffer << "define "
      name_width = define.variables.map(&:name).map(&:value).map(&:length).max || 0
      value_width = define.variables.map(&:val).map(&:value).map(&:length).max || 0
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