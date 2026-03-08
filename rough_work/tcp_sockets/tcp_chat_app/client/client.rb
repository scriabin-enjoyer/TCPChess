# frozen_string_literal: true

require 'socket'
require_relative 'ui'
require_relative 'socket_errors'

module TCPChatApp
  class Client
    REMOTE_PORT = 2211
    REMOTE_HOST = 'localhost'

    # main entry point
    def self.connect(host = REMOTE_HOST, port = REMOTE_PORT)
      client = new(host, port)
    end

    def initialize(host, port)
      @host = host
      @port = port
      @ui = UI.new
      @ui.welcome
      # Just let it fail for now if the connect is unsuccessful
      @server = TCPSocket.new(host, port, connect_timeout: 60)
      @ui.puts_connect_success
    end

    def start_session
      raise NotImplementedError
    end
  end
end
