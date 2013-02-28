require "tempfile"

meta :visudo do
  accepts_value_for :line
  template {
    setup {
      @line_pattern = Regexp.new(line.gsub(/\s*/, "\\s*"))
    }
    met? {
      @current_content = sudo("cat /etc/sudoers")
      @line_pattern =~ @current_content
    }
    meet {
      tmpfile = Tempfile.new('sudoers')
      tmpfile.write(@current_content)
      # Ensure trailing newline
      tmpfile.write("\n")
      tmpfile.write(line)
      tmpfile.close
      unless shell("visudo -c -f #{tmpfile.path}")
        unmeetable! "Your changes to sudoers are invalid"
      end
      sudo("mv '#{tmpfile.path}' /etc/sudoers")
    }
  }
end

dep 'admins can sudo', :template => "visudo" do
  requires 'admin group', 'sudo.bin'

  line '%admin  ALL=(ALL) ALL'
end

dep 'admin group' do
  met? { '/etc/group'.p.grep(/^admin\:/) }
  meet { sudo 'groupadd admin' }
end
