module Babushka
  class SrcDepDefiner < BaseDepDefiner

    accepts_list_for :get
    accepts_list_for :provides, :default_name
    accepts_list_for :prefix, '/usr/local'

    accepts_block_for :configure
    accepts_block_for :make
    accepts_block_for :install

    def process
      super

      requires 'build tools'
      met? {
        present, missing = provides.partition {|cmd_name| cmd_dir(cmd_name) }

        returning missing.empty? do
          log_error "#{missing.map {|i| "'#{i}'" }.to_list} #{missing.length == 1 ? 'is' : 'are'} missing from your PATH." unless missing.empty?
        end
      }
      meet { do_it_live }
    end


    private

    def default_name
      VersionOf.new name
    end

  end
end
