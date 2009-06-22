require 'readline'

alias :L :lambda

def returning obj, &block
  yield obj
  obj
end

def uname
  {
    'Linux' => :linux,
    'Darwin' => :osx
  }[`uname -s`.chomp]
end
def linux?; :linux == uname end
def osx?; :osx == uname end

def from_first_and_rest first, rest
  first.is_a?(Hash) ? first : [*first].concat(rest)
end

$log_indent = 0
Cfg = {}

def indentation
  ' ' * $log_indent * 2
end

def log_error message, opts = {}, &block
  log message, opts.merge(:as => :error), &block
end

def log_verbose message, opts = {}, &block
  if Cfg[:verbose_logging]
    log message, opts, &block
  elsif block_given?
    yield
  end
end

def log_extra message, opts = {}, &block
  log_verbose message.colorize('grey'), opts, &block
end

def log_result message, opts = {}, &block
  log [
    (opts[:result] ? '√' : (opts[:fail_symbol] || '×')).colorize(opts[:result] ? (opts[:ok_color] || 'grey') : (opts[:fail_color] || 'red')),
    "#{message}".colorize(opts[:result] ? (opts[:ok_color] || 'none') : (opts[:fail_color] || 'red'))
  ].join(' ')
end

def log_ok message, opts = {}, &block
  if Cfg[:verbose_logging]
    log message, opts.merge(:as => :ok), &block
    true
  elsif block_given?
    yield
  end
end

def debug message, opts = {}, &block
  if Cfg[:debug]
    log message, opts, &block
  elsif block_given?
    yield
  end
end

def log message, opts = {}, &block
  print indentation
  if block_given?
    print "#{message} {\n".colorize('grey')
    $log_indent += 1
    returning yield do |result|
      $log_indent -= 1
      if opts[:closing_status] == :dry_run
        log '}'.colorize('grey') + ' ' + "#{result ? '√' : '~'} #{message}".colorize(result ? 'green' : 'blue')
      elsif opts[:closing_status]
        log '}'.colorize('grey') + ' ' + "#{result ? '√' : '×'} #{message}".colorize(result ? 'green' : 'red')
      else
        log "}".colorize('grey')
      end
    end
  else
    message.gsub! "\n", "\n#{indentation}"
    message = "#{'√'.colorize('grey')} #{message}" if opts[:as] == :ok
    message = message.colorize 'red' if opts[:as] == :error
    message = message.end_with "\n" unless opts[:newline] == false
    print message
    $stdout.flush
    nil
  end
end

def read_path_from_prompt message, opts = {}
  read_value_from_prompt(message, opts.merge(
    :retry => "Doesn't exist, or not a directory."
  )) {|value|
    File.directory? value || ''
  }
end

def read_value_from_prompt message, in_opts = {}
  opts = {
    :prompt => '? ',
    :persist => true
  }.merge in_opts

  value = nil
  log message, :newline => false
  loop do
    value = Readline.readline opts[:prompt].end_with(' ')
    break unless (block_given? ? !yield(value) : value.blank?) && opts[:persist]
    log "#{opts[:retry] || 'That was blank.'} #{message}", :newline => false
  end
  value
end

def log_and_open message, url
  log "#{message} Hit Enter to open the download page.", :newline => false
  read_from_prompt ' '
  shell "open #{url}"
end

def yaml file_name
  require 'yaml'
  YAML::load_file(RAILS_ROOT / file_name)
end
