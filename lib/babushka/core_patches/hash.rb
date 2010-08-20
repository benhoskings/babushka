class Hash
  def dragnet *keys
    dup.dragnet! *keys
  end

  def dragnet! *keys
    keys.inject({}) {|acc,key|
      acc[key] = self.delete(key) if self.has_key?(key)
      acc
    }
  end

  def defaults! other
    replace other.merge(self)
  end
  def defaults other
    dup.defaults! other
  end

  def map_values &block
    dup.map_values! &block
  end

  def map_values! &block
    keys.each {|k|
      self[k] = yield k, self[k]
    }
    self
  end

  def selekt &block
    hsh = {}
    each_pair {|k,v|
      hsh[k] = v if yield(k,v)
    }
    hsh
  end

  def reject_r &block
    dup.reject_r! &block
  end

  def reject_r! &block
    each_pair {|k,v|
      if yield k, v
        self.delete k
      elsif v.is_a? Hash
        self[k] = v.reject_r &block
      end
    }
  end
end
