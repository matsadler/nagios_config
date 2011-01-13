base = File.expand_path(File.dirname(__FILE__) + '/../../lib')
require base + '/nagios'
require 'test/unit'

class TemplateStreamTest < Test::Unit::TestCase
  
  def setup
    @parser = Nagios::Parser.new
  end
  
  def test_empty_define
    begin_define_called = false
    type = nil
    finish_define_called = false
    @parser.on(:begin_define) {begin_define_called = true}
    @parser.on(:type) {|t| type = t}
    @parser.on(:finish_define) {finish_define_called = true}
    
    @parser.stream_parse("define host{\n}")
    
    assert(begin_define_called, "begin callback not called")
    assert_equal("host", type)
    assert(finish_define_called, "finish callback not called")
  end
  
  def test_multiple_empty_define
    calls = 0
    @parser.on(:begin_define) {calls += 1}
    
    @parser.stream_parse("define host{\n}\n\ndefine host{\n}")
    
    assert_equal(2, calls)
  end
  
  def test_name_value_in_define
    name = nil
    value = nil
    finish_define_called = false
    @parser.on(:name) {|n| name = n}
    @parser.on(:value) {|v| value = v}
    @parser.on(:finish_define) {finish_define_called = true}
    
    @parser.stream_parse("define host{
    foo   bar
}")
    assert_equal("foo", name)
    assert_equal("bar", value)
    assert(finish_define_called, "finish callback not called")
  end
  
  def test_define_can_contain_whitespace
    names = []
    values = []
    
    @parser.on(:name) {|n| names.push(n)}
    @parser.on(:value) {|v| values.push(v)}
    
    @parser.stream_parse("define host{
    foo   bar
    
    baz   qux
}")
    
    assert_equal(%W{foo baz}, names)
    assert_equal(%W{bar qux}, values)
  end
  
  def test_define_can_contain_comment
    names = []
    values = []
    comment = nil
    
    @parser.on(:name) {|n| names.push(n)}
    @parser.on(:value) {|v| values.push(v)}
    @parser.on(:comment) {|c| comment = c}
    
    @parser.stream_parse("define host{
    testing   test
# a comment
    example   foo
}")
    
    assert_equal(%W{testing example}, names)
    assert_equal(%W{test foo}, values)
    assert_equal(" a comment", comment)
  end
  
  def test_start_define_must_be_treminated_by_newline
    assert_raise(Nagios::ParseError) {@parser.stream_parse("define host{foo bar\n}")}
  end
  
  def test_start_define_without_type
    assert_raise(Nagios::ParseError) {@parser.stream_parse("define {\n}")}
  end
  
  def test_name_with_missing_value_in_define
    assert_raise(Nagios::ParseError) {@parser.stream_parse("define host{\nfoo\n}")}
  end
  
  def test_define_can_contain_trailing_comment
    name = nil
    value = nil
    comment = nil
    
    @parser.on(:name) {|n| name = n}
    @parser.on(:value) {|v| value = v}
    @parser.on(:trailing_comment) {|c| comment = c}
    
    @parser.stream_parse("define host {
    example   test ; Mr. Comment
}")
    
    assert_equal("example", name)
    assert_equal("test", value)
    assert_equal(" Mr. Comment", comment)
  end
  
end