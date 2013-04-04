def should_call_dep_like type, dep
  expectations = {
    :none                => {:setup => 0, :met? => 0, :prepare => 0, :before => 0, :meet => 0, :after => 0},
    :met_run             => {:setup => 1, :met? => 1, :prepare => 0, :before => 0, :meet => 0, :after => 0},
    :meet_run            => {:setup => 1, :met? => 2, :prepare => 1, :before => 1, :meet => 1, :after => 1},
    :dep_failed          => {:setup => 1, :met? => 0, :prepare => 0, :before => 0, :meet => 0, :after => 0},
    :failed_meet_run     => {:setup => 1, :met? => 2, :prepare => 1, :before => 1, :meet => 1, :after => 1},
    :early_exit_meet_run => {:setup => 1, :met? => 1, :prepare => 1, :before => 1, :meet => 1, :after => 0},
    :already_met         => {:setup => 1, :met? => 1, :prepare => 0, :before => 0, :meet => 0, :after => 0},
    :failed_at_before    => {:setup => 1, :met? => 2, :prepare => 1, :before => 1, :meet => 0, :after => 0},
  }[type]
  expect_dep_blocks(dep, expectations)
end

def expect_dep_blocks receiver, expectations
  expectations.each_pair {|method_name, times|
    receiver.should_receive(:process_task).with(method_name).exactly(times).times.and_call_original
  }
end
