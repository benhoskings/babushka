require 'rubygems'
require 'open4'

require 'utils'

def shell cmd
  # log "$ #{cmd}".colorize('grey')
  _stdout, _stderr = nil, nil
  status = Open4.popen4 cmd do |pid,stdin,stdout,stderr|
    _stdout, _stderr = stdout.read, stderr.read
  end
  returning (status.exitstatus == 0 ? _stdout : false) do |result|
    # log_error "`#{cmd}` failed with '#{_stderr.chomp}'" unless result
  end
end

def which cmd_name
  shell("which #{cmd_name}")
end

def cmd_dir cmd_name
  path = which("#{cmd_name}")
  File.dirname path if path
end

def sudo cmd
  shell "sudo #{cmd}"
end

def rake cmd
  shell "rake #{cmd} RAILS_ENV=#{RAILS_ENV}"
end
