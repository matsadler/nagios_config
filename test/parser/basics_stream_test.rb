base = File.expand_path(File.dirname(__FILE__) + '/../../lib')
require base + '/nagios_config'
require 'test/unit'

class BasicsStreamTest < Test::Unit::TestCase
  
  def setup
    @parser = NagiosConfig::Parser.new
  end
  
  def test_comment
    comment = nil
    @parser.on(:comment) {|c| comment = c}
    
    @parser.stream_parse("# foo\n")
    
    assert_equal(" foo", comment)
  end
  
  def test_comment_with_leading_whitespace
    assert_raise(NagiosConfig::ParseError) do
      @parser.stream_parse(" # foo\n")
    end
  end
  
  def test_blank_line_comment
    comments = []
    @parser.on(:comment) {|c| comments.push(c)}
    
    @parser.stream_parse("# foo\n#\n# bar\n")
    
    assert_equal([" foo", "", " bar"], comments)
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