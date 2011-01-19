base = File.expand_path(File.dirname(__FILE__) + '/../../lib')
require base + '/nagios_config'
require 'test/unit'

class ReentranceTest < Test::Unit::TestCase
  
  def setup
    @parser = NagiosConfig::Parser.new
    
    # super inconstantly formatted config file
    @config = "
# test config file

import=example.cfg
import=test.cfg

define host {
  name     template
		
	register 0
# check all the time
    check_period	24x7
  max_check_attempts 3 ; three
  
}

# first host
define host{
    host_name   foo.example.com
# a comment
    alias       foo
    address     0.0.0.0
}
  	
define host	{
  host_name			bar.example.com ; second host

  alias					bar             ; aliased to bar
                                ; address comes next
  address				0.0.0.1
}
		"
  end
  
  def test_reentrance
    1.upto(@config.length) do |i|
      @parser = NagiosConfig::Parser.new
      stream = []
      
      @parser.on(:whitespace) {|value| stream.push([:whitespace, value])}
      @parser.on(:comment) {|value| stream.push([:comment, value])}
      @parser.on(:name) {|value| stream.push([:name, value])}
      @parser.on(:value) {|value| stream.push([:value, value])}
      @parser.on(:begin_define) {stream.push([:begin_define])}
      @parser.on(:type) {|value| stream.push([:type, value])}
      @parser.on(:finish_define) {stream.push([:finish_define])}
      @parser.on(:trailing_comment) {|value| stream.push([:trailing_comment, value])}
      
      io = StringIO.new(@config)
      until io.eof?
        @parser << io.read(i)
      end
      
      assert_equal([[:whitespace, "\n"], [:comment, " test config file"], [:whitespace, "\n"], [:name, "import"], [:value, "example.cfg"], [:name, "import"], [:value, "test.cfg"], [:whitespace, "\n"], [:begin_define], [:type, "host"], [:name, "name"], [:value, "template"], [:whitespace, "\t\t\n"], [:name, "register"], [:value, "0"], [:comment, " check all the time"], [:name, "check_period"], [:value, "24x7"], [:name, "max_check_attempts"], [:value, "3"], [:trailing_comment, " three"], [:whitespace, "  \n"], [:finish_define], [:whitespace, "\n"], [:comment, " first host"], [:begin_define], [:type, "host"], [:name, "host_name"], [:value, "foo.example.com"], [:comment, " a comment"], [:name, "alias"], [:value, "foo"], [:name, "address"], [:value, "0.0.0.0"], [:finish_define], [:whitespace, "  \t\n"], [:begin_define], [:type, "host"], [:name, "host_name"], [:value, "bar.example.com"], [:trailing_comment, " second host"], [:whitespace, "\n"], [:name, "alias"], [:value, "bar"], [:trailing_comment, " aliased to bar"], [:trailing_comment, " address comes next"], [:whitespace, " address comes next"], [:name, "address"], [:value, "0.0.0.1"], [:finish_define]], stream)
    end
  end
  
end