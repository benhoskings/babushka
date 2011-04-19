require 'singleton'
require 'yaml'
require 'cloudservers'

require 'spec_helper'

class VM
  include Singleton

  def shell cmd, user = 'root'
    log "Running on #{user}@#{vm_host}: #{cmd}" do
      shell "ssh #{user}@#{vm_host} '#{cmd}'", :log => true
    end
  end

  def start
    raise "Already created a server." unless @server.nil?

    log_block "Creating a #{flavor[:ram]}MB #{image[:name]} rackspace instance." do
      @server = connection.create_server(image_args)
    end
    log_block "Waiting for the server to come online" do
      until server.status == 'ACTIVE'
        print '.'
        sleep 2
        server.refresh
      end
    end
  end

  private

  def server; @server end

  def image_args
    {:name => "babushka", :imageId => image[:id], :flavorId => flavor[:id]}
  end

  def image
    connection.list_images.detect {|image| image[:name][cfg['image_name']] }
  end

  def flavor
    connection.list_flavors.detect {|flavor| flavor[:ram] == 256 }
  end

  def connection
    @_connection ||= CloudServers::Connection.new(
      :username => cfg['username'], :api_key => cfg['api_key']
    )
  end
  def cfg
    @_cfg ||= YAML.load_file(Babushka::Path.path / 'conf/rackspace.yml')
  end
end

VM.instance.start
