require 'spec_helper'

module LogHelpers
  def print_log message, printable
    print message if printable
  end
end

vmrun = "/Library/Application Support/VMware Fusion/vmrun"
vm_path = "/Volumes/Michael Optibay/Virtual Machines.localized/Snow Leopard.vmwarevm/Snow Leopard.vmx"
snapshot_name = "sshd"

def vm_shell cmd
  vm_user = 'test'
  vm_host = '192.168.153.140'
  log "Running on #{vm_user}@#{vm_host}: #{cmd}" do
    shell "ssh #{vm_user}@#{vm_host} '#{cmd}'", :log => true
  end
end

describe "babushka" do
  before(:all) {
    # `"#{vmrun}" revertToSnapshot "#{vm_path}" "#{snapshot_name}"`
    # `"#{vmrun}" start "#{vm_path}"`
  }
  context "bootstrapping" do
    before(:all) {
      vm_shell 'bash -c "`curl babushka.me/up/hard`"'
    }
    it "should have installed babushka" do
      vm_shell('babushka').should =~ /Babushka/
    end
  end
end
