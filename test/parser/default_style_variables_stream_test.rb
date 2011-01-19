base = File.expand_path(File.dirname(__FILE__) + '/../../lib')
require base + '/nagios'
require 'test/unit'

class DefaultStyleVariablesStreamTest < Test::Unit::TestCase
  
  def setup
    @parser = Nagios::Parser.new
  end
  
  def test_name_and_value
    name = nil
    value = nil
    @parser.on(:name) {|n| name = n}
    @parser.on(:value) {|v| value = v}
    
    @parser.stream_parse("foo=bar\n")
    
    assert_equal("foo", name)
    assert_equal("bar", value)
  end
  
  def test_value_can_contain_whitespace
    name = nil
    value = nil
    @parser.on(:name) {|n| name = n}
    @parser.on(:value) {|v| value = v}
    
    @parser.stream_parse("string=something with spaces in\n")
    
    assert_equal("string", name)
    assert_equal("something with spaces in", value)
  end
  
  def test_name_and_value_with_leading_whitespace
    assert_raise(Nagios::ParseError) {@parser.stream_parse(" name=value\n")}
  end
  
  def test_missing_assignment
    assert_raise(Nagios::ParseError) {@parser.stream_parse("name\n")}
  end
  
  def test_missing_value
    assert_raise(Nagios::ParseError) {@parser.stream_parse("foo=\n")}
  end
  
  def test_comment_whitespace_name_value
    comment = nil
    whitespace = nil
    name = nil
    value = nil
    @parser.on(:comment) {|c| comment = c}
    @parser.on(:whitespace) {|w| whitespace = w}
    @parser.on(:name) {|n| name = n}
    @parser.on(:value) {|v| value = v}
    
    @parser.stream_parse("# a comment

key=value
")
    
    assert_equal(" a comment", comment)
    assert_equal("\n", whitespace)
    assert_equal("key", name)
    assert_equal("value", value)
  end
  
  def test_whitespace_comment_name_value
    whitespace = nil
    comment = nil
    name = nil
    value = nil
    @parser.on(:whitespace) {|w| whitespace = w}
    @parser.on(:comment) {|c| comment = c}
    @parser.on(:name) {|n| name = n}
    @parser.on(:value) {|v| value = v}
    
    @parser.stream_parse("
# testing
example=test
")
    
    assert_equal("\n", whitespace)
    assert_equal(" testing", comment)
    assert_equal("example", name)
    assert_equal("test", value)
  end
  
  def test_name_value_whitespace
    name = nil
    value = nil
    whitespace = nil
    @parser.on(:name) {|n| name = n}
    @parser.on(:value) {|v| value = v}
    @parser.on(:whitespace) {|w| whitespace = w}
    
    @parser.stream_parse("e=mc^2

")
    
    assert_equal("e", name)
    assert_equal("mc^2", value)
    assert_equal("\n", whitespace)
  end
  
  def test_name_value_comment_comment
    name = nil
    value = nil
    comments = []
    @parser.on(:name) {|n| name = n}
    @parser.on(:value) {|v| value = v}
    @parser.on(:comment) {|c| comments.push(c)}
    
    @parser.stream_parse("test=example
# comment the first
# comment the second
")
    
    assert_equal("test", name)
    assert_equal("example", value)
    assert_equal([" comment the first", " comment the second"], comments)
  end
  
  def test_comment_whitespace_test_name_value_name_value
    data = {}
    last_key = nil
    comment = nil
    @parser.on(:name) {|n| last_key = n}
    @parser.on(:value) {|v| data[last_key] = v}
    @parser.on(:comment) {|c| comment = c}
    
    @parser.stream_parse("# example
foo=bar
baz=qux
")

    assert_equal(" example", comment)
    assert_equal({"foo" => "bar", "baz" => "qux"}, data)
  end
  
end