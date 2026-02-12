# frozen_string_literal: true

require 'socket'

module CloudHash
  class Server
    def initialize(port)
      @server = TCPServer.new(port)
      puts "Listening on port #{@server.local_address.ip_port}"
      @storage = {}
    end

    def start
      Socket.accept_loop(@server) do |connection|
        handle(connection)
        connection.close
      end
    end

    def handle(connection)
      request = connection.read
      connection.write(process(request))
    end

    def process(request)
      command, key, value = request.split

      case command.upcase
      when 'GET'
        @storage[key]
      when 'SET'
        @storage[key] = value
      end
    end
  end

  class Client
    class << self
      attr_accessor :host, :port
    end

    def self.get(key)
      request "GET #{key}"
    end

    def self.set(key, value)
      request "SET #{key} #{value}"
    end

    def self.request(string)
      client = TCPSocket.new(host, port)
      # send request
      client.write(string)
      # send EOF
      client.close_write
      # read until EOF to get the response
      client.read
    ensure
      # ensure we close the open fd
      client.close
    end
  end
end

server = CloudHash::Server.new(4481)
server_thr = Thread.new do
  server.start
end

CloudHash::Client.host = 'localhost'
CloudHash::Client.port = 4481

puts CloudHash::Client.set 'prez', 'obama'
puts CloudHash::Client.get 'prez'
puts CloudHash::Client.get 'vp'

server_thr.join
