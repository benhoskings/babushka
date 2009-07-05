def failable_shell cmd, opts = {}
  shell = nil
  Babushka::Shell.new(cmd).run opts.merge(:fail_ok => true) do |s|
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
  sudo_cmd = if opts[:su] || cmd[' |'] || cmd[' >']
    "sudo su - #{opts[:as] || 'root'} -c \"#{cmd.gsub('"', '\"')}\""
  else
    "sudo -u #{opts[:as] || 'root'} #{cmd}"
  end
  # log_verbose "$ #{sudo_cmd}" unless Babushka::Base.opts[:debug]
  shell sudo_cmd, opts, &block
end

def log_shell message, cmd, opts = {}
  log "#{message}...", :newline => false
  returning opts.delete(:sudo) ? sudo(cmd, opts) : shell(cmd, opts) do |result|
    log result ? ' done.' : ' failed', :as => (result ? nil : :error), :indentation => false
  end
end

def rake cmd, &block
  sudo "rake #{cmd} RAILS_ENV=#{rails_env}", :as => username, &block
end

def rails_rake cmd, &block
  in_dir rails_root '~/current' do
    rake cmd, &block
  end
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
  if check_file file, :writable?
    # Remove the incorrect setting if it's there
    shell("#{sed} -ri 's/^#{keyword}\s+#{from}//' #{file}")
    # Add the correct setting unless it's already there
    shell("echo '#{keyword} #{to}' >> #{file}") unless grep(/^#{keyword}\s+#{to}/, file)
  end
end

def sed
  linux? ? 'sed' : 'gsed'
end

def append_to_file text, file
  if failable_shell("grep '^#{text}' #{file}").stdout.empty?
    shell %Q{echo "#{text.gsub('"', '\"')}" >> #{file}}
  end
end

def get_source url
  filename = File.basename url
  archive_dir = File.basename filename, %w[.tar.gz .tgz].detect {|ext| filename.ends_with? ext }
  (File.exists?(filename) || log_shell("Downloading #{filename}", "wget #{url}")) &&
  log_shell("Extracting #{filename}", "sudo rm -rf #{archive_dir} && tar -zxvf #{filename}")
end

def generated_by_babushka verb = 'Generated'
  "#{verb} by babushka-#{Babushka::Version} at #{Time.now}"
end
def edited_by_babushka
  generated_by_babushka 'Edited'
end

def read_file filename
  path = File.expand_path filename
  File.read(path).chomp if File.exists? path
end

def render_erb erb, opts = {}
  require 'erb'
  debug ERB.new(IO.read(File.dirname(source) / erb)).result(binding)
  returning sudo "cat > #{opts[:to]}", :input => ERB.new(IO.read(File.dirname(source) / erb)).result(binding) do |result|
    if result
      log "Rendered #{opts[:to]}."
      sudo "chmod #{opts[:perms]} '#{opts[:to]}'" unless opts[:perms].nil?
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
