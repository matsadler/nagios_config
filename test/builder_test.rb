base = File.expand_path(File.dirname(__FILE__) + '/../lib')
require base + '/nagios'
require 'test/unit'

class BuilderTest < Test::Unit::TestCase
  
  def setup
    @builder = Nagios::Builder.new
  end
  
  def test_comment
    @builder.comment(" foo")
    
    result = @builder.root
    
    assert_equal(1, result.nodes.length)
    assert_kind_of(Nagios::Comment, result.nodes.first)
    assert_equal(" foo", result.nodes.first.value)
  end
  
  def test_whitespace
    @builder.break
    
    result = @builder.root
    
    assert_equal(1, result.nodes.length)
    assert_kind_of(Nagios::Whitespace, result.nodes.first)
    assert_equal("\n", result.nodes.first.value)
  end
  
  def test_variable
    @builder.foo = "bar"
    
    result = @builder.root
    
    assert_equal(1, result.nodes.length)
    assert_kind_of(Nagios::Variable, result.nodes.first)
    assert_equal(2, result.nodes.first.nodes.length)
    assert_kind_of(Nagios::Name, result.nodes.first.nodes.first)
    assert_kind_of(Nagios::Value, result.nodes.first.nodes.last)
    assert_equal("foo", result.nodes.first.nodes.first.value)
    assert_equal("bar", result.nodes.first.nodes.last.value)
  end
  
  def test_define
    @builder.define("test") do |test|
      test.bar = "baz"
      test.bar.comment(" comment")
    end
    
    result = @builder.root
    
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
  
  def test_to_s
    @builder.comment(" foo")
    @builder.break
    @builder.foo = "bar"
    @builder.define("test") do |test|
      test.bar = "baz"
      test.bar.comment(" comment")
    end
    
    assert_equal(%Q{# foo

foo=bar
define test {
  bar  baz  ; comment
}
}, @builder.to_s)
  end
  
  def test_set_value_true
    @builder.example = true
    
    assert_equal("example=1\n", @builder.to_s)
  end
  
  def test_set_value_false
    @builder.test = false
    
    assert_equal("test=0\n", @builder.to_s)
  end
  
  def test_set_value_nil
    @builder.example = 1
    @builder.test = 0
    
    assert_equal("example=1\ntest=0\n", @builder.to_s)
    
    @builder.example = nil
    
    assert_equal("test=0\n", @builder.to_s)
  end
  
  def test_method_missing_calls_super
    assert_raise(NoMethodError) {@builder.do_something(1, 2, 3)}
  end
  
end