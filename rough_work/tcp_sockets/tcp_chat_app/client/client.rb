# frozen_string_literal: true

require 'socket'
require_relative 'ui'
require_relative 'socket_errors'

module TCPChatApp
  class Client
    REMOTE_PORT = 2211
    REMOTE_HOST = 'localhost'

    def initialize
      @id = Time.now.hash.to_s(16)[0..6]
      @ui = UI.new(@id)
      @ui.welcome
      # Just let it fail for now if the connect is unsuccessful
      @server = TCPSocket.new(REMOTE_HOST, REMOTE_PORT, connect_timeout: 60)
      @ui.puts_connect_success
    end

    def loop
    end
  end
end

# TCPChatApp::Client.new
