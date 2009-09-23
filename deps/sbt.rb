dep 'sbt' do
  requires 'java'
  merge :versions, :sbt => '0.5.4'
  met? { which 'sbt' }
  meet {
    in_dir var(:install_path, :default => '/usr/local') do
      in_dir 'lib/sbt', :create => true do
        download "http://simple-build-tool.googlecode.com/files/sbt-launcher-#{var(:versions)[:sbt]}.jar"
        shell "ln -sf sbt-launcher-#{var(:versions)[:sbt]}.jar sbt-launcher.jar"
      end
      in_dir 'bin' do
        shell %Q{echo '#!/bin/bash\njava -Xmx512M -jar `dirname $0`/../lib/sbt/sbt-launcher.jar "$@"' > sbt}
        shell 'chmod +x sbt'
      end
    end
  }
end
