base = File.expand_path(File.dirname(__FILE__) + '/../lib')
require base + '/nagios_config'
require 'test/unit'

class FormaterTest < Test::Unit::TestCase
  
  def setup
    @builder = NagiosConfig::Builder.new
    @formater = NagiosConfig::Formater.new
  end
  
  def test_comment
    @builder.comment("foo")
    
    assert_equal("#foo\n", @formater.format(@builder.root))
  end
  
  def test_variable
    @builder.key = "value"
    
    assert_equal("key=value\n", @formater.format(@builder.root))
  end
  
  def test_empty_define
    @builder.define("host") do |host|
    end
    
    assert_equal("define host {\n}\n", @formater.format(@builder.root))
  end
  
  def test_define
    @builder.define("host") do |host|
      host.name = "arther"
    end
    
    assert_equal("define host {\n  name  arther\n}\n", @formater.format(@builder.root))
  end
  
  def test_whitespace
    root = NagiosConfig::Config.new
    root.add_node(NagiosConfig::Whitespace.new("  	\n"))
    
    assert_equal("  	\n", @formater.format(root))
  end
  
  def test_trailing_comment
    @builder.define("host") do |host|
      host.name = "ford"
      host.name.comment("prefect")
    end
    
    assert_equal("define host {\n  name  ford  ;prefect\n}\n", @formater.format(@builder.root))
  end
  
end