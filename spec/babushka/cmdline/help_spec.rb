require 'spec_helper'

RSpec.describe "help" do
  context "with no verb" do
    before {
      [
        "Babushka v#{Babushka::VERSION} (#{Babushka::Base.ref}), (c) Ben Hoskings <ben@hoskings.net>",
        "\nThe gist:",
        "  #{Babushka::Base.program_name} <command> [options]",
        "\nAlso:",
        "  #{Babushka::Base.program_name} help <command>  # Print command-specific usage info",
        "  #{Babushka::Base.program_name} <dep name>      # A shortcut for 'babushka meet <dep name>'",
        "  #{Babushka::Base.program_name} babushka        # Update babushka itself (what babushka.me/up does)",
        "\nCommands:",
        "  help       Print usage information",
        "  version    Print the current version",
        "  list       List the available deps",
        "  meet       The main one: run a dep and all its dependencies.",
        "  sources    Manage dep sources",
        "  console    Start an interactive (irb-based) babushka session",
        "  edit       Load the file containing the specified dep in $EDITOR",
        "\nCommands can be abbrev'ed, as long as they remain unique.",
        "  e.g. '#{Babushka::Base.program_name} l' is short for '#{Babushka::Base.program_name} list'.",
      ].each {|line|
        expect(Babushka::Cmdline::Helpers).to receive(:log).with(line)
      }
      expect(Babushka::LogHelpers).to receive(:log).with("\n")
    }
    it "should print the verb help information" do
      Babushka::Cmdline::Parser.for(%w[help]).run
    end
  end
  context "with a verb" do
    let(:parser) { Babushka::Cmdline::Parser.for(%w[help meet]) }
    before {
      expect(Babushka::Cmdline::Helpers).to receive(:log).with(
        "Babushka v#{Babushka::VERSION} (#{Babushka::Base.ref}), (c) Ben Hoskings <ben@hoskings.net>"
      )
      expect(Babushka::LogHelpers).to receive(:log).with(
        "\nmeet - The main one: run a dep and all its dependencies."
      )

      expect(parser).to receive(:log).with("
    -v, --version                    Print the current version
    -h, --help                       Show this information
    -d, --debug                      Show more verbose logging, and realtime shell command output
    -s, --silent                     Only log errors, running silently on success
        --[no-]color, --[no-]colour  Disable color in the output
    -n, --dry-run                    Check which deps are met, but don't meet any unmet deps
    -y, --defaults                   Use dep arguments' default values without prompting
    -u, --update                     Update sources before loading deps from them
        --show-args                  Show the arguments being passed between deps as they're run
        --profile                    Print a per-line timestamp to the debug log
        --git-fs                     [EXPERIMENTAL] Snapshot the root filesystem in a git repo after meeting deps
        --remote-git-fs              [EXPERIMENTAL] Snapshot the remote host using --git-fs after remote babushka runs
")

      expect(Babushka::LogHelpers).to receive(:log).with("\n")
    }
    it "should print the help information for the verb" do
      parser.run
    end
  end
end
