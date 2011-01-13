module Nagios
  
  class TrailingComment < Node
  end
  
  class Whitespace < Node
    node :trailing_comment, Nagios::TrailingComment
  end
  
  class Comment < Node
  end
  
  class Type < Node
  end
  
  class Name < Node
  end
  
  class Value < Node
  end
  
  class Variable < Node
    node :name, Nagios::Name
    node :val, Nagios::Value
    node :trailing_comment, Nagios::TrailingComment
  end
  
  class Define < Node
    node :type, Nagios::Type
    node :comment, Nagios::Comment
    node :trailing_comment, Nagios::TrailingComment
    nodes :whitespace, :whitespace, Nagios::Whitespace
    nodes :variable, :variables, Nagios::Variable
  end
  
  class Config < Node
    node :comment, Nagios::Comment
    nodes :whitespace, :whitespace, Nagios::Whitespace
    nodes :variable, :variables, Nagios::Variable
    nodes :define, :defines, Nagios::Define
  end
end