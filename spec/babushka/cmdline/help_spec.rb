require 'spec_helper'

describe "help" do
  context "with no verb" do
    before {
      [
        "Babushka v#{Babushka::VERSION} (#{Babushka::Base.ref}), (c) 2012 Ben Hoskings <ben@hoskings.net>",
        "\nThe gist:",
        "  #{Base.program_name} <command> [options]",
        "\nAlso:",
        "  #{Base.program_name} help <command>  # Print command-specific usage info",
        "  #{Base.program_name} <dep name>      # A shortcut for 'babushka meet <dep name>'",
        "  #{Base.program_name} babushka        # Update babushka itself (what babushka.me/up does)",
        "\nCommands:",
        "  help       Print usage information",
        "  version    Print the current version",
        "  list       List the available deps",
        "  meet       The main one: run a dep and all its dependencies.",
        "  sources    Manage dep sources",
        "  console    Start an interactive (irb-based) babushka session",
        "  search     Search for deps in the community database",
        "  edit       Load the file containing the specified dep in $EDITOR",
        "\nCommands can be abbrev'ed, as long as they remain unique.",
        "  e.g. '#{Base.program_name} l' is short for '#{Base.program_name} list'.",
        "\n"
      ].each {|line|
        Cmdline::Helpers.should_receive(:log).with(line)
      }
    }
    it "should print the verb help information" do
      Cmdline::Parser.for(%w[help]).run
    end
  end
  context "with a verb" do
    let(:parser) { Cmdline::Parser.for(%w[help meet]) }
    before {
      [
        "Babushka v#{Babushka::VERSION} (#{Babushka::Base.ref}), (c) 2012 Ben Hoskings <ben@hoskings.net>",
        "\nmeet - The main one: run a dep and all its dependencies."
      ].each {|line|
        Cmdline::Helpers.should_receive(:log).with(line)
      }

      parser.should_receive(:log).with("
    -v, --version                    Print the current version
    -h, --help                       Show this information
    -d, --debug                      Show more verbose logging, and realtime shell command output
        --[no-]color, --[no-]colour  Disable color in the output
    -n, --dry-run                    Discover the curent state without making any changes
    -y, --defaults                   Assume the default value for all vars without prompting, where possible
    -u, --update                     Update referenced sources before loading deps from them
        --show-args                  Show the arguments being passed between deps as they're run
        --track-blocks               Track deps' blocks in TextMate as they're run
")

      Cmdline::Helpers.should_receive(:log).with("\n")
    }
    it "should print the help information for the verb" do
      parser.run
    end
  end
end
