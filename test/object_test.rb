base = File.expand_path(File.dirname(__FILE__) + '/../lib')
require base + '/nagios_config'
require 'test/unit'

class ObjectTest < Test::Unit::TestCase
  
  def setup
    
  end
  
  def teardown
    NagiosConfig::Object.clear
  end
  
  def test_hash_access
    obj = NagiosConfig::Object.new(:host, :host_name => "example.com", :alias => "example")
    
    assert_equal("example.com", obj[:host_name])
    assert_equal("example", obj[:alias])
  end
  
  def test_hash_set
    obj = NagiosConfig::Object.new(:host)
    
    obj[:address] = "192.0.32.10"
    obj[:contact_groups] = "example"
    
    assert_equal("192.0.32.10", obj[:address])
    assert_equal("example", obj[:contact_groups])
  end
  
  def test_get_attributes
    obj = NagiosConfig::Object.new(:host, :host_name => "example.com", :alias => "example")
    
    assert_equal("example.com", obj[:host_name])
    assert_equal("example", obj[:alias])
    
    assert_equal("example.com", obj.host_name)
    assert_equal("example", obj.alias)
  end
  
  def test_set_attributes
    obj = NagiosConfig::Object.new(:host)
    
    obj.address = "192.0.32.10"
    obj.contact_groups = "example"
    
    assert_equal("192.0.32.10", obj.address)
    assert_equal("example", obj.contact_groups)
  end
  
  def test_parent
    obj1 = NagiosConfig::Object.new(:host, :use => "example", :host_name => "test.com")
    obj2 = NagiosConfig::Object.new(:host, :name => "example", :hostgroups => "test")
    
    assert_same(obj2, obj1.parent)
  end
  
  def test_inherit_parent_attributes
    obj1 = NagiosConfig::Object.new(:host, :use => "default", :host_name => "foo.com")
    obj2 = NagiosConfig::Object.new(:host, :name => "default", :hostgroups => "foo,bar,baz")
    
    assert_equal("foo,bar,baz", obj1.hostgroups)
  end
  
  def test_inherit_parent_hash_access
    obj1 = NagiosConfig::Object.new(:host, :use => "default", :host_name => "foo.com")
    obj2 = NagiosConfig::Object.new(:host, :name => "default", :hostgroups => "foo,bar,baz")
    
    assert_equal("foo,bar,baz", obj1[:hostgroups])
  end
  
  def test_inherit_parent_attributes_is_dynamic
    obj1 = NagiosConfig::Object.new(:host, :use => "generic", :host_name => "baz.com")
    obj2 = NagiosConfig::Object.new(:host, :name => "generic", :hostgroups => "baz")
    
    assert_equal("baz", obj1.hostgroups)
    
    obj2.hostgroups = "qux"
    
    assert_equal("qux", obj1.hostgroups)
  end
  
  def test_name_and_register_not_inherited
    obj1 = NagiosConfig::Object.new(:host, :use => "foo")
    obj2 = NagiosConfig::Object.new(:host, :name => "foo", :register => "0")
    
    assert_nil(obj1.name)
    assert_nil(obj1.register)
  end
  
  def test_override_parent_attributes
    obj1 = NagiosConfig::Object.new(:host, :use => "default", :host_name => "foo.com")
    obj2 = NagiosConfig::Object.new(:host, :name => "default", :hostgroups => "test")
    
    obj1.hostgroups = "example"
    
    assert_equal("example", obj1.hostgroups)
    assert_equal("test", obj2.hostgroups)
  end
  
  def test_multiple_levels_of_inheritance
    obj1 = NagiosConfig::Object.new(:host, :host_name => "foo.com", :use => "default")
    obj2 = NagiosConfig::Object.new(:host, :name => "default", :use => "generic", :check_command => "pong")
    obj3 = NagiosConfig::Object.new(:host, :name => "generic", :check_command => "ping", :hostgroups => "test")
    
    assert_equal("foo.com", obj1.host_name)
    assert_equal("pong", obj1.check_command)
    assert_equal("test", obj1.hostgroups)
  end
  
  def test_inheritance_doesnt_happen_across_types
    obj1 = NagiosConfig::Object.new(:host, :use => "example", :host_name => "test.com")
    obj2 = NagiosConfig::Object.new(:service, :name => "example", :hostgroups => "test")
    
    assert_raise(NagiosConfig::ParentNotFound) {obj1.parent}
  end
  
  def test_simple_equals
    obj1 = NagiosConfig::Object.new(:host, :host_name => "foo.com", :alias => "foo")
    obj2 = NagiosConfig::Object.new(:host, :host_name => "foo.com", :alias => "foo")
    obj3 = NagiosConfig::Object.new(:service, :host_name => "foo.com", :alias => "foo")
    obj4 = NagiosConfig::Object.new(:host, :host_name => "bar.com", :alias => "bar")
    
    assert(obj1 == obj2)
    assert(obj1 != obj3)
    assert(obj1 != obj4)
  end
  
  def test_equals_with_inheritance
    obj1 = NagiosConfig::Object.new(:host, :host_name => "foo.com", :alias => "foo", :check_command => "ping")
    obj2 = NagiosConfig::Object.new(:host, :host_name => "foo.com", :alias => "foo", :use => "default")
    obj3 = NagiosConfig::Object.new(:host, :name => "default", :check_command => "ping")
    
    assert(obj1 == obj2)
  end
  
  def test_inspect_is_unique_per_object
    obj1 = NagiosConfig::Object.new(:host, :host_name => "foo.com", :alias => "foo")
    obj2 = NagiosConfig::Object.new(:host, :host_name => "foo.com", :alias => "foo")
    
    assert(obj1.inspect != obj2.inspect)
    assert(obj1.inspect == obj1.inspect)
  end
  
  def test_method_missing
    obj = NagiosConfig::Object.new(:host, :host_name => "foo.com", :alias => "foo")
    
    assert_raise(NoMethodError) {obj.do_something_with(:things, :stuff)}
  end
  
  def test_self_from_node
    obj = NagiosConfig::Object.new(:host, :name => "defaults", :register => "0", :hostgroups => "web")
    
    node = NagiosConfig::Parser.new.parse("define host {
  host_name      apple.com
  alias          apple
  use            defaults
  check_command  ping
}\n").defines.first
    
    obj = NagiosConfig::Object.from_node(node)
    
    assert_equal("apple.com", obj.host_name)
    assert_equal("apple", obj.alias)
    assert_equal("defaults", obj.use)
    assert_equal("ping", obj.check_command)
    assert_equal("web", obj.hostgroups)
  end
  
end