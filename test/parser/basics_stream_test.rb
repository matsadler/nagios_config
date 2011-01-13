base = File.expand_path(File.dirname(__FILE__) + '/../../lib')
require base + '/nagios'
require 'test/unit'

class BasicsStreamTest < Test::Unit::TestCase
  
  def setup
    @parser = Nagios::Parser.new
  end
  
  def test_comment
    comment = nil
    @parser.on(:comment) {|c| comment = c}
    
    @parser.stream_parse("# foo\n")
    
    assert_equal(" foo", comment)
  end
  
  def test_comment_terminated_by_end_of_file
    comment = nil
    @parser.on(:comment) {|c| comment = c}
    
    @parser.stream_parse("# bar")
    
    assert_equal(" bar", comment)
  end
  
  def test_comment_with_leading_whitespace
    assert_raise(Nagios::ParseError) do
      @parser.stream_parse(" # foo\n")
    end
  end
  
  def test_space_is_whitespace
    called = false
    whitespace = nil
    @parser.on(:whitespace) {|w| called = true; whitespace = w}
    
    @parser.stream_parse("  \n")
    
    assert(called, "callback not called")
    assert_equal("  \n", whitespace)
  end
  
  def test_tab_is_whitespace
    called = false
    whitespace = nil
    @parser.on(:whitespace) {|w| called = true; whitespace = w}
    
    @parser.stream_parse("\t\n")
    
    assert(called, "callback not called")
    assert_equal("\t\n", whitespace)
  end
  
  def test_newline_is_whitespace
    called = false
    whitespace = nil
    @parser.on(:whitespace) {|w| called = true; whitespace = w}
    
    @parser.stream_parse("\n")
    
    assert(called, "callback not called")
    assert_equal("\n", whitespace)
  end
  
end