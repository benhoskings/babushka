def setup_yield_counts
  @yield_counts = Hash.new {|hsh,k| hsh[k] = Hash.new {|hsh,k| 0 } }

  @yield_counts_none = {}
  @yield_counts_met_run = {:setup => 1, :met? => 1}
  @yield_counts_meet_run = {:setup => 1, :met? => 2, :prepare => 1, :before => 1, :meet => 1, :after => 1}
  @yield_counts_dep_failed = {:setup => 1}
  @yield_counts_failed_meet_run = {:setup => 1, :met? => 2, :prepare => 1, :before => 1, :meet => 1, :after => 1}
  @yield_counts_already_met = {:setup => 1, :met? => 1}
  @yield_counts_failed_at_before = {:setup => 1, :met? => 2, :prepare => 1, :before => 1}
end

def make_counter_dep opts = {}
  incrementers = DepContext.accepted_blocks.inject({}) {|lambdas,key|
    lambdas[key] = L{ @yield_counts[opts[:name]][key] += 1 }
    lambdas
  }
  dep opts[:name] do
    requires opts[:requires] unless opts[:requires].nil?
    requires_when_unmet opts[:requires_when_unmet] unless opts[:requires_when_unmet].nil?
    DepContext.accepted_blocks.each {|dep_method|
      send dep_method do
        incrementers[dep_method].call
        (opts[dep_method] || default_block_for(dep_method)).call
      end
    }
  end
end
