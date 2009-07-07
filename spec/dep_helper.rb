def make_counter_dep opts = {}
  incrementers = DepDefiner.accepted_blocks.inject({}) {|lambdas,key|
    lambdas[key] = L{ @yield_counts[key] += 1 }
    lambdas
  }
  dep [opts[:name], 'lambda counter'].compact.join(' ') do
    DepDefiner.accepted_blocks.each {|dep_method|
      send dep_method, &L{
        returning (opts[dep_method] || @dep.send(:default_task, dep_method)).call do
          incrementers[dep_method].call
        end
      }
    }
  end
end
