module Babushka
  class DepContext < DepDefiner
    include GitHelpers
    include UriHelpers

    accepts_list_for :requires
    accepts_list_for :requires_when_unmet

    accepts_block_for :setup
    accepts_block_for :met?

    accepts_block_for :prepare
    accepts_block_for :before
    accepts_block_for :meet
    accepts_block_for :after

    private

    def in_path? provided_list
      PathChecker.in_path? provided_list
    end

    # Return a `Babushka::SSH` for the given host, which provides a simple
    # interface to run shell commands (and remote babushka runs) on a remote
    # host.
    #
    # If a block is passed, it will be yielded with the `Babuahka::SSH` as an
    # argument.
    #
    # Some examples:
    #
    #   remote_git_version = ssh('ben@example.org').shell('git --version')
    #
    #   ssh('ben@example.org') do |remote|
    #     remote.babushka 'postgres.bin', version: '9.4.1'
    #   end
    #
    def ssh host, &blk
      Babushka::SSH.new(host).tap {|remote|
        yield(remote) if block_given?
      }
    end
  end
end
