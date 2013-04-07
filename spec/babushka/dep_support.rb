def should_call_dep_like type, dep
  expectations = {
    :none              => {:setup => 0, :met? => 0, :prepare => 0, :before => 0, :meet => 0, :after => 0},
    :unmet_requirement => {:setup => 1, :met? => 0, :prepare => 0, :before => 0, :meet => 0, :after => 0},
    :met_run           => {:setup => 1, :met? => 1, :prepare => 0, :before => 0, :meet => 0, :after => 0},
    :meet_failed       => {:setup => 1, :met? => 1, :prepare => 1, :before => 1, :meet => 1, :after => 0},
    :meet_skipped      => {:setup => 1, :met? => 2, :prepare => 1, :before => 1, :meet => 0, :after => 0},
    :meet_run          => {:setup => 1, :met? => 2, :prepare => 1, :before => 1, :meet => 1, :after => 1},
  }[type]
  expect_dep_blocks(dep, expectations)
end

def expect_dep_blocks receiver, expectations
  expectations.each_pair {|method_name, times|
    receiver.should_receive(:invoke).with(method_name).exactly(times).times.and_call_original
  }
end
