require 'singleton'
require 'yaml'
require 'cloudservers'

require 'spec_helper'

module LogHelpers
  def print_log message, printable
    print message if printable
  end
end

class VM
  include Singleton
  SERVER_NAME = 'babushka-specs'

  def babushka task
    run "babushka '#{task}' --defaults --no-colour"
  end

  def run cmd, user = 'root'
    log "Running on #{user}@#{host}: #{cmd}" do
      shell "ssh #{user}@#{host} '#{cmd}'", :log => true
    end
  end

  def server
    @_server || (existing_server || create_server).tap {|s|
      wait_for_server
    }
  end

  private

  def existing_server
    server_detail = connection.list_servers_detail.detect {|s| s[:name] == SERVER_NAME }
    unless server_detail.nil?
      log "A server is already running."
      @_server = connection.get_server(server_detail[:id])
    end
  end

  def create_server
    log_block "Creating a #{flavor[:ram]}MB #{image[:name]} rackspace instance" do
      @_server = connection.create_server(image_args)
    end
  end

  def wait_for_server
    if server.status != 'ACTIVE'
      log_block "Waiting for the server to come online" do
        until server.status == 'ACTIVE'
          sleep 3
          print '.'
          server.refresh
        end
        server.status == 'ACTIVE'
      end
    end
  end

  def host
    server.addresses[:public].first
  end

  def image_args
    {
      :name => SERVER_NAME,
      :imageId => image[:id],
      :flavorId => flavor[:id],
      :personality => {
        public_key => '/root/.ssh/authorized_keys'
      }
    }
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
  def public_key
    Dir.glob(File.expand_path("~/.ssh/id_[dr]sa.pub")).first
  end
end
