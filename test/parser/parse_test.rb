base = File.expand_path(File.dirname(__FILE__) + '/../../lib')
require base + '/nagios'
require 'test/unit'

class ParseTest < Test::Unit::TestCase
  
  def setup
    @parser = Nagios::Parser.new
  end
  
  def test_comment
    result = @parser.parse("# foo\n")
    
    assert_equal(1, result.nodes.length)
    assert_kind_of(Nagios::Comment, result.nodes.first)
    assert_equal(" foo", result.nodes.first.value)
  end
  
  def test_whitespace
    result = @parser.parse("  \n")
    
    assert_equal(1, result.nodes.length)
    assert_kind_of(Nagios::Whitespace, result.nodes.first)
    assert_equal("  \n", result.nodes.first.value)
  end
  
  def test_variable
    result = @parser.parse("foo=bar\n")
    
    assert_equal(1, result.nodes.length)
    assert_kind_of(Nagios::Variable, result.nodes.first)
    assert_equal(2, result.nodes.first.nodes.length)
    assert_kind_of(Nagios::Name, result.nodes.first.nodes.first)
    assert_kind_of(Nagios::Value, result.nodes.first.nodes.last)
    assert_equal("foo", result.nodes.first.nodes.first.value)
    assert_equal("bar", result.nodes.first.nodes.last.value)
  end
  
  def test_define
    result = @parser.parse("define test{\nbar baz ; comment\n}\n")
    assert_equal(1, result.nodes.length)
    assert_kind_of(Nagios::Define, result.nodes.first)
    assert_equal(2, result.nodes.first.nodes.length)
    assert_kind_of(Nagios::Type, result.nodes.first.nodes.first)
    assert_equal("test", result.nodes.first.nodes.first.value)
    assert_kind_of(Nagios::Variable, result.nodes.first.nodes.last)
    assert_equal(3, result.nodes.first.nodes.last.nodes.length)
    assert_kind_of(Nagios::Name, result.nodes.first.nodes.last.nodes.first)
    assert_kind_of(Nagios::Value, result.nodes.first.nodes.last.nodes[1])
    assert_kind_of(Nagios::TrailingComment, result.nodes.first.nodes.last.nodes.last)
    assert_equal("bar", result.nodes.first.nodes.last.nodes.first.value)
    assert_equal("baz", result.nodes.first.nodes.last.nodes[1].value)
    assert_equal(" comment", result.nodes.first.nodes.last.nodes.last.value)
  end
  
end