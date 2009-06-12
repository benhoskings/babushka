def returning obj, &block
  yield obj
  obj
end

$log_indent = 0

def log_error message, opts = {}, &block
  log message, opts.merge(:error => true), &block
end

def log message, opts = {}, &block
  print(' ' * $log_indent * 2)
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
    if opts[:error]
      print "#{message.colorize('red')}\n"
    else
      print "#{message}\n"
    end
  end
end

def yaml file_name
  require 'yaml'
  YAML::load_file(RAILS_ROOT / file_name)
end
