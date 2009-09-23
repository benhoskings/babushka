dep 'sbt' do
  requires 'java'
  met? { which 'sbt' }
  meet {
    in_dir var(:install_path, :default => '/usr/local/bin') do
      download 'http://simple-build-tool.googlecode.com/files/sbt-launcher-0.5.4.jar', 'sbt-launcher.jar'
      shell %q{echo 'java -Xmx512M -jar `dirname $0`/sbt-launcher.jar "$@"' > sbt}
      shell 'chmod +x sbt'
    end
  }
end
