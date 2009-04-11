def returning obj, &block
  yield obj
  obj
end

$log_indent = 0

def log message, &block
  print((' ' * $log_indent * 2) + message)
  if block_given?
    print " {\n"
    $log_indent += 1
    returning yield do
      $log_indent -= 1
      log "}"
    end
  else
    print "\n"
  end
end

def yaml file_name
  require 'yaml'
  YAML::load_file(RAILS_ROOT / file_name)
end
