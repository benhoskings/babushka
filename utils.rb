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
    returning yield do
      $log_indent -= 1
      log "}".colorize('grey')
    end
  else
    print "#{message}\n"
  end
end

def yaml file_name
  require 'yaml'
  YAML::load_file(RAILS_ROOT / file_name)
end
