base = File.expand_path(File.dirname(__FILE__) + '/../lib')
require base + '/nagios_config'
require 'test/unit'

class MainTest < Test::Unit::TestCase
  
  def test_hash_access
    main = NagiosConfig::Main.new(:log_file => "/foo/bar/log", :object_cache_file => "/foo/bar/objects.cache")
    
    assert_equal("/foo/bar/log", main[:log_file])
    assert_equal("/foo/bar/objects.cache", main[:object_cache_file])
  end
  
  def test_hash_set
    main = NagiosConfig::Main.new
    
    main[:cfg_file] = ["hosts.cfg", "services.cfg"]
    main[:resource_file] = "/foo/bar/resource.cfg"
    
    assert_equal(["hosts.cfg", "services.cfg"], main[:cfg_file])
    assert_equal("/foo/bar/resource.cfg", main[:resource_file])
  end
  
  def test_get_attributes
    main = NagiosConfig::Main.new(:log_file => "/foo/bar/log", :object_cache_file => "/foo/bar/objects.cache")
    
    assert_equal("/foo/bar/log", main.log_file)
    assert_equal("/foo/bar/objects.cache", main.object_cache_file)
  end
  
  def test_set_attributes
    main = NagiosConfig::Main.new
    
    main.cfg_file = ["hosts.cfg", "services.cfg"]
    main.resource_file = "/foo/bar/resource.cfg"
    
    assert_equal(["hosts.cfg", "services.cfg"], main.cfg_file)
    assert_equal("/foo/bar/resource.cfg", main.resource_file)
  end
  
  def test_objects
    obj1 = NagiosConfig::Object.new(:host, :name => "example_host")
    obj2 = NagiosConfig::Object.new(:service, :name => "example_service")
    main = NagiosConfig::Main.new({}, [obj1, obj2])
    
    assert_equal([obj1, obj2], main.objects)
  end
  
  def test_filter_objects
    obj1 = NagiosConfig::Object.new(:host, :name => "example_host")
    obj2 = NagiosConfig::Object.new(:service, :name => "example_service")
    main = NagiosConfig::Main.new({}, [obj1, obj2])
    
    assert_equal([obj1], main.objects(:host))
    assert_equal([obj2], main.objects(:service))
  end
  
  def test_modify_objects
    obj1 = NagiosConfig::Object.new(:host, :name => "example_host")
    obj2 = NagiosConfig::Object.new(:service, :name => "example_service")
    obj3 = NagiosConfig::Object.new(:service, :name => "second_example_service")
    main = NagiosConfig::Main.new({}, [obj1, obj2])
    
    assert_equal([obj1, obj2], main.objects)
    
    main.objects << obj3
    
    assert_equal([obj1, obj2, obj3], main.objects)
    assert_equal([obj2, obj3], main.objects(:service))
    
    main.objects.delete(obj2)
    
    assert_equal([obj1, obj3], main.objects)
    assert_equal([obj3], main.objects(:service))
  end
  
  def test_simple_equals
    obj1 = NagiosConfig::Object.new(:host, :name => "example_host")
    obj2 = NagiosConfig::Object.new(:service, :name => "example_service")
    main1 = NagiosConfig::Main.new({:log_file => "/foo/bar/log", :cfg_file => ["hosts.cfg", "services.cfg"]}, [obj1, obj2])
    
    # same
    obj3 = NagiosConfig::Object.new(:host, :name => "example_host")
    obj4 = NagiosConfig::Object.new(:service, :name => "example_service")
    main2 = NagiosConfig::Main.new({:log_file => "/foo/bar/log", :cfg_file => ["hosts.cfg", "services.cfg"]}, [obj3, obj4])
    
    # different variables
    obj5 = NagiosConfig::Object.new(:host, :name => "example_host")
    obj6 = NagiosConfig::Object.new(:service, :name => "example_service")
    main3 = NagiosConfig::Main.new({:log_file => "/baz/qux/log", :cfg_file => ["hostgroups.cfg", "constacts.cfg"]}, [obj5, obj6])
    
    # diffrent objects
    obj7 = NagiosConfig::Object.new(:hostgroup, :name => "example_hostgroup")
    obj8 = NagiosConfig::Object.new(:service, :name => "second_example_service")
    main4 = NagiosConfig::Main.new({:log_file => "/foo/bar/log", :cfg_file => ["hosts.cfg", "services.cfg"]}, [obj7, obj8])
    
    assert(main1 == main2)
    assert(main1 != main3)
    assert(main1 != main4)
    assert(main3 != main4)
  end
  
  def test_inspect_is_unique_per_object
    obj1 = NagiosConfig::Object.new(:host, :name => "example_host")
    main1 = NagiosConfig::Main.new({:log_file => "/foo/bar/log"}, [obj1])
    
    obj2 = NagiosConfig::Object.new(:host, :name => "example_host")
    main2 = NagiosConfig::Main.new({:log_file => "/foo/bar/log"}, [obj2])
    
    assert(main1.inspect != main2.inspect)
    assert(main1.inspect == main1.inspect)
  end
  
  def test_method_missing
    main = NagiosConfig::Main.new(:log_file => "/foo/bar/log")
    
    assert_raise(NoMethodError) {main.do_something_with(:things, :stuff)}
  end
  
  def test_self_from_node
    node = NagiosConfig::Parser.new.parse("# LOG FILE
log_file=/foo/bar/baz/nagios/nagios.log

# OBJECT CONFIGURATION FILE(S)
# This is the configuration file in which you define hosts, host
# groups, contacts, contact groups, services, etc.

cfg_file=hostgroups.cfg
cfg_file=hosts.cfg
cfg_file=services.cfg

# OBJECT CACHE FILE

object_cache_file=/foo/bar/baz/nagios/objects.cache\n")
    
    main = NagiosConfig::Main.from_node(node)
    
    assert_equal("/foo/bar/baz/nagios/nagios.log", main.log_file)
    assert_equal(["hostgroups.cfg", "hosts.cfg", "services.cfg"], main.cfg_file)
    assert_equal("/foo/bar/baz/nagios/objects.cache", main.object_cache_file)
  end
  
  def test_self_from_node_with_objects
    node = NagiosConfig::Parser.new.parse("define host {
  name        defaults
  register    0
  hostgroups  web
}

define host {
  host_name      example.com
  alias          example
  use            defaults
  check_command  ping
}

import=example.cfg\n")
    
    main = NagiosConfig::Main.from_node(node)
    
    assert_equal(2, main.objects.length)
    assert_equal("example.com", main.objects.last.host_name)
    assert_equal("example", main.objects.last.alias)
    assert_equal("defaults", main.objects.last.use)
    assert_equal("ping", main.objects.last.check_command)
    assert_equal("web", main.objects.last.hostgroups)
    assert_equal("example.cfg", main.import)
  end
  
  def test_parse
    main = NagiosConfig::Main.parse("define host {
  host_name  test.com
}

import=more.cfg\n")
    
    assert_equal(1, main.objects.length)
    assert_equal("test.com", main.objects.first.host_name)
    assert_equal("more.cfg", main.import)
  end
  
end