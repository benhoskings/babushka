require 'rubygems'
require 'open4'

require 'utils'

def shell cmd
  # log "running '#{cmd}'"
  _stdout, _stderr = nil, nil
  status = Open4.popen4 cmd do |pid,stdin,stdout,stderr|
    _stdout, _stderr = stdout.read, stderr.read
  end
  returning (status.exitstatus == 0 ? _stdout : false) do |result|
    log_error "`#{cmd}` failed with '#{_stderr.chomp}'" unless result
  end
end

def cmd_dir cmd_name
  which = shell("which #{cmd_name}")
  File.dirname which if which
end

def sudo cmd
  log "(would be sudoing the next command)"
  shell cmd
end

def rake cmd
  shell "rake #{cmd}"
end
