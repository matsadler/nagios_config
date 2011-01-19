module NagiosConfig
  
  class TrailingComment < Node
  end
  
  class Whitespace < Node
    node :trailing_comment, NagiosConfig::TrailingComment
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
    node :name, NagiosConfig::Name
    node :val, NagiosConfig::Value
    node :trailing_comment, NagiosConfig::TrailingComment
  end
  
  class Define < Node
    node :type, NagiosConfig::Type
    node :comment, NagiosConfig::Comment
    node :trailing_comment, NagiosConfig::TrailingComment
    nodes :whitespace, :whitespace, NagiosConfig::Whitespace
    nodes :variable, :variables, NagiosConfig::Variable
  end
  
  class Config < Node
    node :comment, NagiosConfig::Comment
    nodes :whitespace, :whitespace, NagiosConfig::Whitespace
    nodes :variable, :variables, NagiosConfig::Variable
    nodes :define, :defines, NagiosConfig::Define
  end
end