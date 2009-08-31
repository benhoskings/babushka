def setup_yield_counts
  @yield_counts = Hash.new {|hsh,k| hsh[k] = Hash.new {|hsh,k| 0 } }

  @yield_counts_none = {}
  @yield_counts_met_run = {:setup => 1, :met? => 1}
  @yield_counts_meet_run = {:setup => 1, :met? => 2, :meet => 1, :before => 1, :after => 1}
  @yield_counts_dep_failed = {:setup => 1}
  @yield_counts_failed_meet_run = {:setup => 1, :met? => 2, :meet => 1, :before => 1, :after => 1}
  @yield_counts_already_met = {:setup => 1, :met? => 1}
  @yield_counts_failed_at_before = {:setup => 1, :met? => 2, :before => 1}
end

def make_counter_dep opts = {}
  incrementers = BaseDepDefiner.accepted_blocks.inject({}) {|lambdas,key|
    lambdas[key] = L{ @yield_counts[opts[:name]][key] += 1 }
    lambdas
  }
  dep opts[:name] do
    requires opts[:requires] unless opts[:requires].nil?
    BaseDepDefiner.accepted_blocks.each {|dep_method|
      send dep_method, &L{
        returning (opts[dep_method] || @dep.definer.send(:default_task, dep_method)).call do
          incrementers[dep_method].call
        end
      }
    }
  end
end
