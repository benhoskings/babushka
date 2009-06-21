$: << File.dirname(__FILE__)
require 'monkey_patches'
require 'dep'


class Babushka
  def initialize argv
    @args = argv.dup
  end

  def run
    setup unless @setup
    if @tasks.empty?
      log "Nothing to do."
    else
      @tasks.each {|dep_name| Dep(dep_name).meet }
    end
  end


  private

  def setup
    @tasks = extract_args @args
    load_deps
    @setup = true
  end

  def load_deps
    Dir.glob('deps/**/*.rb').each {|f| require f }
    log "Loaded #{Dep.deps.count} dependencies."
  end

  def extract_args args
    Cfg[:verbose_logging] = %w[-q --quiet].map {|arg| args.delete arg }.first.blank?
    Cfg[:debug] = args.delete('--debug')
    Cfg[:dry_run] = !%w[-n --dry-run].map {|arg| args.delete arg }.first.blank?
    args
  end
end

def Babushka argv
  Babushka.new(argv).run
end

Babushka ARGV
