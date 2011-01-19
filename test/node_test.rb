base = File.expand_path(File.dirname(__FILE__) + '/../lib')
require base + '/nagios_config'
require 'test/unit'

class NodeTest < Test::Unit::TestCase
  
  # Generate a new subclass for each test to avoid class ivars persisting
  def setup
    @node_class = Class.new(NagiosConfig::Node)
    @other_node_class = Class.new(NagiosConfig::Node)
  end
  
  def test_default_allow_nothing
    assert_equal([], @node_class.allow)
  end
  
  def test_node_not_allowed
    parent = @node_class.new
    child = @other_node_class.new
    
    assert_equal(false, parent.allow?(child))
    assert_raise(RuntimeError) {parent.add_node(child)}
  end
  
  def test_allow_node
    @node_class.allow(@other_node_class)
    parent = @node_class.new
    child = @other_node_class.new
    
    assert(parent.allow?(child), "child should be allowed")
    assert_nothing_raised {parent.add_node(child)}
  end
  
  def test_add_node
    @node_class.allow(@other_node_class)
    parent = @node_class.new
    child1 = @other_node_class.new
    child2 = @other_node_class.new
    
    parent.add_node(child1)
    
    assert_equal([child1], parent.nodes)
    
    parent.add_node(child2)
    
    assert_equal([child1, child2], parent.nodes)
  end
  
  def test_remove_node
    @node_class.allow(@other_node_class)
    parent = @node_class.new
    child1 = @other_node_class.new
    child2 = @other_node_class.new
    parent.add_node(child1)
    parent.add_node(child2)
    
    parent.remove_node(child1)
    
    assert_equal([child2], parent.nodes)
  end
  
  def test_class_method_nodes_creates_subclass
    flunk if @node_class.constants.map(&:to_s).include?("Example")
    @node_class.nodes(:example)
    
    assert(@node_class.constants.map(&:to_s).include?("Example"), "const not set")
    assert_kind_of(Class, @node_class::Example)
    assert_equal(NagiosConfig::Node, @node_class::Example.superclass)
  end
  
  def test_class_method_nodes_allows_subclass
    @node_class.nodes(:example)
    parent = @node_class.new
    child = @node_class::Example.new
    
    assert_equal([@node_class::Example], @node_class.allow)
    assert(parent.allow?(child), "child should be allowed")
  end
  
  def test_class_method_nodes_creates_accessors
    flunk if @node_class.instance_methods.include?("examples")
    flunk if @node_class.instance_methods.include?("add_example")
    @node_class.nodes(:example)
    
    assert(@node_class.instance_methods.map(&:to_s).include?("examples"), "method missing")
    assert(@node_class.instance_methods.map(&:to_s).include?("add_example"), "method missing")
  end
  
  def test_generated_nodes_accessors
    @node_class.nodes(:example)
    @node_class.nodes(:test)
    node = @node_class.new
    child1 = @node_class::Example.new
    child2 = @node_class::Example.new
    child3 = @node_class::Test.new
    
    assert_nothing_raised {node.add_example(child1)}
    assert_nothing_raised {node.add_example(child2)}
    assert_nothing_raised {node.add_test(child3)}
    
    assert_equal([child1, child2], node.examples)
    assert_equal([child3], node.tests)
    assert_equal([child1, child2, child3], node.nodes)
  end
  
  def test_class_method_node_creates_accessors
    flunk if @node_class.instance_methods.include?("example")
    flunk if @node_class.instance_methods.include?("example=")
    @node_class.node(:example)
    
    assert(@node_class.instance_methods.map(&:to_s).include?("example"), "method missing")
    assert(@node_class.instance_methods.map(&:to_s).include?("example="), "method missing")
  end
  
  def test_generated_node_accessors
    @node_class.node(:example)
    node = @node_class.new
    child = @node_class::Example.new
    
    assert_nothing_raised {node.example = child}
    
    assert_equal(child, node.example)
    assert_equal([child], node.nodes)
  end
  
  def test_after
    @node_class.nodes(:example)
    node = @node_class.new
    child1 = @node_class::Example.new
    child2 = @node_class::Example.new
    child3 = @node_class::Example.new
    node.add_node(child1)
    node.add_node(child2)
    node.add_node(child3)
    
    assert_equal(child2, node.after(child1))
  end
  
  def test_after_on_last_node
    @node_class.nodes(:example)
    node = @node_class.new
    child1 = @node_class::Example.new
    child2 = @node_class::Example.new
    child3 = @node_class::Example.new
    node.add_node(child1)
    node.add_node(child2)
    node.add_node(child3)
    
    assert_equal(nil, node.after(child3))
  end
  
  def test_before
    @node_class.nodes(:example)
    node = @node_class.new
    child1 = @node_class::Example.new
    child2 = @node_class::Example.new
    child3 = @node_class::Example.new
    node.add_node(child1)
    node.add_node(child2)
    node.add_node(child3)
    
    assert_equal(child2, node.before(child3))
  end
  
  def test_before_on_first_node
    @node_class.nodes(:example)
    node = @node_class.new
    child1 = @node_class::Example.new
    child2 = @node_class::Example.new
    child3 = @node_class::Example.new
    node.add_node(child1)
    node.add_node(child2)
    node.add_node(child3)
    
    assert_equal(nil, node.before(child1))
  end
  
  def test_insert_after
    @node_class.nodes(:example)
    node = @node_class.new
    child1 = @node_class::Example.new
    child2 = @node_class::Example.new
    child3 = @node_class::Example.new
    node.add_node(child1)
    node.add_node(child3)
    
    node.insert_after(child1, child2)
    
    assert_equal([child1, child2, child3], node.nodes)
  end
  
  def test_insert_after_on_last_node
    @node_class.nodes(:example)
    node = @node_class.new
    child1 = @node_class::Example.new
    child2 = @node_class::Example.new
    child3 = @node_class::Example.new
    node.add_node(child1)
    node.add_node(child3)
    
    node.insert_after(child3, child2)
    
    assert_equal([child1, child3, child2], node.nodes)
  end
  
  def test_insert_before
    @node_class.nodes(:example)
    node = @node_class.new
    child1 = @node_class::Example.new
    child2 = @node_class::Example.new
    child3 = @node_class::Example.new
    node.add_node(child1)
    node.add_node(child3)
    
    node.insert_before(child3, child2)
    
    assert_equal([child1, child2, child3], node.nodes)
  end
  
  def test_insert_before_on_first_node
    @node_class.nodes(:example)
    node = @node_class.new
    child1 = @node_class::Example.new
    child2 = @node_class::Example.new
    child3 = @node_class::Example.new
    node.add_node(child1)
    node.add_node(child3)
    
    node.insert_before(child1, child2)
    
    assert_equal([child2, child1, child3], node.nodes)
  end
  
end