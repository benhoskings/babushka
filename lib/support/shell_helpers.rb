def failable_shell cmd, opts = {}
  shell = nil
  Shell.new(cmd).run opts.merge(:fail_ok => true) do |s|
    shell = s
  end
  shell
end

def which cmd_name, &block
  shell "which #{cmd_name}", &block
end

def in_dir dir, opts = {}, &block
  if dir.nil?
    yield
  else
    path = File.expand_path(dir)
    Dir.mkdir(path) if opts[:create] unless File.exists?(path)
    Dir.chdir path do
      debug "in dir #{dir} (#{path})" do
        yield
      end
    end
  end
end

def cmd_dir cmd_name
  which("#{cmd_name}") {|shell|
    File.dirname shell.stdout if shell.ok?
  }
end

def sudo cmd, opts = {}, &block
  if cmd[' |'] || cmd[' >']
    shell "sudo su - #{opts[:as] || 'root'} -c \"#{cmd.gsub('"', '\"')}\"", opts, &block
  else
    shell "sudo -u #{opts[:as] || 'root'} #{cmd}", opts, &block
  end
end

def log_shell cmd, message
  log "#{message}...", :newline => false
  returning shell(cmd) do |result|
    log result ? ' done.' : ' failed', :as => (result ? nil : :error), :indentation => false
  end
end

def rake cmd, &block
  sudo "rake #{cmd} RAILS_ENV=#{rails_env}", :as => username, &block
end

def check_file file_name, method_name
  returning File.send method_name, file_name do |result|
    log_error "#{file_name} failed #{method_name.to_s.sub(/[?!]$/, '')} check." unless result
  end
end

def grep regex, file
  if File.exists?(path = File.expand_path(file))
    output = IO.readlines(path).grep(regex)
    output unless output.empty?
  end
end

def change_with_sed keyword, from, to, file
  sed = linux? ? 'sed' : 'gsed'
  if check_file file, :writable?
    # Remove the incorrect setting if it's there
    shell("#{sed} -ri 's/^#{keyword}\s+#{from}//' #{file}")
    # Add the correct setting unless it's already there
    shell("echo '#{keyword} #{to}' >> #{file}") unless grep(/^#{keyword}\s+#{to}/, file)
  end
end

def append_to_file text, file
  if failable_shell("grep '^#{text}' #{file}").stdout.empty?
    shell %Q{echo "#{text.gsub('"', '\"')}" >> #{file}}
  end
end

def get_source url
  filename = File.basename url
  archive_dir = File.basename filename, '.tar.gz'
  (File.exists?(filename) || log_shell("wget #{url}", "Downloading #{filename}")) &&
  log_shell("sudo rm -rf #{archive_dir} && tar -zxvf #{filename}", "Extracting #{filename}")
end

def render_erb erb, opts = {}
  require 'erb'
  log ERB.new(IO.read(File.dirname(source) / erb)).result(binding)
  returning sudo "cat > #{opts[:to]}", :input => ERB.new(IO.read(File.dirname(source) / erb)).result(binding) do |result|
    if result
      log "Rendered #{opts[:to]}."
      File.chmod opts[:perms], opts[:to] unless opts[:perms].nil?
    else
      log_error "Couldn't render #{opts[:to]}."
    end
  end
end

def log_and_open message, url
  log "#{message} Hit Enter to open the download page.", :newline => false
  read_from_prompt ' '
  shell "open #{url}"
end
