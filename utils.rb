
alias :L :lambda

def returning obj, &block
  yield obj
  obj
end

$log_indent = 0
Cfg = {}

def indentation
  ' ' * $log_indent * 2
end

def log_error message, opts = {}, &block
  log message, opts.merge(:error => true), &block
end

def log_verbose message, opts = {}, &block
  if Cfg[:verbose_logging]
    log message, opts, &block
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
      if opts[:closing_status]
        log "}".colorize(result ? 'green' : 'red')
      else
        log "}".colorize('grey')
      end
    end
  else
    message.gsub! "\n", "\n#{indentation}"
    message = message.colorize 'red' if opts[:error]
    message = message.end_with "\n" unless opts[:newline] == false
    print message
  end
end

def yaml file_name
  require 'yaml'
  YAML::load_file(RAILS_ROOT / file_name)
end
