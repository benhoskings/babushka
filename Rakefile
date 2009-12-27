require 'rake'
require 'spec/rake/spectask'

desc "Run all specs"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.libs.concat %w[spec]
end

desc "Run all specs with rcov"
Spec::Rake::SpecTask.new('rcov') do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.libs.concat %w[spec]
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
end
