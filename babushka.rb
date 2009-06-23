$: << File.dirname(__FILE__)
require 'monkey_patches'
require 'dep'


class Babushka
  def initialize argv
    @args = argv.dup
  end

  def run
    if !(@setup ||= setup)
      log "There was a problem loading deps."
    elsif @tasks.empty?
      log "Nothing to do."
    else
      @tasks.each {|dep_name| Dep(dep_name).meet }
    end
  end


  private

  def setup
    @tasks = extract_args @args
    %w[~/.babushka/deps ./deps].all? {|dep_path| DepDefiner.load_deps_from dep_path }
  end

  def extract_args args
    Cfg[:verbose_logging] = %w[-q --quiet].map {|arg| args.delete arg }.first.blank?
    Cfg[:debug] = args.delete('--debug')
    Cfg[:dry_run] = !%w[-n --dry-run].map {|arg| args.delete arg }.first.blank?
    Cfg[:force] = !%w[-f --force].map {|arg| args.delete arg }.first.blank?
    args
  end
end

def Babushka argv
  Babushka.new(argv).run
end

Babushka ARGV
