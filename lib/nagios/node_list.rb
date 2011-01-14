module Nagios
  class NodeList
    class Element
      include Enumerable
      attr_accessor :previous, :value, :next
      
      def initialize(value)
        self.value = value
      end
      
      def each(&block)
        current = self
        begin
          yield current
        end while current = current.next
      end
      
      def next=(element)
        @next = element
        element.previous = self
        element
      end
    end
    
    include Enumerable
    attr_accessor :head, :tail
    protected :head, :tail
    
    def initialize(*args)
      push(*args)
    end
    
    def push(*args)
      args.each do |arg|
        self << arg
      end
      self
    end
    
    def <<(arg)
      elm = Element.new(arg)
      if tail
        tail.next = elm
      else
        self.head = elm
      end
      self.tail = elm
      self
    end
    
    def first
      head.value
    end
    
    def last
      tail.value
    end
    
    def each
      head.each do |element|
        yield element.value
      end if head
    end
    
    def delete(value)
      elem = head.find {|element| element.value == value}
      
      self.head = elem.next if elem == head
      self.tail = elem.previous if elem == tail
      elem.previous.next = elem.next if elem.previous
    end
    
    def reject!(&block)
      replace(reject(&block))
    end
    
    def select!(&block)
      replace(select(&block))
    end
    
    def replace(array)
      self.head = nil
      self.tail = nil
      push(*array)
      self
    end
    
    def inspect
      entries.inspect
    end
    
  end
end